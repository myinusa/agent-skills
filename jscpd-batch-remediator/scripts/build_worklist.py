#!/usr/bin/env python3
"""Build a deterministic duplicate-cluster worklist from a jscpd JSON report."""

from __future__ import annotations

import argparse
import hashlib
import json
import logging
import re
import sys
from collections.abc import Sequence
from dataclasses import asdict, dataclass, field
from pathlib import Path, PurePosixPath


LOGGER = logging.getLogger("jscpd_worklist")
SCRIPT_PATH = Path(__file__).resolve()
REPO_ROOT = SCRIPT_PATH.parents[4]
DEFAULT_OUTPUT_PATH = Path("output/jscpd/current-jscpd-worklist.jsonl")
DEFAULT_LIMIT = 12
DEFAULT_LOG_LEVEL = "INFO"
SUPPORTED_LOG_LEVELS = ("DEBUG", "INFO", "WARNING", "ERROR")
MAX_PREVIEW_LINES = 8
MAX_PREVIEW_WIDTH = 120
JsonDict = dict[str, object]


class JscpdWorklistError(RuntimeError):
    """Base error for jscpd worklist generation."""


class ReportSchemaError(JscpdWorklistError):
    """Raised when the jscpd JSON payload does not match the expected schema."""


@dataclass(frozen=True, order=True)
class DuplicateOccurrence:
    """One file/range occurrence inside a duplicate cluster."""

    file: str
    start_line: int
    end_line: int
    start_column: int
    end_column: int

    def dedupe_key(self) -> tuple[str, int, int, int, int]:
        """Return a stable key for set-like deduplication."""

        return (
            self.file,
            self.start_line,
            self.end_line,
            self.start_column,
            self.end_column,
        )


@dataclass
class DuplicateClusterAccumulator:
    """Mutable cluster accumulator built from raw jscpd duplicate pairs."""

    fingerprint: str
    normalized_fragment: str
    lines: int
    tokens: int
    pair_count: int = 0
    occurrences: dict[tuple[str, int, int, int, int], DuplicateOccurrence] = field(default_factory=dict)

    def add_pair(self, duplicate: JsonDict) -> None:
        """Merge a raw jscpd duplicate pair into the cluster."""

        self.pair_count += 1
        first_occurrence = extract_occurrence(duplicate, "firstFile")
        second_occurrence = extract_occurrence(duplicate, "secondFile")
        self.occurrences[first_occurrence.dedupe_key()] = first_occurrence
        self.occurrences[second_occurrence.dedupe_key()] = second_occurrence


@dataclass(frozen=True)
class DuplicateClusterRecord:
    """Serializable worklist record for one duplicate cluster."""

    id: str
    fingerprint: str
    lines: int
    tokens: int
    pair_count: int
    occurrence_count: int
    files: tuple[str, ...]
    common_parent: str | None
    recommended_strategy: str
    fragment_preview: str
    occurrences: tuple[DuplicateOccurrence, ...]


