#!/usr/bin/env python3
"""Build a deterministic duplicate-family worklist from a Fallow dupes JSON report."""

from __future__ import annotations

import argparse
import hashlib
import json
import logging
import sys
from collections.abc import Sequence
from dataclasses import asdict, dataclass
from pathlib import Path, PurePosixPath


LOGGER = logging.getLogger("fallow_dupes_worklist")
SCRIPT_PATH = Path(__file__).resolve()
REPO_ROOT = SCRIPT_PATH.parents[4]
DEFAULT_OUTPUT_PATH = Path("output/fallow/app-dupes/worklist.jsonl")
DEFAULT_LIMIT = 12
DEFAULT_LOG_LEVEL = "INFO"
SUPPORTED_LOG_LEVELS = ("DEBUG", "INFO", "WARNING", "ERROR")
MAX_PREVIEW_LINES = 8
MAX_PREVIEW_WIDTH = 120
JsonDict = dict[str, object]


class FallowDupesWorklistError(RuntimeError):
    """Base error for Fallow dupes worklist generation."""


class ReportSchemaError(FallowDupesWorklistError):
    """Raised when the Fallow dupes JSON payload does not match the expected schema."""


@dataclass(frozen=True, order=True)
class DuplicateOccurrence:
    """One file/range occurrence inside a duplicate group."""

    file: str
    start_line: int
    end_line: int
    start_column: int
    end_column: int


@dataclass(frozen=True)
class DuplicateGroupRecord:
    """One clone group inside a duplicate family."""

    token_count: int
    line_count: int
    files: tuple[str, ...]
    fragment_preview: str
    occurrences: tuple[DuplicateOccurrence, ...]


@dataclass(frozen=True)
class DuplicateFamilyRecord:
    """Serializable worklist record for one duplicate family."""

    id: str
    fingerprint: str
    app: str
    group_count: int
    occurrence_count: int
    files: tuple[str, ...]
    common_parent: str | None
    total_duplicated_lines: int
    total_duplicated_tokens: int
    recommended_strategy: str
    suggestions: tuple[str, ...]
    actions: tuple[str, ...]
    groups: tuple[DuplicateGroupRecord, ...]


def build_parser() -> argparse.ArgumentParser:
    """Create the CLI parser for worklist generation."""

    parser = argparse.ArgumentParser(
        description="Build a deterministic duplicate-family worklist from a Fallow dupes JSON report.",
    )
    parser.add_argument(
        "report",
        type=Path,
        help="Path to the Fallow dupes JSON report.",
    )
    parser.add_argument(
        "--app",
        required=True,
        help="App name for the selected worklist.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=DEFAULT_LIMIT,
        help="Maximum number of duplicate families to include. Default: {default_limit}".format(
            default_limit=DEFAULT_LIMIT
        ),
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_PATH,
        help="Write JSONL output to this path. Default: {default_output}".format(
            default_output=DEFAULT_OUTPUT_PATH
        ),
    )
    parser.add_argument(
        "--log-level",
        choices=SUPPORTED_LOG_LEVELS,
        default=DEFAULT_LOG_LEVEL,
        help="Logging verbosity. Default: {default_level}".format(default_level=DEFAULT_LOG_LEVEL),
    )
    return parser


def configure_logging(log_level: str) -> None:
    """Configure process-wide logging."""

    logging.basicConfig(
        level=getattr(logging, log_level),
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )


def resolve_output_path(raw_path: Path) -> Path:
    """Resolve an output path relative to the repo root."""

    candidate = raw_path.expanduser()
    if not candidate.is_absolute():
        candidate = (REPO_ROOT / candidate).resolve()
    else:
        candidate = candidate.resolve()
    return candidate


def normalize_report_path(raw_path: Path) -> Path:
    """Resolve the report path relative to the repo root and require that it exists."""

    candidate = raw_path.expanduser()
    if not candidate.is_absolute():
        candidate = (REPO_ROOT / candidate).resolve()
    else:
        candidate = candidate.resolve()
    if not candidate.exists():
        raise FallowDupesWorklistError(
            "The Fallow dupes report '{path}' does not exist.".format(path=display_path(candidate))
        )
    return candidate


