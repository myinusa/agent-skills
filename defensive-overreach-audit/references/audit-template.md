---
title: "Defensive Overreach Audit Report Template"
type: "reference"
description: "Required structure and evidence fields for defensive-overreach audit reports."
status: "active"
date created: "2026-08-12"
date modified: "2026-08-12"
tags: [skills, audit, defensive-overreach, template]
component: [agents, docs]
related:
  - .codex/skills/defensive-overreach-audit/SKILL.md
---

# defensive-overreach-audit report template

Use this template for the saved audit artifact. Adapt the wording to the real scope, but keep the section order and the evidence shape. The goal is a coverage-backed audit, not a short opinion note.

````markdown
---
title: "Defensive Overreach Audit — YYYY-MM-DD"
type: "audit"
description: "Evidence-backed audit of defensive coding or process overhead in the specified Foundry scope."
status: "active"
date created: "YYYY-MM-DD"
date modified: "YYYY-MM-DD"
tags: [audit, defensive-overreach]
component: [agents]
audience: "developer"
scope: "<file, folder, or repo scope>"
skill: "defensive-overreach-audit"
---

# Defensive Overreach Audit

## Scope
- Target: <file, folder, or repo scope>
- Depth: <surface | deep | comprehensive>
- Lens: <code | process | both>

## Audit Summary
- Confirmed overreach: <count>
- Justified safeguards: <count>
- Needs review: <count>
- Highest-signal simplification candidate: <file:line>
- Overall verdict: <1-3 sentences>

## Coverage
- Files in scope: <count or estimate>
- Files inspected directly: <count>
- Key directories or modules inspected:
  - <path>
  - <path>
- Candidate patterns searched for:
  - <pattern family>
  - <pattern family>
- Coverage note: <representative / partial / exhaustive within bounded scope>

## Confirmed Overreach

### <short title>
- File: <path:line>
- Boundary involved: <upstream/downstream boundary or `none`>
- Defended failure mode: <what this code appears to be guarding against>
- Why this is redundant now: <1-3 sentences>
- Complexity cost: <branching, indirection, duplicate normalization, stale compatibility, etc.>
- Evidence:
```text
<quoted code snippet>
```
- Suggested simplification:
```text
<small before/after sketch or target shape>
```
- Risk if removed incorrectly: <brief note>

## Justified Safeguards

### <short title>
- File: <path:line>
- Live failure mode: <what can still go wrong>
- Why this safeguard still earns its keep: <1-3 sentences>
- Evidence:
```text
<quoted code snippet when non-obvious>
```

## Needs Review

### <short title>
- File: <path:line>
- Why this is ambiguous: <1-3 sentences>
- Evidence:
```text
<quoted code snippet>
```
- What would resolve it: <missing runtime fact, product rule, external contract, or consumer check>

## Systemic Patterns
- <repeatable pattern across the scope>
- <repeatable pattern across the scope>

## Simplification Priorities

| Priority | File | Pattern | Why it matters | Suggested shape |
| --- | --- | --- | --- | --- |
| High | `<path:line>` | <pattern> | <reason> | <target shape> |
| Medium | `<path:line>` | <pattern> | <reason> | <target shape> |

## Risks of Simplification
- <what could break if the wrong guard is removed>
- <what boundary must still remain protected>

## Follow-up Actions
- Priority: <High | Medium | Low>
  Action: <bounded follow-up action>
  Likely location: <path or subsystem>
  Acceptance criterion: <what must remain true after cleanup>
````
