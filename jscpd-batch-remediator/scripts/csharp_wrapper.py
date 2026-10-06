#!/usr/bin/env python3
"""Run a fresh jscpd scan over Foundry production C# source files."""

from __future__ import annotations

import argparse
import json
import logging
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path


LOGGER = logging.getLogger("foundry_csharp_jscpd")
SCRIPT_PATH = Path(__file__).resolve()
REPO_ROOT = SCRIPT_PATH.parents[4]
DEFAULT_OUTPUT_DIR = Path("output/jscpd-csharp")
DEFAULT_PREFIX = "current-jscpd-csharp"
USING_DIRECTIVE = re.compile(
    r"^\s*(?:global\s+)?using\s+(?!var\b|\()[^;\r\n]+;(?:\s*//.*)?\s*$"
)


@dataclass(frozen=True)
class Manifest:
    profile: str
    run_token: str
    selection_label: str
    scope: str
    explicit_paths: tuple[str, ...]
    roots: tuple[str, ...]
    scanned_files: int
    output_dir: str
    json_report: str
    html_report: str
    manifest_path: str
    current_json_report: str | None
    current_html_report: str | None
    current_manifest_path: str | None
    detection_date: str | None
    clone_count: int
    duplicated_lines: int
    duplicated_tokens: int
    duplicate_percentage: float
    duplicate_token_percentage: float


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scope", nargs="?", default="backend")
    parser.add_argument("--path", action="append", default=[])
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--write-current", action="store_true")
    parser.add_argument("--latest-prefix", default=DEFAULT_PREFIX)
    parser.add_argument("--stdout-format", choices=("text", "json"), default="text")
    parser.add_argument(
        "--log-level",
        choices=("DEBUG", "INFO", "WARNING", "ERROR"),
        default="INFO",
    )
    return parser


def resolve_repo_path(raw_path: str | Path) -> Path:
    candidate = Path(raw_path).expanduser()
    if not candidate.is_absolute():
        candidate = REPO_ROOT / candidate
    candidate = candidate.resolve()
    try:
        candidate.relative_to(REPO_ROOT)
    except ValueError as error:
        raise ValueError(f"Path is outside the repository: {candidate}") from error
    if not candidate.exists():
        raise FileNotFoundError(candidate)
    return candidate


def resolve_roots(scope: str, explicit_paths: list[str]) -> tuple[Path, ...]:
    if explicit_paths:
        return tuple(dict.fromkeys(resolve_repo_path(path) for path in explicit_paths))
    if scope in {"backend", "repo"}:
        return (resolve_repo_path("apps/backend"),)
    return (resolve_repo_path(scope),)


def display_path(path: Path) -> str:
    try:
        return path.relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return str(path)


