---
title: Agent skills
type: readme
description: Central catalogue of reusable agent skills.
status: active
date created: 2026-10-06
date modified: 2026-10-06
component: [agents]
---

# Agent skills

Each directory contains a self-contained skill package. `SKILL.md` defines the skill. Supporting `references/`, `scripts/`, and `agents/` directories provide package resources when they are present.

## Packages

- `backend-csharp-naming-review`
- `codex-to-codex-cli-delegation`
- `codex-to-gemini-delegation`
- `crack-tech-debt-audit`
- `defensive-overreach-audit`
- `fallow-dupes-batch-remediator`
- `gemini-image-to-code`
- `grok-bot-to-codex-delegation`
- `grok-bot-to-gemini-delegation`
- `grok-bot-to-opencode-delegation`
- `grok-build-to-codex-delegation`
- `grok-build-to-gemini-delegation`
- `grok-build-to-opencode-delegation`
- `impeccable-review-loop`
- `jscpd-batch-remediator`
- `opencode-image-to-code`
- `public-release-audit`

Delegation skills use the `<delegator>-to-<worker>-delegation` naming pattern.

Original source repositories retain their own copies. The central packages provide the reusable catalogue for later installation and publication work.
