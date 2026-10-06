---
name: crack-tech-debt-audit
description: Use ONLY when the user explicitly invokes crack-tech-debt-audit by name and wants an opinionated, evidence-calibrated technical-debt and architecture audit. Supports audit modes, severity calibration, evidence typing, and direct file-specific findings. In Foundry, default output is a dated file under docs/audits unless the user provides another output path. Do not use for ordinary code review, implementation, lint cleanup, or broad quality comments unless the user explicitly names this skill.
---

# Crack Tech Debt Audit

A runtime-neutral agent skill that conducts a deliberate, hard-edged audit of a codebase and produces an evidence-calibrated technical debt report.

Use this higher-control technical-debt audit when the user wants stronger structure, sharper prioritization, and direct findings.

When explicitly invoked by name, follow this protocol.

---

## Operating principles

Find what's actually wrong. Not diplomatic. Not surface-only. Don't pattern-match to generic best practices without grounding in this specific repo. No sycophancy. No "overall the codebase is well-structured" filler.

Cite `file:line` for every concrete finding. Vague claims like "the code generally..." don't count. Read code before judging it. A pattern that looks wrong in isolation may be load-bearing, but do not hide behind that possibility when the structure is plainly causing friction.

Name the exact files, folders, duplicated patterns, stale artefacts, and consequences. If a directory layout, naming scheme, abstraction, or ownership boundary is making change harder than it should be, say so directly. Do not soften a finding because the right fix may involve moving files, renaming things, deleting dead material, or challenging the current structure.

Avoid busywork, box-ticking, fake thoroughness, and process-heavy behaviour. Keep the audit free of remediation ceremonies, broad validation passes, and bloated follow-up plans. Do not turn findings into requests for tests, fixtures, smoke checks, fallback behaviour, backwards-compatibility layers, monitoring, migrations, documentation tasks, or extra abstractions unless the actual problem clearly requires them.

Do not edit product code. This is an audit skill, not a remediation skill. The durable output is the audit report.

## Audit modes

Choose one mode before Phase 1 and write it in the report. If the user did not specify a mode, infer the narrowest mode that satisfies the request.

- `full-repo`: complete repository audit.
- `scoped-module`: audit one app, package, service, directory, or bounded subsystem.
- `delta-since-commit`: audit debt introduced or exposed since a commit, tag, branch, or date.
- `repeat-run`: update an existing artifact for this skill/mode/scope after verifying old findings.
- `triage-top-10`: produce up to the ten highest-impact findings and skip lower-value inventory.

If the mode is ambiguous, state the assumption instead of stopping unless the ambiguity would make the audit misleading.

### Delta mode execution contract

When mode is `delta-since-commit`, do all of the following before reporting findings:

1. Resolve and record a base reference (`commit`, `tag`, `branch`, or `date`).
2. Build and record a changed-file inventory from the base reference.
3. Review changed-line context first, then nearby boundary files only when needed.
4. Treat pre-existing debt as context unless the delta clearly introduces or exposes it.
5. Include `base_ref`, `head_ref`, and a short `delta_scope` summary in report metadata.

## Phase 1: Orient

Orient enough to avoid bad claims. Keep the orientation pass proportional to the scope.

1. Read the README, agent instructions, package manifest (`package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` / solution files), and any architecture docs that are directly relevant to the chosen scope.
2. Map the major modules or layers in scope and identify obvious exclusions such as generated folders, vendored code, lockfiles, snapshots, and migrations unless they are part of the problem.
3. Run the deterministic orientation helper if it will sharpen the audit: `rtk python .codex/skills/crack-tech-debt-audit/scripts/orient_audit.py [scope]`. Use its output to seed judgment, not replace it.
4. Check history when churn, ownership drift, or repeated edits look material. Foundry examples: `rtk git --no-pager log --oneline -200` and `rtk git --no-pager log --stat --since="6 months ago"`.
5. Write a short mental model of how the scoped system actually works before finalizing findings. If your model contradicts the README, flag it.

If the repository is large, unstable, or unfamiliar, you may gather top-size and top-churn inventories when they help locate the debt.

## Phase 2: Audit across these dimensions

