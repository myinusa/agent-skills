#!/usr/bin/env python3
"""Run the Foundry source dupes wrapper fresh and build the current duplicate-family worklist."""

from __future__ import annotations

import argparse
import json
import logging
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path


LOGGER = logging.getLogger("fallow_dupes_batch")
SCRIPT_PATH = Path(__file__).resolve()
SKILL_ROOT = SCRIPT_PATH.parents[1]
REPO_ROOT = SCRIPT_PATH.parents[4]
APP_DUPES_WRAPPER = REPO_ROOT / "scripts/tooling/fallow-app-dupes/cli.py"
WORKLIST_BUILDER = SCRIPT_PATH.with_name("build_worklist.py")
DEFAULT_OUTPUT_DIR = Path("output/fallow/app-dupes")
DEFAULT_LIMIT = 12
DEFAULT_LOG_LEVEL = "INFO"
SUPPORTED_APPS = ("typescript", "csharp", "python")
SUPPORTED_LOG_LEVELS = ("DEBUG", "INFO", "WARNING", "ERROR")


class FallowDupesBatchError(RuntimeError):
    """Base error for Fallow dupes batch selection."""


class ManifestParseError(FallowDupesBatchError):
    """Raised when the wrapper manifest JSON cannot be parsed."""


@dataclass(frozen=True)
class BatchConfig:
    """Normalized batch-run configuration."""

    app: str
    limit: int
    output_dir: Path
    log_level: str

    @property
    def app_output_dir(self) -> Path:
        return self.output_dir / self.app


@dataclass(frozen=True)
class WrapperManifest:
    """Subset of the wrapper manifest required for batch selection."""

    run_token: str
    app: str
    workspace: str
    json_report: str
    text_report: str
    wrapper_metadata_path: str
    manifest_path: str
    current_json_report: str | None
    current_text_report: str | None
    current_wrapper_metadata_path: str | None
    current_manifest_path: str | None
    clone_group_count: int
    clone_family_count: int
    duplicated_lines: int
    duplication_percentage: float


@dataclass(frozen=True)
class BatchSelectionSummary:
    """Machine-readable summary of one selected duplicate batch."""

    run_token: str
    app: str
    limit: int
    clone_group_count: int
    clone_family_count: int
    duplicated_lines: int
    duplication_percentage: float
    report_path: str
    text_report_path: str
    wrapper_manifest_path: str
    worklist_path: str
    selected_families: int


