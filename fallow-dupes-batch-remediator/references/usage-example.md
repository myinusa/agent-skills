---
title: "Fallow Dupes Batch Remediator Usage Example"
type: "reference"
status: "active"
date created: "2026-07-20"
date modified: "2026-07-20"
tags: [codex, skills, example, fallow, duplicates, tooling]
related:
  - .codex/skills/fallow-dupes-batch-remediator/SKILL.md
  - scripts/tooling/fallow-app-dupes/cli.py
---

# Usage Example

The helper regenerates `output/fallow/app-dupes/<scope>/current-report.json` and `current-worklist.jsonl`, then selects the next duplicate families in a deterministic order.

Example prompt:

```text
Use fallow-dupes-batch-remediator to fix the next 6 duplicate families for typescript.
```

Equivalent explicit instruction:

```text
Use fallow-dupes-batch-remediator.
Scope: typescript
Batch size: 6
```