Use `rg`, `ast-grep`, language-native tooling, history, and code reading to find concrete examples. Cite `path/to/file.ext:LINE` for every finding. Use the dimensions below where they surface real issues.

1. **Architectural decay** - circular deps, layering violations, god files (>500 LOC) and god functions, duplicated logic across 3+ sites where an abstraction should exist, abstractions that exist but nobody uses, dead code.
2. **Consistency rot** - multiple ways of doing the same thing: HTTP clients, error handling, logging, config loading, validation, date handling, serialization, routing, dependency injection, or state management.
3. **Type and contract debt** - `any` / `unknown` / `as any` / `# type: ignore` / loose dicts, untyped API boundaries, missing schema validation at trust boundaries, DTO/domain drift.
4. **Test debt and verification blind spots** - critical paths with no meaningful coverage, skipped or flaky tests, or high-churn files where regressions are currently invisible. Do not recommend new tests by reflex.
5. **Dependency and config debt** - vulnerable packages, unused deps, duplicate deps doing the same job, env var sprawl, undocumented config, inconsistent defaults.
6. **Performance and resource hygiene** - N+1 queries, sync work in async paths, blocking I/O on hot paths, uncleaned listeners or handles, unnecessary serialization, unbounded concurrency.
7. **Error handling and observability** - swallowed exceptions, blanket catches, errors logged but not handled, inconsistent error shapes, missing structured logs on critical paths.
8. **Security hygiene** - hardcoded secrets, string-concat SQL, missing input validation at trust boundaries, permissive auth or CORS, weak crypto, unsafe deserialization.
9. **Documentation drift** - README claims that don't match reality, comments that contradict adjacent code, public APIs without docs, stale runbooks.
10. **Agent and maintainer legibility** - missing route maps, stale agent instructions, prompt/skill sprawl, hidden runtime config drift, unclear command entry points, non-reproducible setup, documented constraints that are not mechanically enforced.

## Evidence standard

Every finding must include an evidence type. Use the strongest applicable type:

- `code`: direct source inspection.
- `test`: test failure, missing coverage, skipped test, flaky test, or weak assertion.
- `tool`: static analysis, typecheck, audit, dependency, or coverage result.
- `history`: churn, repeated fixes, ownership drift, or high top-size/top-churn overlap.
- `docs`: mismatch between documentation and implementation.
- `runtime`: logs, metrics, traces, browser evidence, local execution, or observed behavior.

Do not promote a finding above Medium severity unless evidence shows user impact, operational risk, security exposure, high change frequency, or broad blast radius.

Do not manufacture weak `tool` evidence by running broad validation passes that do not sharpen a concrete claim.

## Severity rubric

- `Critical`: likely data loss, security exposure, production outage, broken auth/entitlement, irreversible migration risk, or a systemic architectural fault blocking safe change.
- `High`: high-probability defect in an important path, severe maintainability bottleneck in high-churn code, missing validation at a trust boundary, or recurring operational failure mode.
- `Medium`: real debt with concrete cost, limited blast radius, moderate risk, or repeated local inconsistency that slows work but is not urgent.
- `Low`: cleanup, clarity, minor duplication, stale comments, or isolated maintainability issue with low risk.

Effort is `S` for one focused change, `M` for a small coordinated refactor, and `L` for multi-module work needing careful execution.

## Exclusion policy

Do not audit generated files, vendored code, lockfiles, compiled assets, snapshots, bulk migrations, minified bundles, or third-party examples unless the user explicitly includes them or they are the source of a concrete risk.

## Phase 3: Deliverable

Write to a dedicated audit artifact, unless the user names another path, with this structure:

- Foundry default path: `docs/audits/YYYY-MM/YYYY-MM-DD-<scope>-crack-tech-debt-audit.md`
- Include repository-compliant YAML front matter.

- **Audit metadata** - generated date, scope, mode, commit, major assumptions, exclusions, unavailable tools.
- **Executive summary** - ranked findings only.
- **Architectural mental model** - your understanding of the system as it actually is.
- **Findings table** - columns: `ID | Category | File:Line | Evidence | Severity | Effort | Consequence | Recommendation`. Each row should name the concrete pattern and what it costs.
- **Structural friction and stale artefacts** - call out folders, names, dead files, or ownership seams that are actively getting in the way when they materially affect the scope.
- **Most important fixes** - the few changes that would remove the most drag or risk. Use concrete refactor outlines or diff sketches, not vague advice.
- **Tooling evidence actually used** - commands run, important results, tools unavailable, and irrelevant tools skipped.
- **Things that look bad but are actually fine** - calls you considered flagging and chose not to, with reasoning. This section is required.
- **Open questions for the maintainer** - things you couldn't tell were debt vs. intentional.