def build_parser() -> argparse.ArgumentParser:
    """Create the CLI parser for the batch runner."""

    parser = argparse.ArgumentParser(
        description="Run the Foundry source dupes wrapper fresh and build the current duplicate-family worklist.",
    )
    parser.add_argument(
        "app",
        choices=SUPPORTED_APPS,
        help="Source scope passed to scripts/tooling/fallow-app-dupes/cli.py.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=DEFAULT_LIMIT,
        help="Maximum number of duplicate families to select. Default: {default_limit}".format(
            default_limit=DEFAULT_LIMIT
        ),
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="Directory for generated artifacts. Default: {default_output}".format(
            default_output=DEFAULT_OUTPUT_DIR
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


def build_config(args: argparse.Namespace) -> BatchConfig:
    """Normalize parsed arguments into an immutable configuration object."""

    if args.limit <= 0:
        raise FallowDupesBatchError("The duplicate-family limit must be greater than zero.")

    return BatchConfig(
        app=args.app,
        limit=args.limit,
        output_dir=resolve_output_dir(args.output_dir),
        log_level=args.log_level,
    )


def resolve_output_dir(raw_path: Path) -> Path:
    """Resolve an output directory relative to the repo root."""

    candidate = raw_path.expanduser()
    if not candidate.is_absolute():
        candidate = (REPO_ROOT / candidate).resolve()
    else:
        candidate = candidate.resolve()
    return candidate


def build_wrapper_command(config: BatchConfig) -> list[str]:
    """Build the subprocess command for the repo-owned source dupes wrapper."""

    return [
        sys.executable,
        str(APP_DUPES_WRAPPER),
        config.app,
        "--output-dir",
        str(config.output_dir),
        "--write-current",
        "--stdout-format",
        "json",
        "--log-level",
        config.log_level,
    ]


def build_worklist_command(config: BatchConfig, report_path: Path) -> list[str]:
    """Build the subprocess command for the family worklist builder."""

    return [
        sys.executable,
        str(WORKLIST_BUILDER),
        str(report_path),
        "--app",
        config.app,
        "--limit",
        str(config.limit),
        "--output",
        str(worklist_path(config)),
        "--log-level",
        config.log_level,
    ]


def run_command(command: list[str], label: str) -> subprocess.CompletedProcess[str]:
    """Run a subprocess and capture its output."""

    LOGGER.info("Running %s command: %s", label, " ".join(command))
    return subprocess.run(
        command,
        cwd=REPO_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )


def parse_wrapper_manifest(stdout: str) -> WrapperManifest:
    """Parse the JSON manifest emitted by scripts/tooling/fallow-app-dupes/cli.py."""

    try:
        payload = json.loads(stdout)
    except json.JSONDecodeError as error:
        raise ManifestParseError("The source dupes wrapper did not emit valid JSON manifest output.") from error

    if not isinstance(payload, dict):
        raise ManifestParseError("The source dupes wrapper manifest payload must be a JSON object.")

    return WrapperManifest(
        run_token=require_string(payload.get("run_token"), "run_token"),
        app=require_string(payload.get("app"), "app"),
        workspace=require_string(payload.get("workspace"), "workspace"),
        json_report=require_string(payload.get("json_report"), "json_report"),
        text_report=require_string(payload.get("text_report"), "text_report"),
        wrapper_metadata_path=require_string(payload.get("wrapper_metadata_path"), "wrapper_metadata_path"),
        manifest_path=require_string(payload.get("manifest_path"), "manifest_path"),
        current_json_report=require_optional_string(payload.get("current_json_report"), "current_json_report"),
        current_text_report=require_optional_string(payload.get("current_text_report"), "current_text_report"),
        current_wrapper_metadata_path=require_optional_string(
            payload.get("current_wrapper_metadata_path"),
            "current_wrapper_metadata_path",
        ),
        current_manifest_path=require_optional_string(payload.get("current_manifest_path"), "current_manifest_path"),
        clone_group_count=require_integer(payload.get("clone_group_count"), "clone_group_count"),
        clone_family_count=require_integer(payload.get("clone_family_count"), "clone_family_count"),
        duplicated_lines=require_integer(payload.get("duplicated_lines"), "duplicated_lines"),
        duplication_percentage=require_float(payload.get("duplication_percentage"), "duplication_percentage"),
    )


def require_string(value: object, label: str) -> str:
    """Require that a JSON value is a string."""

    if isinstance(value, str):
        return value
    raise ManifestParseError("The source dupes wrapper field '{label}' must be a string.".format(label=label))


def require_optional_string(value: object, label: str) -> str | None:
    """Require that a JSON value is either null or a string."""

    if value is None:
        return None
    if isinstance(value, str):
        return value
    raise ManifestParseError(
        "The source dupes wrapper field '{label}' must be null or a string.".format(label=label)
    )


def require_integer(value: object, label: str) -> int:
    """Require that a JSON value is an integer-like number."""

    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    raise ManifestParseError("The source dupes wrapper field '{label}' must be numeric.".format(label=label))


def require_float(value: object, label: str) -> float:
    """Require that a JSON value is a number."""

    if isinstance(value, int | float):
        return float(value)
    raise ManifestParseError("The source dupes wrapper field '{label}' must be numeric.".format(label=label))


def resolve_report_path(manifest: WrapperManifest) -> Path:
    """Resolve the best available report path from a wrapper manifest."""

    if manifest.current_json_report:
        return resolve_repo_path(manifest.current_json_report)
    return resolve_repo_path(manifest.json_report)


def resolve_wrapper_manifest_path(manifest: WrapperManifest) -> Path:
    """Resolve the best available manifest path from a wrapper manifest."""

    if manifest.current_manifest_path:
        return resolve_repo_path(manifest.current_manifest_path)
    return resolve_repo_path(manifest.manifest_path)


def resolve_text_report_path(manifest: WrapperManifest) -> Path:
    """Resolve the best available text report path from a wrapper manifest."""

    if manifest.current_text_report:
        return resolve_repo_path(manifest.current_text_report)
    return resolve_repo_path(manifest.text_report)


def resolve_repo_path(raw_path: str) -> Path:
    """Resolve a repo-relative or absolute path string into an absolute path."""

    candidate = Path(raw_path).expanduser()
    if not candidate.is_absolute():
        candidate = (REPO_ROOT / candidate).resolve()
    else:
        candidate = candidate.resolve()
    return candidate


def worklist_path(config: BatchConfig) -> Path:
    """Return the stable current worklist path for the batch."""

    return config.app_output_dir / "current-worklist.jsonl"


def selection_summary_path(config: BatchConfig) -> Path:
    """Return the stable current batch-selection summary path."""

    return config.app_output_dir / "current-selection.json"


def count_worklist_entries(worklist_path_value: Path) -> int:
    """Count the selected JSONL worklist entries."""

    if not worklist_path_value.exists():
        raise FallowDupesBatchError(
            "Expected worklist output at '{path}' but it was not created.".format(
                path=display_path(worklist_path_value)
            )
        )
    count = 0
    for line in worklist_path_value.read_text(encoding="utf-8").splitlines():
        if line.strip():
            count += 1
    return count


def write_selection_summary(config: BatchConfig, manifest: WrapperManifest, selected_families: int) -> Path:
    """Write a machine-readable summary for the currently selected batch."""

    summary_path = selection_summary_path(config)
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    payload = BatchSelectionSummary(
        run_token=manifest.run_token,
        app=manifest.app,
        limit=config.limit,
        clone_group_count=manifest.clone_group_count,
        clone_family_count=manifest.clone_family_count,
        duplicated_lines=manifest.duplicated_lines,
        duplication_percentage=manifest.duplication_percentage,
        report_path=display_path(resolve_report_path(manifest)),
        text_report_path=display_path(resolve_text_report_path(manifest)),
        wrapper_manifest_path=display_path(resolve_wrapper_manifest_path(manifest)),
        worklist_path=display_path(worklist_path(config)),
        selected_families=selected_families,
    )
    summary_path.write_text(
        json.dumps(asdict(payload), indent=2, ensure_ascii=True) + "\n",
        encoding="utf-8",
    )
    return summary_path


def emit_result(summary_path: Path, manifest: WrapperManifest, selected_families: int, config: BatchConfig) -> None:
    """Emit human-readable completion output for the batch runner."""

    print("Scope: {app}".format(app=manifest.app))
    print("Report: {path}".format(path=display_path(resolve_report_path(manifest))))
    print("Text report: {path}".format(path=display_path(resolve_text_report_path(manifest))))
    print("Wrapper manifest: {path}".format(path=display_path(resolve_wrapper_manifest_path(manifest))))
    print("Worklist: {path}".format(path=display_path(worklist_path(config))))
    print("Selection summary: {path}".format(path=display_path(summary_path)))
    print("{count} duplicate families selected".format(count=selected_families))


def forward_failure_output(result: subprocess.CompletedProcess[str], label: str) -> None:
    """Forward stderr or stdout from a failed subprocess."""

    stderr = result.stderr.strip()
    stdout = result.stdout.strip()
    if stderr:
        print(stderr, file=sys.stderr)
        return
    if stdout:
        print(stdout, file=sys.stderr)
        return
    print("{label} failed without any captured output.".format(label=label), file=sys.stderr)


def execute() -> int:
    """Run the batch selection end to end and return a process exit code."""

    parser = build_parser()
    args = parser.parse_args()
    configure_logging(args.log_level)

    try:
        config = build_config(args)
        LOGGER.info("Starting Fallow duplicate-family batch selection.")
        LOGGER.info("Skill root: %s", SKILL_ROOT)
        LOGGER.info("Repository root: %s", REPO_ROOT)
        LOGGER.info("Scope: %s", config.app)
        LOGGER.info("Limit: %s", config.limit)
        LOGGER.info("Output directory: %s", config.output_dir)

        wrapper_result = run_command(build_wrapper_command(config), "app-dupes-wrapper")
        if wrapper_result.returncode != 0:
            forward_failure_output(wrapper_result, "app-dupes-wrapper")
            return wrapper_result.returncode

        manifest = parse_wrapper_manifest(wrapper_result.stdout)
        worklist_result = run_command(build_worklist_command(config, resolve_report_path(manifest)), "worklist-builder")
        if worklist_result.returncode != 0:
            forward_failure_output(worklist_result, "worklist-builder")
            return worklist_result.returncode

        selected_families = count_worklist_entries(worklist_path(config))
        summary_path = write_selection_summary(config, manifest, selected_families)
        emit_result(summary_path, manifest, selected_families, config)
        return 0
    except (FallowDupesBatchError, ManifestParseError, OSError, ValueError) as error:
        LOGGER.exception("Failed to run the Fallow dupes batch selector: %s", error)
        print("error: {message}".format(message=error), file=sys.stderr)
        return 1


def display_path(path: Path) -> str:
    """Render a path relative to the repo root when possible."""

    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def main() -> int:
    """CLI entrypoint."""

    return execute()


if __name__ == "__main__":
    raise SystemExit(main())
