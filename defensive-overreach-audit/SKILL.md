---
name: defensive-overreach-audit
description: Use ONLY when the user explicitly asks for the defensive-overreach-audit skill by name and provides a target file, folder, or explicit repo scope to inspect for excessive defensive coding or process overhead. This skill reads the bounded scope, distinguishes justified safeguards from redundant caution, and writes exactly one markdown audit report under `docs/audits/YYYY-MM/`. Do not use for general code review, implementation, refactoring, or any request that does not explicitly name this skill.
---

ONLY ACTIVATE THIS SKILL WHEN THE USER EXPLICITLY NAMES `defensive-overreach-audit`. NEVER ACTIVATE IMPLICITLY.

You are auditing defensive overreach. Your job is to inspect a bounded code or process surface, identify where safeguards have crossed from useful boundary protection into redundant local caution, classify the risk of simplification, and save one evidence-backed markdown report. The report must be broad enough to reflect the inspected surface, not just a few obvious examples. You do not implement fixes.

## Explicit Invocation Required

This skill MUST NOT activate implicitly.

Only activate when the user explicitly says `defensive-overreach-audit` or directly asks to use the skill by that exact name. If the user asks for a general review, cleanup, refactor, or architecture audit without naming this skill, do not route here automatically.

## Routing Boundaries

Use this skill when:
- The user explicitly names `defensive-overreach-audit`.
- The user provides a bounded target: one or more files, a directory, or an explicit repo-wide scope.
- The user wants excessive defensive coding, excessive guard layering, unnecessary fallback logic, or process overhead analyzed rather than rewritten immediately.
- The user wants a saved markdown audit artifact, not just inline comments.

Do not use this skill when:
- The user wants a general code review, correctness review, lint cleanup, or bug investigation.
- The user wants actual code simplification or refactoring applied.
- The user wants a broad maintainability audit. Use the ordinary audit workflow.
- The user wants a second-pass critique of existing work. Use normal review flow unless another active skill is explicitly named.
- The user does not explicitly name this skill.

Negative examples (do not trigger):
- "Review this folder for code smells."
- "Clean up redundant guards in this service."
- "Audit the repo for maintainability risk."
- "Why is this feature slow?"
- "Look for defensive coding in here." without explicitly naming `defensive-overreach-audit`.

Edge cases:
- If the user names the skill but gives no target, ask once for a target path or explicit `repo` scope.
- If the target includes both code and process docs/scripts, audit both and keep the findings separated.
- If a safeguard sits at a real trust boundary, external integration boundary, destructive operation, auth boundary, money boundary, migration boundary, or concurrency boundary, trace both the upstream normalizer and the downstream consumer before deciding. Keep it only when the report can name the live failure mode and show that the guard still meaningfully reduces blast radius. Otherwise, treat duplicated, stale, or unreachable protection as `confirmed overreach`.
- If the same pattern might be either prudent or excessive depending on runtime facts you cannot confirm, classify it as `needs review` rather than a confirmed overreach.
- If the target path does not exist, ask once for correction unless enough valid scope remains to continue cleanly.

## Inputs

Required:
- An explicit request to use `defensive-overreach-audit`.
- A bounded target path or explicit `repo` scope.

Optional:
- Focus lens such as `code`, `process`, or `both` (default: `both` when mixed artifacts are present).
- Depth: `surface`, `deep`, or `comprehensive` (default: `deep`).
- Output path override.
- Prior audit path for comparison.

Hard constraint: avoid input sprawl. Use the supplied scope and infer nearby context only when needed to justify a finding.

## Hard Constraints

1. Never activate implicitly.
2. Report only. Do not edit source files, plans, or docs.
3. Save exactly one markdown audit artifact.
4. Ground all non-trivial findings in repository evidence with file paths and line numbers where practical.
5. Distinguish justified safeguards from overreach, but do not use ambiguity as an excuse to stay shallow. Trace enough surrounding context to make a real call.
6. Prefer bounded simplification opportunities over style commentary.
7. Use multiple agents by default when the scope is larger than a single small file.
8. Treat external boundaries as high-scrutiny zones:
   - user input parsing
   - auth and permission checks
   - external APIs and webhooks
   - persistence and migrations
   - concurrency and retry paths
   - destructive operations
   - money or billing logic
9. If evidence is incomplete, classify as `needs review` rather than `confirmed overreach`, but only after tracing the nearest upstream boundary and one downstream consumer where possible.
10. Do not be theatrical. No moralising about "bad code" and no generic advice.
11. Coverage must be explicit. The report must state what was inspected, what candidate patterns were found, and whether the audit is representative or partial.
12. Major confirmed findings must include quoted code snippets and a small simplification sketch.
13. `Deep` and `comprehensive` runs require a second pass that actively tries to disconfirm the initial overreach calls.
14. Concision is not the goal. Prefer useful breadth and concrete evidence over shortness.

## What Counts as Defensive Overreach

Flag a pattern when repository evidence shows it adds branching, indirection, or process cost without changing observable behavior or reducing a live failure mode.

Primary simplification candidates include:

- The same invariant is revalidated in several adjacent layers after an earlier trusted boundary already normalizes it.
- Fallback branches protect states that local code construction makes unreachable.
- Compatibility or dual-shape logic remains after the old shape is gone.
- Stale compatibility paths or pass-through adapters that preserve the same dependency while adding no shaping, validation, or policy.
- Repeated null, empty, or default handling obscures a narrower invariant already enforced upstream.
- Repeated validation or normalization across layers where the earlier layer already collapses the value into a narrower trusted shape.
- Process overhead exists only to guard low-risk local work and has no demonstrated failure mode behind it.
- Wrapper helpers, feature flags, retries, toggles, or adapters add branching without changing real operational behavior.

Do not flag these by default:

- Boundary parsing and normalization at ingress.
- Explicit failure handling around unstable external systems.
- Auth, billing, destructive action, migration, or concurrency safeguards.
- Checks needed to preserve public contract behavior.
- Guards whose removal would widen blast radius even if they look repetitive.

## Workflow

### Step 1: Orient on the target and boundary map

1. Confirm the exact target path(s) or repo scope.
2. Read the relevant `AGENTS.md` and nearby docs only as needed for the chosen scope.
3. Identify the trust boundaries in the target area:
   - external input
   - storage
   - network
   - auth
   - destructive operations
   - runtime orchestration
4. Decide whether the audit is primarily about:
   - code-level over-defensiveness
   - process or workflow overhead
   - both
5. Establish a coverage ledger before synthesis:
   - how many files are in scope
   - which subdirectories or subsystems were inspected directly
   - what candidate overreach patterns were searched for
   - whether the run is representative or intentionally partial

### Step 2: Split the audit across multiple agents

Unless the target is a single small file, use multiple agents in parallel.

Recommended split:
- Agent A: code-level redundant guards, fallback branches, and duplicated invariants
- Agent B: process overhead, scripts, docs, checklists, and workflow redundancy
- Agent C: justification check for boundary-critical safeguards that should probably stay

Each sub-agent must:
- read the scoped files before judging
- cite evidence
- separate confirmed overreach from justified protection
- flag uncertain cases as `needs review`
- return both findings and coverage notes so the final report can show breadth

### Step 3: Inspect the target directly

Before drafting:

1. Read the concrete files the audit depends on.
2. Trace the nearest upstream boundary and downstream consumers.
3. Sample beyond the first obvious hits. Do not stop after the first few easy findings if the target is materially larger.
4. Ask for each candidate pattern:
   - What failure mode is this defending against?
   - Is that failure mode still possible here?
   - Is the same invariant already enforced earlier?
   - What complexity cost does this add?
   - What would break if this were simplified?
5. Compare code, tests, scripts, and docs when the claim depends on process or operational behavior.
6. For `deep` and `comprehensive` runs, do a second pass over every major confirmed finding:
   - try to falsify the overreach call
   - inspect at least one downstream consumer or adjacent boundary
   - downgrade only if the evidence really shows the safeguard is still live

### Step 4: Classify findings

Classify each meaningful item as one of:

- `confirmed overreach`
  Use when the evidence shows the safeguard or process step is redundant, stale, unreachable, or duplicative relative to the current boundary design.
- `justified safeguard`
  Use when the pattern may look defensive but is still earning its keep at a real trust or failure boundary.
- `needs review`
  Use when the intent or runtime risk cannot be proven statically.

For every `confirmed overreach`, record:
- a short title
- the file and line reference
- the defended failure mode
- why it no longer appears live
- the boundary involved
- the complexity cost it adds
- a quoted code snippet
- a small simplification sketch or target shape
- the risk of removing it

For every `justified safeguard`, record:
- the live failure mode
- the boundary where it still earns its keep
- a quoted code snippet when the justification is non-obvious

For every `needs review`, record:
- what makes the case ambiguous
- what evidence would resolve it

### Step 5: Write the audit artifact

1. Load `references/audit-template.md`.
2. Save exactly one report to:
   - `docs/audits/YYYY-MM/YYYY-MM-DD-defensive-overreach-audit-<target-slug>.md`
   - use `repo` as the slug for repo-wide scope
   - if the user supplied an explicit output path, use that instead
3. Keep the report evidence-backed and structurally rich.
4. If a section has no findings, say `None identified.`

### Step 6: Final verification

Before finishing:

1. Re-read the saved file once.
2. Confirm the report names the explicit target and depth.
3. Confirm the report includes a coverage summary and that it matches the inspected scope.
4. Confirm the findings separate overreach from justified safeguards.
5. Confirm major findings include quoted snippets and a simplification sketch.
6. Confirm the report does not drift into implementation.

## Output Contract

A run is complete only when:

- exactly one markdown audit file has been saved
- the report states the target scope and audit depth
- the report includes an audit summary and a coverage section
- the report separates `confirmed overreach`, `justified safeguard`, and `needs review`
- major claims are grounded in repository evidence
- major confirmed findings include quoted code snippets and a concrete simplification direction without applying it
- `deep` and `comprehensive` runs reflect second-pass scrutiny rather than a first-pass skim

Final response must include:
- the saved audit path
- the highest-signal confirmed overreach items
- the most important justified safeguard that should not be simplified casually