def load_clone_families(report_path: Path) -> list[JsonDict]:
    """Load and validate the clone families from a Fallow dupes JSON report."""

    try:
        payload = json.loads(report_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise ReportSchemaError(
            "The Fallow dupes report at '{path}' is not valid JSON.".format(path=display_path(report_path))
        ) from error

    if not isinstance(payload, dict):
        raise ReportSchemaError(
            "The Fallow dupes report at '{path}' must be a JSON object.".format(path=display_path(report_path))
        )

    clone_families = payload.get("clone_families")
    if not isinstance(clone_families, list):
        raise ReportSchemaError(
            "The Fallow dupes report at '{path}' is missing the clone_families array.".format(
                path=display_path(report_path)
            )
        )

    validated_families: list[JsonDict] = []
    for family in clone_families:
        if not isinstance(family, dict):
            raise ReportSchemaError("Every Fallow clone family entry must be a JSON object.")
        validated_families.append(family)
    return validated_families


def build_worklist(report_path: Path, app: str, limit: int) -> list[DuplicateFamilyRecord]:
    """Build a sorted duplicate-family worklist from a Fallow dupes report."""

    if limit <= 0:
        raise FallowDupesWorklistError("The duplicate-family limit must be greater than zero.")

    families = load_clone_families(report_path)
    records = [finalize_family(family, app) for family in families]
    ordered_records = sorted(records, key=family_sort_key)
    return ordered_records[:limit]


def finalize_family(family: JsonDict, app: str) -> DuplicateFamilyRecord:
    """Convert a raw clone family payload into a serializable worklist record."""

    files = tuple(sorted(extract_string_list(family.get("files"), "family.files")))
    groups = tuple(
        sorted(
            (finalize_group(group) for group in extract_dict_list(family.get("groups"), "family.groups")),
            key=group_sort_key,
        )
    )
    common_parent = build_common_parent(files)
    total_duplicated_lines = require_integer(family.get("total_duplicated_lines"), "family.total_duplicated_lines")
    total_duplicated_tokens = require_integer(
        family.get("total_duplicated_tokens"),
        "family.total_duplicated_tokens",
    )
    suggestions = tuple(extract_message_list(family.get("suggestions"), "family.suggestions"))
    actions = tuple(extract_message_list(family.get("actions"), "family.actions"))
    occurrence_count = sum(len(group.occurrences) for group in groups)
    fingerprint = build_fingerprint(files, groups, total_duplicated_lines, total_duplicated_tokens)
    family_id = "family:{fingerprint}:{lines}:{groups}".format(
        fingerprint=fingerprint,
        lines=total_duplicated_lines,
        groups=len(groups),
    )

    return DuplicateFamilyRecord(
        id=family_id,
        fingerprint=fingerprint,
        app=app,
        group_count=len(groups),
        occurrence_count=occurrence_count,
        files=files,
        common_parent=common_parent,
        total_duplicated_lines=total_duplicated_lines,
        total_duplicated_tokens=total_duplicated_tokens,
        recommended_strategy=build_recommended_strategy(common_parent, files, occurrence_count, len(groups)),
        suggestions=suggestions,
        actions=actions,
        groups=groups,
    )


def finalize_group(group: JsonDict) -> DuplicateGroupRecord:
    """Convert one raw clone group payload into a serializable group record."""

    occurrences = tuple(
        sorted(
            extract_occurrence(instance)
            for instance in extract_dict_list(group.get("instances"), "group.instances")
        )
    )
    files = tuple(sorted({occurrence.file for occurrence in occurrences}))
    token_count = require_integer(group.get("token_count"), "group.token_count")
    line_count = require_integer(group.get("line_count"), "group.line_count")
    fragment_preview = render_fragment_preview(require_string_from_first_occurrence(group))
    return DuplicateGroupRecord(
        token_count=token_count,
        line_count=line_count,
        files=files,
        fragment_preview=fragment_preview,
        occurrences=occurrences,
    )


def extract_occurrence(instance: JsonDict) -> DuplicateOccurrence:
    """Extract one occurrence entry from a raw Fallow clone instance."""

    return DuplicateOccurrence(
        file=require_string(instance.get("file"), "instance.file"),
        start_line=require_integer(instance.get("start_line"), "instance.start_line"),
        end_line=require_integer(instance.get("end_line"), "instance.end_line"),
        start_column=require_integer(instance.get("start_col"), "instance.start_col"),
        end_column=require_integer(instance.get("end_col"), "instance.end_col"),
    )


def require_string_from_first_occurrence(group: JsonDict) -> str:
    """Extract the first clone fragment for preview rendering."""

    instances = extract_dict_list(group.get("instances"), "group.instances")
    if not instances:
        raise ReportSchemaError("Every Fallow clone group must contain at least one instance.")
    return require_string(instances[0].get("fragment"), "instance.fragment")


def extract_dict_list(value: object, label: str) -> list[JsonDict]:
    """Require that a JSON value is a list of dictionaries."""

    if not isinstance(value, list):
        raise ReportSchemaError("The Fallow field '{label}' must be an array.".format(label=label))

    items: list[JsonDict] = []
    for item in value:
        if not isinstance(item, dict):
            raise ReportSchemaError("The Fallow field '{label}' must contain only objects.".format(label=label))
        items.append(item)
    return items


def extract_string_list(value: object, label: str) -> list[str]:
    """Require that a JSON value is a list of strings."""

    if not isinstance(value, list):
        raise ReportSchemaError("The Fallow field '{label}' must be an array.".format(label=label))

    items: list[str] = []
    for item in value:
        if not isinstance(item, str):
            raise ReportSchemaError("The Fallow field '{label}' must contain only strings.".format(label=label))
        items.append(item)
    return items


def extract_message_list(value: object, label: str) -> list[str]:
    """Extract description strings from the Fallow suggestions/actions arrays."""

    messages: list[str] = []
    for item in extract_dict_list(value, label):
        messages.append(require_string(item.get("description"), "{label}.description".format(label=label)))
    return messages


def require_string(value: object, label: str) -> str:
    """Require that a JSON value is a string."""

    if isinstance(value, str):
        return value
    raise ReportSchemaError("The Fallow field '{label}' must be a string.".format(label=label))


def require_integer(value: object, label: str) -> int:
    """Require that a JSON value is an integer-like number."""

    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    raise ReportSchemaError("The Fallow field '{label}' must be numeric.".format(label=label))


def build_fingerprint(
    files: Sequence[str],
    groups: Sequence[DuplicateGroupRecord],
    total_duplicated_lines: int,
    total_duplicated_tokens: int,
) -> str:
    """Build a stable family fingerprint from the family payload."""

    payload = {
        "files": list(files),
        "totals": {
            "lines": total_duplicated_lines,
            "tokens": total_duplicated_tokens,
        },
        "groups": [
            {
                "token_count": group.token_count,
                "line_count": group.line_count,
                "occurrences": [asdict(occurrence) for occurrence in group.occurrences],
            }
            for group in groups
        ],
    }
    digest = hashlib.sha256(json.dumps(payload, sort_keys=True).encode("utf-8")).hexdigest()
    return digest[:12]


def build_common_parent(files: Sequence[str]) -> str | None:
    """Return the shared directory path for all files in a family when one exists."""

    if not files:
        return None

    parent_parts = [PurePosixPath(file_path).parent.parts for file_path in files]
    shared_parts: list[str] = []
    for part_group in zip(*parent_parts):
        if len(set(part_group)) != 1:
            break
        shared_parts.append(part_group[0])

    if not shared_parts:
        return None
    return str(PurePosixPath(*shared_parts))


def build_recommended_strategy(
    common_parent: str | None,
    files: Sequence[str],
    occurrence_count: int,
    group_count: int,
) -> str:
    """Describe the expected remediation style for a duplicate family."""

    file_count = len(files)
    if common_parent:
        return (
            "Extract a shared helper or module under '{parent}' and remove the {occurrences} repeated "
            "occurrences across {groups} clone groups in {file_count} files.".format(
                parent=common_parent,
                occurrences=occurrence_count,
                groups=group_count,
                file_count=file_count,
            )
        )
    return (
        "Extract the shared logic at the nearest maintained boundary and remove the {occurrences} repeated "
        "occurrences across {groups} clone groups in {file_count} files.".format(
            occurrences=occurrence_count,
            groups=group_count,
            file_count=file_count,
        )
    )


def render_fragment_preview(fragment: str) -> str:
    """Render a compact multi-line preview for one duplicate group."""

    preview_lines = []
    for raw_line in fragment.strip().splitlines()[:MAX_PREVIEW_LINES]:
        preview_lines.append(raw_line.rstrip()[:MAX_PREVIEW_WIDTH])
    return "\n".join(preview_lines)


def group_sort_key(group: DuplicateGroupRecord) -> tuple[int, int, tuple[str, ...]]:
    """Build a deterministic sort key for groups inside one family."""

    return (-group.line_count, -group.token_count, group.files)


def family_sort_key(family: DuplicateFamilyRecord) -> tuple[int, int, int, tuple[str, ...], str]:
    """Build a deterministic sort key for duplicate families."""

    return (
        -family.total_duplicated_lines,
        -family.total_duplicated_tokens,
        -family.group_count,
        family.files,
        family.fingerprint,
    )


def write_jsonl(output_path: Path, worklist: Sequence[DuplicateFamilyRecord]) -> None:
    """Write the selected worklist records as JSONL."""

    output_path.parent.mkdir(parents=True, exist_ok=True)
    lines = [json.dumps(asdict(record), ensure_ascii=True) for record in worklist]
    payload = "\n".join(lines)
    if payload:
        payload += "\n"
    output_path.write_text(payload, encoding="utf-8")


def display_path(path: Path) -> str:
    """Render a path relative to the repo root when possible."""

    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def execute() -> int:
    """Run the worklist builder end to end and return a process exit code."""

    parser = build_parser()
    args = parser.parse_args()
    configure_logging(args.log_level)

    try:
        report_path = normalize_report_path(args.report)
        output_path = resolve_output_path(args.output)
        LOGGER.info("Building Fallow duplicate-family worklist.")
        LOGGER.info("Report path: %s", report_path)
        LOGGER.info("Output path: %s", output_path)
        LOGGER.info("Scope: %s", args.app)
        LOGGER.info("Family limit: %s", args.limit)
        worklist = build_worklist(report_path, args.app, args.limit)
        write_jsonl(output_path, worklist)
        print(output_path)
        print("{count} duplicate families selected".format(count=len(worklist)))
        return 0
    except (FallowDupesWorklistError, OSError, ReportSchemaError, ValueError) as error:
        LOGGER.exception("Failed to build the Fallow dupes worklist: %s", error)
        print("error: {message}".format(message=error), file=sys.stderr)
        return 1


def main() -> int:
    """CLI entrypoint."""

    return execute()


if __name__ == "__main__":
    raise SystemExit(main())
