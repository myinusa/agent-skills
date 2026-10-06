---
title: "Usage Example: JSCPD Batch Remediator"
type: "guide"
description: "Concrete examples for invoking the JSCPD Batch Remediator Codex skill."
status: "draft"
date created: "2026-06-08 00:00"
date modified: "2026-06-14"
tags: [codex, skills, example, jscpd, duplicates, python, csharp]
component: [all]
related:
  - .codex/skills/jscpd-batch-remediator/SKILL.md
---

# Usage Example: JSCPD Batch Remediator

Skill invocations are just prompts. Keep the batch size explicit.
The helper regenerates the current report, HTML file, manifest, and worklist for the requested profile before the agent edits code.

One-liner:

"Use `jscpd-batch-remediator` with `profile: python` to fix the next 8 duplicate clusters for `repo`."

Tiny key/value block:

```text
Use jscpd-batch-remediator.
batch_size: 8
profile: python
target: repo
constraints: no suppression, no config churn, verify with jscpd after edits
```

Expected response shape:

```text
Fixed:
- cluster:<id>

Skipped:
- cluster:<id> — <reason>
```

## Example A: Minimal invocation

Prompt:

Use `jscpd-batch-remediator` with `profile: python` to fix 6 duplicate clusters for `repo`.

## Example B: Explicit path mode

Prompt:

Use `jscpd-batch-remediator`.
batch_size: 5
profile: python
paths:
- scripts/ci/workflow
- scripts/tooling

## Example C: Tight verification

Prompt:

Use `jscpd-batch-remediator`.
batch_size: 4
profile: python
target: repo

Re-run jscpd on the touched files after the refactor and show which cluster IDs disappeared.

## Example D: Backend C#

Prompt:

Use `jscpd-batch-remediator`.
batch_size: 6
profile: csharp
target: backend