Do not pad the report with remediation plans, checklists, smoke-test sections, documentation follow-up, or generic next steps unless the user explicitly asked for them.

## Rules

- Cite `file:line` for every concrete finding.
- Include an evidence type for every finding.
- If unsure whether something is debt or intentional, ask in open questions. Do not bluff.
- Do not compress findings into generic observations. Name the specific files, folders, repeated patterns, and consequences.
- Do not bundle unrelated issues into one umbrella finding just to make the report shorter.
- Don't recommend rewrites. Recommend specific, scoped changes.
- Don't recommend tests, fixtures, smoke checks, monitoring, fallback paths, backwards-compatibility layers, migrations, extra abstractions, or defensive hardening unless the actual problem clearly requires them.
- Don't pad. If a category has nothing material, omit it or write `Nothing material`.
- No sycophancy. Tell the user what's broken.
- Do not edit product code or docs other than the audit output unless the user explicitly asks.

## Stack-specific tooling

Detect the stack from the manifest and run relevant local or package-scoped tools only when they expose or confirm a real issue. Prefer project scripts over ad hoc commands. Run tools in parallel when possible.

- **TypeScript / JavaScript** - package-manager audit command, dependency-unused checks, circular dependency checks, typecheck, lint, or relevant tests.
- **Python** - `pip-audit`, `ruff check`, `vulture`, `pydeps --show-cycles`, `mypy`, or relevant tests.
- **Rust** - `cargo audit`, `cargo udeps`, `cargo machete`, `cargo clippy`, or relevant tests.
- **Go** - `govulncheck`, `go vet`, `staticcheck`, `golangci-lint run`, or relevant tests.
- **.NET** - `dotnet list package --vulnerable`, solution/project build, analyzers, available architecture checks, or targeted tests.
- **Infrastructure / SQL / shell** - repo linters, schema validation, shellcheck, policy checks present in the project, or migration checks when the migration itself is under scrutiny.

If a tool isn't installed, note it in the audit and move on. Do not install dev tools globally without permission.

## Large repos: use multiple agents when available

If the repo is very large or the scope naturally splits into distinct modules, dispatch multiple read-only agents in parallel when the host runtime supports it and the split improves coverage.

Each delegated agent gets: scope, mode, dimensions list, evidence standard, severity rubric, citation requirement, and no-edit instruction. The main agent merges, dedupes, normalizes severity, rejects weak findings, and ranks.

## Repeat-run mode

If an existing artifact for this mode/scope exists, read it first. Mark resolved findings as `RESOLVED` only after checking evidence, update stale ones, and tag new findings with `NEW`. This turns the audit into a living document tracked over time.

---

# Project documentation

The remaining sections cover installation, usage, and maintenance notes for this skill.

## Usage

In your agent runtime, explicitly ask to use `crack-tech-debt-audit` in the repo you want audited. Example: `Use crack-tech-debt-audit on this repo in triage-top-10 mode.` Output goes to a dedicated crack audit artifact unless another path is requested.

See `usage-examples.md` for prompt examples.
Maintainer context is captured in `improvements.md`.

## Philosophy

The core quality levers are enough orientation to avoid bad calls, file-line citations, hard-edged language, no rewrite recommendations by default, no padding, and a required "looks bad but is actually fine" section.

Modes bound the scope, evidence types make weak findings visible, severity calibration reduces noise, and the orientation helper is available when size or churn data would actually sharpen the audit.

## Limitations

This is still a static audit, not a security audit, penetration test, performance benchmark, or business-logic verification pass.

It cannot reliably distinguish intentional simplicity from accidental simplicity without maintainer context. Use open questions when intent is unclear.

For very large repos (>200k LOC), even delegated passes can be shallow. Prefer `scoped-module` or `triage-top-10` mode.