def list_production_files(roots: tuple[Path, ...]) -> tuple[Path, ...]:
    command = [
        "git",
        "ls-files",
        "--cached",
        "--others",
        "--exclude-standard",
        "--",
        *(display_path(root) for root in roots),
    ]
    result = subprocess.run(
        command,
        cwd=REPO_ROOT,
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    files: set[Path] = set()
    for raw_path in result.stdout.splitlines():
        if not raw_path.lower().endswith(".cs"):
            continue
        relative_path = Path(raw_path)
        lowered_parts = tuple(part.lower() for part in relative_path.parts)
        if "tests" in lowered_parts or "bin" in lowered_parts or "obj" in lowered_parts:
            continue
        if any(part.endswith(".tests") for part in lowered_parts):
            continue
        source_path = (REPO_ROOT / relative_path).resolve()
        if source_path.is_file():
            files.add(source_path)
    if not files:
        raise RuntimeError("No production C# files matched the requested scope.")
    return tuple(sorted(files))


def sanitise_source(source: str) -> str:
    lines: list[str] = []
    for line in source.splitlines(keepends=True):
        content = line.rstrip("\r\n")
        if USING_DIRECTIVE.fullmatch(content):
            lines.append("".join(character if character in "\r\n" else " " for character in line))
        else:
            lines.append(line)
    return "".join(lines)


def prepare_scan(files: tuple[Path, ...]) -> Path:
    prepared_root = Path(tempfile.mkdtemp(prefix="foundry-jscpd-csharp-")).resolve()
    for source_path in files:
        destination = prepared_root / source_path.relative_to(REPO_ROOT)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(
            sanitise_source(source_path.read_text(encoding="utf-8")),
            encoding="utf-8",
        )
    return prepared_root


def run_jscpd(prepared_root: Path, output_dir: Path) -> None:
    pnpm = shutil.which("pnpm") or "pnpm"
    command = [
        pnpm,
        "exec",
        "jscpd",
        "--pattern",
        "**/*.cs",
        "--format",
        "csharp",
        "--silent",
        "--reporters",
        "json,html",
        "--output",
        str(output_dir),
        "--no-gitignore",
        "--no-tips",
        str(prepared_root / "apps/backend"),
    ]
    LOGGER.info("Running jscpd over prepared production sources.")
    result = subprocess.run(
        command,
        cwd=REPO_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip() or "jscpd failed without output."
        raise RuntimeError(message)


def rewrite_report_paths(report_path: Path, prepared_root: Path) -> None:
    payload = json.loads(report_path.read_text(encoding="utf-8"))
    prefixes = (
        f"{prepared_root.as_posix()}/",
        f"{str(prepared_root).replace(chr(92), '/')}/",
        f"{prepared_root}\\",
    )
    duplicates = payload.get("duplicates", [])
    for duplicate in duplicates:
        for key in ("firstFile", "secondFile"):
            file_payload = duplicate.get(key)
            if not isinstance(file_payload, dict):
                continue
            file_name = file_payload.get("name")
            if not isinstance(file_name, str):
                continue
            normalized = file_name.replace("\\", "/")
            for prefix in prefixes:
                normalized = normalized.replace(prefix.replace("\\", "/"), "")
            if not normalized.startswith("apps/backend/"):
                normalized = f"apps/backend/{normalized.lstrip('/')}"
            file_payload["name"] = normalized
    report_path.write_text(json.dumps(payload, ensure_ascii=True), encoding="utf-8")


def report_summary(report_path: Path) -> tuple[str | None, int, int, int, float, float]:
    payload = json.loads(report_path.read_text(encoding="utf-8"))
    statistics = payload["statistics"]
    total = statistics["total"]
    return (
        statistics.get("detectionDate"),
        int(total["clones"]),
        int(total["duplicatedLines"]),
        int(total["duplicatedTokens"]),
        float(total["percentage"]),
        float(total["percentageTokens"]),
    )


def copy_artifacts(
    temporary_output: Path,
    output_dir: Path,
    prefix: str,
    write_current: bool,
    scope: str,
    roots: tuple[Path, ...],
    files: tuple[Path, ...],
    explicit_paths: list[str],
) -> Manifest:
    source_json = temporary_output / "jscpd-report.json"
    source_html = temporary_output / "jscpd-report.html"
    if not source_json.exists() or not source_html.exists():
        raise RuntimeError("jscpd did not create its expected JSON and HTML reports.")

    run_token = datetime.now(timezone.utc).strftime("%Y-%m-%d-%H-%M-%S-%f")
    output_dir.mkdir(parents=True, exist_ok=True)
    json_report = output_dir / f"{run_token}.json"
    html_report = output_dir / f"{run_token}.html"
    manifest_path = output_dir / f"{run_token}.manifest.json"
    shutil.copy2(source_json, json_report)
    shutil.copy2(source_html, html_report)

    detection_date, clones, lines, tokens, percentage, token_percentage = report_summary(json_report)
    current_json = output_dir / f"{prefix}-report.json" if write_current else None
    current_html = output_dir / f"{prefix}-report.html" if write_current else None
    current_manifest = output_dir / f"{prefix}-manifest.json" if write_current else None
    if current_json is not None and current_html is not None:
        shutil.copy2(json_report, current_json)
        shutil.copy2(html_report, current_html)

    manifest = Manifest(
        profile="csharp",
        run_token=run_token,
        selection_label=scope if not explicit_paths else ",".join(explicit_paths),
        scope=scope,
        explicit_paths=tuple(explicit_paths),
        roots=tuple(display_path(root) for root in roots),
        scanned_files=len(files),
        output_dir=display_path(output_dir),
        json_report=display_path(json_report),
        html_report=display_path(html_report),
        manifest_path=display_path(manifest_path),
        current_json_report=display_path(current_json) if current_json else None,
        current_html_report=display_path(current_html) if current_html else None,
        current_manifest_path=display_path(current_manifest) if current_manifest else None,
        detection_date=detection_date,
        clone_count=clones,
        duplicated_lines=lines,
        duplicated_tokens=tokens,
        duplicate_percentage=percentage,
        duplicate_token_percentage=token_percentage,
    )
    manifest_payload = json.dumps(asdict(manifest), indent=2, ensure_ascii=True) + "\n"
    manifest_path.write_text(manifest_payload, encoding="utf-8")
    if current_manifest is not None:
        current_manifest.write_text(manifest_payload, encoding="utf-8")
    return manifest


def main() -> int:
    args = build_parser().parse_args()
    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    prepared_root: Path | None = None
    temporary_output: Path | None = None
    try:
        roots = resolve_roots(args.scope, args.path)
        files = list_production_files(roots)
        output_dir = args.output_dir
        if not output_dir.is_absolute():
            output_dir = (REPO_ROOT / output_dir).resolve()
        prefix = args.latest_prefix.strip()
        if not prefix:
            raise ValueError("latest-prefix must not be empty.")

        prepared_root = prepare_scan(files)
        temporary_output = Path(tempfile.mkdtemp(prefix="foundry-jscpd-output-")).resolve()
        run_jscpd(prepared_root, temporary_output)
        rewrite_report_paths(temporary_output / "jscpd-report.json", prepared_root)
        manifest = copy_artifacts(
            temporary_output,
            output_dir,
            prefix,
            args.write_current,
            args.scope,
            roots,
            files,
            args.path,
        )
        if args.stdout_format == "json":
            print(json.dumps(asdict(manifest), ensure_ascii=True))
        else:
            print(f"Scanned {manifest.scanned_files} production C# files.")
            print(f"Clones: {manifest.clone_count}; duplicated lines: {manifest.duplicated_lines}.")
            print(f"Report: {manifest.json_report}")
        return 0
    except (FileNotFoundError, RuntimeError, ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        LOGGER.exception("Foundry C# jscpd wrapper failed: %s", error)
        print(f"error: {error}", file=sys.stderr)
        return 1
    finally:
        if prepared_root is not None:
            shutil.rmtree(prepared_root, ignore_errors=True)
        if temporary_output is not None:
            shutil.rmtree(temporary_output, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
