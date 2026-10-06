---
title: "Fallow Dupes Batch Remediator"
type: "reference"
description: "Skill package notes for Foundry duplicate-family batch selection with Fallow."
status: "active"
date created: "2026-07-20"
date modified: "2026-07-20"
tags: [codex, skills, fallow, duplicates, tooling]
component: [agents, scripts, tooling]
related:
  - .codex/skills/fallow-dupes-batch-remediator/SKILL.md
  - .codex/skills/fallow-dupes-batch-remediator/references/usage-example.md
  - scripts/tooling/fallow-app-dupes/README.md
---

# fallow-dupes-batch-remediator

This skill packages a deterministic Fallow duplication cleanup loop for Foundry source scopes.

Use it to regenerate the current dupes report through `scripts/tooling/fallow-app-dupes/cli.py`, work from a family-based JSONL worklist, and consolidate repeated logic when selected families exist.

Final responses list fixed and skipped family IDs. Structural extraction is expected work for this skill.
