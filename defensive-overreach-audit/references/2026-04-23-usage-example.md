---
title: "Usage Example: defensive-overreach-audit"
type: "guide"
description: "Concrete prompt examples for invoking the defensive-overreach-audit skill."
status: "active"
date created: "2026-04-23 16:54"
date modified: "2026-08-12"
tags: [skills, audit, defensive-overreach, examples]
component: [agents, docs]
related:
  - .codex/skills/defensive-overreach-audit/SKILL.md
  - .codex/skills/defensive-overreach-audit/references/audit-template.md
---

# Usage Example: defensive-overreach-audit

Use this skill when you want a saved audit artifact that distinguishes redundant local caution from safeguards that still matter at real boundaries.

## Example 1: Audit one feature folder

```text
Use defensive-overreach-audit.
Target: apps/backend/Application/Careers
Include quoted code snippets for each confirmed overreach and show the target simplification shape where safe.
```

## Example 2: Audit one file deeply

```text
Use defensive-overreach-audit.
Target: apps/web/src/features/finances/services/financesWorkflow.ts
Depth: deep
Include a coverage section even if the file is small.
```

## Example 3: Audit code and adjacent process together

```text
Use defensive-overreach-audit.
Target: scripts/tooling
Lens: process
Depth: deep
Show where the process overhead is duplicated, stale, or guarding a no-longer-live failure mode.
```

## Example 4: Mixed scope with explicit output path

```text
Use defensive-overreach-audit.
Target: apps/backend/Application/Finance
Lens: both
Output: docs/audits/2026-04/2026-04-23-subscriptions-defensive-overreach-audit.md
Include quoted code snippets for every confirmed overreach and every non-obvious justified safeguard.
```

## Example 5: Repo-wide comprehensive pass

```text
Use defensive-overreach-audit.
Target: repo
Depth: comprehensive
Focus on duplicated invariants, unreachable fallback paths, stale compatibility logic, and process overhead that no longer protects a live failure mode.
Include quoted code snippets for every confirmed overreach and a short simplification snippet where safe.
Show coverage counts so the report makes clear how much of the surface was actually inspected.
```

## Expected Behaviour

- The skill only activates when `defensive-overreach-audit` is explicitly named.
- It reads the bounded scope before judging anything.
- It uses multiple agents by default when the scope is larger than a single small file.
- It includes a coverage section so the report is not pretending a tiny sample was comprehensive.
- It separates `confirmed overreach`, `justified safeguard`, and `needs review`.
- It writes exactly one markdown audit artifact using the section order defined in `references/audit-template.md`.
- Major confirmed findings include quoted code snippets and a small simplification sketch.
- It does not implement simplifications or refactors.
