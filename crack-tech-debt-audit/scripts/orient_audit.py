#!/usr/bin/env python3
"""Deterministic orientation helper for crack-tech-debt-audit.

Run from a repository root:
    rtk python .codex/skills/crack-tech-debt-audit/scripts/orient_audit.py [scope]

Requires Python 3.8+.
"""

from __future__ import annotations

import argparse
import os
import subprocess
from collections import Counter
from pathlib import Path

EXCLUDED_DIRS = {
    ".git",
    ".hg",
    ".svn",
    "node_modules",
    "vendor",
    "dist",
    "build",
    "coverage",
    ".next",
    ".nuxt",
    ".turbo",
    ".cache",
    "bin",
    "obj",
    "target",
    "__pycache__",
}

EXCLUDED_SUFFIXES = {
    ".lock",
    ".min.js",
    ".map",
    ".snap",
    ".png",
    ".jpg",
    ".jpeg",
    ".gif",
    ".webp",
    ".ico",
    ".pdf",
    ".zip",
    ".gz",
    ".tar",
    ".br",
    ".woff",
    ".woff2",
    ".ttf",
}

EXCLUDED_NAMES = {
    "package-lock.json",
    "pnpm-lock.yaml",
    "yarn.lock",
    "Cargo.lock",
    "poetry.lock",
    "Pipfile.lock",
    "Gemfile.lock",
    "composer.lock",
}

MANIFEST_NAMES = {
    "package.json",
    "pnpm-workspace.yaml",
    "pyproject.toml",
    "Cargo.toml",
    "go.mod",
    "composer.json",
    "Gemfile",
    "requirements.txt",
    "Pipfile",
    "setup.py",
    "setup.cfg",
    "tox.ini",
    "Makefile",
    "Justfile",
    "Directory.Build.props",
    "global.json",
}

MANIFEST_SUFFIXES = {
    ".csproj",
    ".fsproj",
    ".vbproj",
    ".sln",
    ".slnx",
}

GENERATED_HINTS = ("generated", "autogen", ".g.cs", ".designer.cs")


def run_git(args: list[str], cwd: Path) -> tuple[str, str | None]:
    try:
        completed = subprocess.run(
            ["git", *args],
            cwd=cwd,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except FileNotFoundError:
        return "", "git command not available in PATH"
    if completed.returncode != 0:
        stderr = (completed.stderr or "").strip()
        return "", stderr or f"git command failed with exit code {completed.returncode}"
    return completed.stdout, None


def to_repo_relative(path: Path, repo: Path) -> Path:
    try:
        return path.relative_to(repo)
    except ValueError:
        return path


def is_excluded(path: Path) -> bool:
    parts = set(path.parts)
    if parts.intersection(EXCLUDED_DIRS):
        return True
    if path.name in EXCLUDED_NAMES:
        return True
    text = path.as_posix().lower()
    return any(text.endswith(suffix) for suffix in EXCLUDED_SUFFIXES)


def line_count(path: Path) -> int:
    try:
        with path.open("rb") as handle:
            return sum(1 for _ in handle)
    except OSError:
        return 0


def iter_files(scope: Path) -> list[Path]:
    if scope.is_file():
        return [scope]
    files: list[Path] = []
    for root, dirs, names in os.walk(scope):
        dirs[:] = [name for name in dirs if name not in EXCLUDED_DIRS]
        root_path = Path(root)
        for name in names:
            path = root_path / name
            if not is_excluded(path):
                files.append(path)
    return files


def print_table(title: str, rows: list[tuple[str, str]], limit: int = 20) -> None:
    print(f"\n## {title}")
    if not rows:
        print("None found.")
        return
    for left, right in rows[:limit]:
        print(f"{left}\t{right}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Collect deterministic tech-debt audit orientation signals.")
    parser.add_argument("scope", nargs="?", default=".", help="File or directory scope to inspect")
    parser.add_argument("--since", default="6 months ago", help="Git history window for churn")
    parser.add_argument("--limit", type=int, default=20, help="Rows to show per section")
    args = parser.parse_args()

    repo = Path.cwd()
    scope = (repo / args.scope).resolve()
    if not scope.exists():
        raise SystemExit(f"Scope does not exist: {scope}")

    files = iter_files(scope)
    relative_files = [to_repo_relative(path, repo) for path in files]

    print(f"# Crack Tech Debt Audit Orientation")
    print(f"Scope: {args.scope}")
    print(f"Files considered: {len(files)}")

    largest = sorted(((line_count(path), path) for path in files), reverse=True)
    print_table(
        "Largest Files",
        [(str(count), to_repo_relative(path, repo).as_posix()) for count, path in largest],
        args.limit,
    )

    git_scope = args.scope if args.scope != "." else "."
    churn_output, git_error = run_git(["log", f"--since={args.since}", "--format=", "--name-only", "--", git_scope], repo)
    churn = Counter(line.strip() for line in churn_output.splitlines() if line.strip())
    if git_error:
        print(f"WARNING: git history unavailable: {git_error}")
    print_table("Most Changed Files", [(str(count), path) for path, count in churn.most_common(args.limit)], args.limit)

    largest_paths = {to_repo_relative(path, repo).as_posix() for _, path in largest[: args.limit]}
    top_churn_paths = {path for path, _ in churn.most_common(args.limit)}
    overlap = [(churn[path], path) for path in largest_paths.intersection(top_churn_paths)]
    overlap.sort(key=lambda row: row[0], reverse=True)
    print_table("Largest And Most Changed Overlap", [(str(count), path) for count, path in overlap], args.limit)

    manifests = sorted(path for path in relative_files if path.name in MANIFEST_NAMES or path.suffix in MANIFEST_SUFFIXES)
    print_table("Manifests And Solution Files", [("manifest", path.as_posix()) for path in manifests], args.limit)

    generated_candidates = sorted(
        path for path in relative_files if any(hint in path.as_posix().lower() for hint in GENERATED_HINTS)
    )
    print_table("Generated Candidates To Exclude Unless In Scope", [("generated?", path.as_posix()) for path in generated_candidates], args.limit)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
