#!/usr/bin/env python3
"""Run the Foundry jscpd wrapper fresh and build the current duplicate-cluster worklist."""

from __future__ import annotations

import argparse
import json
import logging
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path


LOGGER = logging.getLogger("jscpd_batch")
SCRIPT_PATH = Path(__file__).resolve()
SKILL_ROOT = SCRIPT_PATH.parents[1]
REPO_ROOT = SCRIPT_PATH.parents[4]
WORKLIST_BUILDER = SCRIPT_PATH.with_name("build_worklist.py")
DEFAULT_LIMIT = 12
DEFAULT_LOG_LEVEL = "INFO"
SUPPORTED_LOG_LEVELS = ("DEBUG", "INFO", "WARNING", "ERROR")


@dataclass(frozen=True)
class BatchProfile:
    name: str
    wrapper_path: Path
    default_scope: str
    output_dir: Path
    latest_prefix: str


BATCH_PROFILES: dict[str, BatchProfile] = {
    "python": BatchProfile(
        name="python",
        wrapper_path=REPO_ROOT / "scripts/tooling/python-jscpd/cli.py",
        default_scope="repo",
        output_dir=Path("output/jscpd"),
        latest_prefix="current-jscpd",
    ),
    "csharp": BatchProfile(
        name="csharp",
        wrapper_path=SCRIPT_PATH.with_name("csharp_wrapper.py"),
        default_scope="backend",
        output_dir=Path("output/jscpd-csharp"),
        latest_prefix="current-jscpd-csharp",
    ),
}


class JscpdBatchError(RuntimeError):
    """Base error for jscpd batch selection."""


class ManifestParseError(JscpdBatchError):
    """Raised when the wrapper manifest JSON cannot be parsed."""


@dataclass(frozen=True)
class BatchConfig:
    """Normalized batch-run configuration."""

    profile: BatchProfile
    scope: str
    explicit_paths: tuple[Path, ...]
    limit: int
    output_dir: Path
    latest_prefix: str
    log_level: str


@dataclass(frozen=True)
class WrapperManifest:
    """Subset of the wrapper manifest required for batch selection."""

    profile: str
    run_token: str
    json_report: str
    html_report: str
    manifest_path: str
    current_json_report: str | None
    current_html_report: str | None
    current_manifest_path: str | None
    clone_count: int
    duplicated_lines: int
    duplicate_percentage: float


@dataclass(frozen=True)
class BatchSelectionSummary:
    """Machine-readable summary of one selected duplicate batch."""

    profile: str
    run_token: str
    limit: int
    clone_count: int
    duplicated_lines: int
    duplicate_percentage: float
    report_path: str
    html_report: str
    wrapper_manifest_path: str
    worklist_path: str
    selected_clusters: int