def build_parser() -> argparse.ArgumentParser:
    """Create the CLI parser for worklist generation."""

    parser = argparse.ArgumentParser(
        description="Build a deterministic duplicate-cluster worklist from a jscpd JSON report.",
    )
    parser.add_argument(
        "report",
        type=Path,
        help="Path to the jscpd JSON report.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=DEFAULT_LIMIT,
        help="Maximum number of duplicate clusters to include. Default: {default_limit}".format(
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
        raise JscpdWorklistError(
            "The jscpd report '{path}' does not exist.".format(path=display_path(candidate))
        )
    return candidate


def load_duplicates(report_path: Path) -> list[JsonDict]:
    """Load and validate the raw duplicate list from a jscpd JSON report."""

    try:
        payload = json.loads(report_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise ReportSchemaError(
            "The jscpd report at '{path}' is not valid JSON.".format(path=display_path(report_path))
        ) from error

    if not isinstance(payload, dict):
        raise ReportSchemaError(
            "The jscpd report at '{path}' must be a JSON object.".format(path=display_path(report_path))
        )

    duplicates = payload.get("duplicates")
    if not isinstance(duplicates, list):
        raise ReportSchemaError(
            "The jscpd report at '{path}' is missing the duplicates array.".format(
                path=display_path(report_path)
            )
        )

    validated_duplicates: list[JsonDict] = []
    for duplicate in duplicates:
        if not isinstance(duplicate, dict):
            raise ReportSchemaError("Every jscpd duplicate entry must be a JSON object.")
        validated_duplicates.append(duplicate)
    return validated_duplicates


def build_worklist(report_path: Path, limit: int) -> list[DuplicateClusterRecord]:
    """Build a sorted duplicate-cluster worklist from a jscpd report."""

    if limit <= 0:
        raise JscpdWorklistError("The duplicate-cluster limit must be greater than zero.")

    duplicates = load_duplicates(report_path)
    clusters = cluster_duplicates(duplicates)
    ordered_clusters = sorted(clusters, key=cluster_sort_key)
    return ordered_clusters[:limit]


def cluster_duplicates(duplicates: Sequence[JsonDict]) -> list[DuplicateClusterRecord]:
    """Group raw duplicate pairs by normalized fragment fingerprint."""

    clusters: dict[str, DuplicateClusterAccumulator] = {}
    for duplicate in duplicates:
        fragment = extract_fragment(duplicate)
        lines = require_integer(duplicate.get("lines"), "duplicate.lines")
        tokens = require_integer(duplicate.get("tokens"), "duplicate.tokens")
        normalized_fragment = normalize_fragment(fragment)
        fingerprint = build_fingerprint(normalized_fragment, lines)
        cluster = clusters.get(fingerprint)
        if cluster is None:
            cluster = DuplicateClusterAccumulator(
                fingerprint=fingerprint,
                normalized_fragment=normalized_fragment,
                lines=lines,
                tokens=tokens,
            )
            clusters[fingerprint] = cluster
        cluster.add_pair(duplicate)
    return [finalize_cluster(cluster) for cluster in clusters.values()]


def finalize_cluster(cluster: DuplicateClusterAccumulator) -> DuplicateClusterRecord:
    """Convert a mutable cluster accumulator into a serializable worklist record."""

    occurrences = tuple(sorted(cluster.occurrences.values()))
    files = tuple(sorted({occurrence.file for occurrence in occurrences}))
    common_parent = build_common_parent(files)
    occurrence_count = len(occurrences)
    cluster_id = "cluster:{fingerprint}:{lines}:{occurrences}".format(
        fingerprint=cluster.fingerprint,
        lines=cluster.lines,
        occurrences=occurrence_count,
    )
    return DuplicateClusterRecord(
        id=cluster_id,
        fingerprint=cluster.fingerprint,
        lines=cluster.lines,
        tokens=cluster.tokens,
        pair_count=cluster.pair_count,
        occurrence_count=occurrence_count,
        files=files,
        common_parent=common_parent,
        recommended_strategy=build_recommended_strategy(common_parent, len(files), occurrence_count),
        fragment_preview=render_fragment_preview(cluster.normalized_fragment),
        occurrences=occurrences,
    )


def extract_occurrence(duplicate: JsonDict, file_key: str) -> DuplicateOccurrence:
    """Extract one occurrence entry from a raw jscpd duplicate object."""

    file_payload = require_dict(duplicate.get(file_key), file_key)
    file_name = require_string(file_payload.get("name"), "{key}.name".format(key=file_key))
    start_location = require_dict(file_payload.get("startLoc"), "{key}.startLoc".format(key=file_key))
    end_location = require_dict(file_payload.get("endLoc"), "{key}.endLoc".format(key=file_key))
    return DuplicateOccurrence(
        file=file_name,
        start_line=require_integer(start_location.get("line"), "{key}.startLoc.line".format(key=file_key)),
        end_line=require_integer(end_location.get("line"), "{key}.endLoc.line".format(key=file_key)),
        start_column=require_integer(
            start_location.get("column"),
            "{key}.startLoc.column".format(key=file_key),
        ),
        end_column=require_integer(
            end_location.get("column"),
            "{key}.endLoc.column".format(key=file_key),
        ),
    )


def require_dict(value: object, label: str) -> JsonDict:
    """Require that a JSON value is a dictionary."""

    if isinstance(value, dict):
        return value
    raise ReportSchemaError("The jscpd field '{label}' must be an object.".format(label=label))


def require_string(value: object, label: str) -> str:
    """Require that a JSON value is a string."""

    if isinstance(value, str):
        return value
    raise ReportSchemaError("The jscpd field '{label}' must be a string.".format(label=label))


def require_integer(value: object, label: str) -> int:
    """Require that a JSON value is an integer-like number."""

    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    raise ReportSchemaError("The jscpd field '{label}' must be numeric.".format(label=label))


def extract_fragment(duplicate: JsonDict) -> str:
    """Return the reported fragment or reconstruct it from the first source range."""

    reported_fragment = duplicate.get("fragment")
    if isinstance(reported_fragment, str) and reported_fragment:
        return reported_fragment

    file_payload = require_dict(duplicate.get("firstFile"), "firstFile")
    file_name = require_string(file_payload.get("name"), "firstFile.name")
    start_location = require_dict(file_payload.get("startLoc"), "firstFile.startLoc")
    end_location = require_dict(file_payload.get("endLoc"), "firstFile.endLoc")
    start_position = require_integer(start_location.get("position"), "firstFile.startLoc.position")
    end_position = require_integer(end_location.get("position"), "firstFile.endLoc.position")

    source_path = resolve_source_path(file_name)
    source = source_path.read_text(encoding="utf-8")
    if start_position < 0 or end_position <= start_position or end_position > len(source):
        raise ReportSchemaError(
            "The jscpd source range for '{path}' is outside the source file.".format(
                path=display_path(source_path)
            )
        )
    return source[start_position:end_position]


def resolve_source_path(file_name: str) -> Path:
    """Resolve a report file path within the repository."""

    candidate = Path(file_name)
    if not candidate.is_absolute():
        candidate = REPO_ROOT / candidate
    candidate = candidate.resolve()
    try:
        candidate.relative_to(REPO_ROOT)
    except ValueError as error:
        raise ReportSchemaError(
            "The jscpd source path '{path}' is outside the repository.".format(path=candidate)
        ) from error
    if not candidate.exists():
        raise ReportSchemaError(
            "The jscpd source path '{path}' does not exist.".format(path=display_path(candidate))
        )
    return candidate


def normalize_fragment(fragment: str) -> str:
    """Normalize duplicate fragment text for hashing and preview output."""

    return "\n".join(line.rstrip() for line in fragment.strip().splitlines())


def build_fingerprint(fragment: str, lines: int) -> str:
    """Build a stable cluster fingerprint from the normalized fragment and line count."""

    token_shape = re.sub(r"\s+", "", fragment)
    payload = "{lines}\n{fragment}".format(lines=lines, fragment=token_shape).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()[:12]


def build_common_parent(files: Sequence[str]) -> str | None:
    """Return the shared directory path for all files in a cluster when one exists."""

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


def build_recommended_strategy(common_parent: str | None, file_count: int, occurrence_count: int) -> str:
    """Describe the expected remediation style for a duplicate cluster."""

    if common_parent:
        return (
            "Extract a shared helper or module under '{parent}' and remove the {occurrences} repeated occurrences "
            "across {file_count} files.".format(
                parent=common_parent,
                occurrences=occurrence_count,
                file_count=file_count,
            )
        )
    return (
        "Extract the shared logic at the nearest maintained boundary and remove the {occurrences} repeated "
        "occurrences across {file_count} files.".format(
            occurrences=occurrence_count,
            file_count=file_count,
        )
    )


def render_fragment_preview(fragment: str) -> str:
    """Render a compact multi-line preview for one duplicate cluster."""

    preview_lines = []
    for raw_line in fragment.splitlines()[:MAX_PREVIEW_LINES]:
        preview_lines.append(raw_line[:MAX_PREVIEW_WIDTH])
    return "\n".join(preview_lines)


def cluster_sort_key(cluster: DuplicateClusterRecord) -> tuple[int, int, int, int, tuple[str, ...], str]:
    """Build a deterministic sort key for duplicate clusters."""

    return (
        -cluster.lines,
        -cluster.tokens,
        -cluster.occurrence_count,
        -cluster.pair_count,
        cluster.files,
        cluster.fingerprint,
    )


def write_jsonl(output_path: Path, worklist: Sequence[DuplicateClusterRecord]) -> None:
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
        LOGGER.info("Building jscpd duplicate worklist.")
        LOGGER.info("Report path: %s", report_path)
        LOGGER.info("Output path: %s", output_path)
        LOGGER.info("Cluster limit: %s", args.limit)
        worklist = build_worklist(report_path, args.limit)
        write_jsonl(output_path, worklist)
        print(output_path)
        print("{count} duplicate clusters selected".format(count=len(worklist)))
        return 0
    except (JscpdWorklistError, OSError, ValueError) as error:
        LOGGER.exception("Failed to build the jscpd worklist: %s", error)
        print("error: {message}".format(message=error), file=sys.stderr)
        return 1


def main() -> int:
    """CLI entrypoint."""

    return execute()


if __name__ == "__main__":
    raise SystemExit(main())