def build_parser() -> argparse.ArgumentParser:
    """Create the CLI parser for the batch runner."""

    parser = argparse.ArgumentParser(
        description="Run the Meridian jscpd wrapper fresh and build the current duplicate-cluster worklist.",
    )
    parser.add_argument(
        "--profile",
        choices=tuple(BATCH_PROFILES.keys()),
        default="python",
        help="Wrapper profile to use. Default: python",
    )
    parser.add_argument(
        "scope",
        nargs="?",
        default=None,
        help="Named scan scope passed to the selected jscpd wrapper.",
    )
    parser.add_argument(
        "--path",
        action="append",
        default=[],
        dest="paths",
        help="Repo-relative or absolute file/directory path to scan. Repeatable.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=DEFAULT_LIMIT,
        help="Maximum number of duplicate clusters to select. Default: {default_limit}".format(
            default_limit=DEFAULT_LIMIT
        ),
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Directory for generated artifacts. Defaults to the selected profile output directory.",
    )
    parser.add_argument(
        "--latest-prefix",
        default=None,
        help="Filename prefix for current artifacts. Defaults to the selected profile prefix.",
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
        raise JscpdBatchError("The duplicate-cluster limit must be greater than zero.")

    profile = BATCH_PROFILES[args.profile]
    explicit_paths = tuple(Path(raw_path) for raw_path in args.paths)
    scope = args.scope or profile.default_scope
    output_dir = resolve_output_dir(args.output_dir or profile.output_dir)
    latest_prefix = (args.latest_prefix or profile.latest_prefix).strip()
    if not latest_prefix:
        raise JscpdBatchError("The latest-prefix value must not be empty.")

    return BatchConfig(
        profile=profile,
        scope=scope,
        explicit_paths=explicit_paths,
        limit=args.limit,
        output_dir=output_dir,
        latest_prefix=latest_prefix,
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
    """Build the subprocess command for the repo-owned jscpd wrapper."""

    command = [
        sys.executable,
        str(config.profile.wrapper_path),
        config.scope,
        "--output-dir",
        str(config.output_dir),
        "--write-current",
        "--latest-prefix",
        config.latest_prefix,
        "--stdout-format",
        "json",
        "--log-level",
        config.log_level,
    ]
    for path in config.explicit_paths:
        command.extend(["--path", str(path)])
    return command


def build_worklist_command(config: BatchConfig, report_path: Path) -> list[str]:
    """Build the subprocess command for the cluster worklist builder."""

    return [
        sys.executable,
        str(WORKLIST_BUILDER),
        str(report_path),
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
    """Parse the JSON manifest emitted by the selected jscpd wrapper."""

    try:
        payload = json.loads(stdout)
    except json.JSONDecodeError as error:
        raise ManifestParseError("The jscpd wrapper did not emit valid JSON manifest output.") from error

    if not isinstance(payload, dict):
        raise ManifestParseError("The jscpd wrapper manifest payload must be a JSON object.")

    return WrapperManifest(
        profile=require_string(payload.get("profile"), "profile"),
        run_token=require_string(payload.get("run_token"), "run_token"),
        json_report=require_string(payload.get("json_report"), "json_report"),
        html_report=require_string(payload.get("html_report"), "html_report"),
        manifest_path=require_string(payload.get("manifest_path"), "manifest_path"),
        current_json_report=require_optional_string(payload.get("current_json_report"), "current_json_report"),
        current_html_report=require_optional_string(
            payload.get("current_html_report"),
            "current_html_report",
        ),
        current_manifest_path=require_optional_string(
            payload.get("current_manifest_path"),
            "current_manifest_path",
        ),
        clone_count=require_integer(payload.get("clone_count"), "clone_count"),
        duplicated_lines=require_integer(payload.get("duplicated_lines"), "duplicated_lines"),
        duplicate_percentage=require_float(payload.get("duplicate_percentage"), "duplicate_percentage"),
    )


def require_string(value: object, label: str) -> str:
    """Require that a JSON value is a string."""

    if isinstance(value, str):
        return value
    raise ManifestParseError("The jscpd wrapper field '{label}' must be a string.".format(label=label))


def require_optional_string(value: object, label: str) -> str | None:
    """Require that a JSON value is either null or a string."""

    if value is None:
        return None
    if isinstance(value, str):
        return value
    raise ManifestParseError("The jscpd wrapper field '{label}' must be null or a string.".format(label=label))


def require_integer(value: object, label: str) -> int:
    """Require that a JSON value is an integer-like number."""

    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    raise ManifestParseError("The jscpd wrapper field '{label}' must be numeric.".format(label=label))


def require_float(value: object, label: str) -> float:
    """Require that a JSON value is a number."""

    if isinstance(value, int | float):
        return float(value)
    raise ManifestParseError("The jscpd wrapper field '{label}' must be numeric.".format(label=label))


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


def resolve_html_report_path(manifest: WrapperManifest) -> Path:
    """Resolve the best available HTML report path from a wrapper manifest."""

    if manifest.current_html_report:
        return resolve_repo_path(manifest.current_html_report)
    return resolve_repo_path(manifest.html_report)


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

    return config.output_dir / "{prefix}-worklist.jsonl".format(prefix=config.latest_prefix)


def selection_summary_path(config: BatchConfig) -> Path:
    """Return the stable current batch-selection summary path."""

    return config.output_dir / "{prefix}-selection.json".format(prefix=config.latest_prefix)


def count_worklist_entries(worklist_path_value: Path) -> int:
    """Count the selected JSONL worklist entries."""

    if not worklist_path_value.exists():
        raise JscpdBatchError(
            "Expected worklist output at '{path}' but it was not created.".format(
                path=display_path(worklist_path_value)
            )
        )
    count = 0
    for line in worklist_path_value.read_text(encoding="utf-8").splitlines():
        if line.strip():
            count += 1
    return count


def write_selection_summary(config: BatchConfig, manifest: WrapperManifest, selected_clusters: int) -> Path:
    """Write a machine-readable summary for the currently selected batch."""

    summary_path = selection_summary_path(config)
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    report_path = resolve_report_path(manifest)
    html_report_path = resolve_html_report_path(manifest)
    wrapper_manifest_path = resolve_wrapper_manifest_path(manifest)
    payload = BatchSelectionSummary(
        profile=manifest.profile,
        run_token=manifest.run_token,
        limit=config.limit,
        clone_count=manifest.clone_count,
        duplicated_lines=manifest.duplicated_lines,
        duplicate_percentage=manifest.duplicate_percentage,
        report_path=display_path(report_path),
        html_report=display_path(html_report_path),
        wrapper_manifest_path=display_path(wrapper_manifest_path),
        worklist_path=display_path(worklist_path(config)),
        selected_clusters=selected_clusters,
    )
    summary_path.write_text(
        json.dumps(asdict(payload), indent=2, ensure_ascii=True) + "\n",
        encoding="utf-8",
    )
    return summary_path


def emit_result(summary_path: Path, manifest: WrapperManifest, selected_clusters: int, config: BatchConfig) -> None:
    """Emit human-readable completion output for the batch runner."""

    print("Report: {path}".format(path=display_path(resolve_report_path(manifest))))
    print("HTML report: {path}".format(path=display_path(resolve_html_report_path(manifest))))
    print("Wrapper manifest: {path}".format(path=display_path(resolve_wrapper_manifest_path(manifest))))
    print("Worklist: {path}".format(path=display_path(worklist_path(config))))
    print("Selection summary: {path}".format(path=display_path(summary_path)))
    print("{count} duplicate clusters selected".format(count=selected_clusters))


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
        LOGGER.info("Starting jscpd duplicate-batch selection.")
        LOGGER.info("Skill root: %s", SKILL_ROOT)
        LOGGER.info("Repository root: %s", REPO_ROOT)
        LOGGER.info("Profile: %s", config.profile.name)
        LOGGER.info("Scope: %s", config.scope)
        LOGGER.info("Explicit paths: %s", [str(path) for path in config.explicit_paths])
        LOGGER.info("Limit: %s", config.limit)
        LOGGER.info("Output directory: %s", config.output_dir)
        LOGGER.info("Latest prefix: %s", config.latest_prefix)

        wrapper_result = run_command(build_wrapper_command(config), "jscpd-wrapper")
        if wrapper_result.returncode != 0:
            forward_failure_output(wrapper_result, "jscpd-wrapper")
            return wrapper_result.returncode

        manifest = parse_wrapper_manifest(wrapper_result.stdout)
        worklist_result = run_command(build_worklist_command(config, resolve_report_path(manifest)), "worklist-builder")
        if worklist_result.returncode != 0:
            forward_failure_output(worklist_result, "worklist-builder")
            return worklist_result.returncode

        selected_clusters = count_worklist_entries(worklist_path(config))
        summary_path = write_selection_summary(config, manifest, selected_clusters)
        emit_result(summary_path, manifest, selected_clusters, config)
        return 0
    except (JscpdBatchError, ManifestParseError, OSError, ValueError) as error:
        LOGGER.exception("Failed to run the jscpd batch selector: %s", error)
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
