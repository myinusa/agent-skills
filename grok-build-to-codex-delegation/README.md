---
title: Codex Delegation
type: guide
description: Project-local Grok Build skill for delegating repository work to Codex while Grok coordinates and accepts the result.
status: active
date created: 2026-08-25
date modified: 2026-08-27
tags: [grok-build, codex, delegation, agents]
component: [agents]
related:
  - .grok/skills/grok-build-to-codex-delegation/SKILL.md
  - .grok/skills/grok-build-to-codex-delegation/references/usage-example.md
---

# Codex Delegation

This project-local Grok Build skill delegates repository work to Codex while Grok coordinates the task, reviews the repository result, and manages correction passes.

## Use

Run the skill in Grok Build with a task:

```text
/grok-build-to-codex-delegation implement the customer export endpoint and validate the existing backend build
```

Grok can also select the skill automatically when a request explicitly asks it to delegate repository work to Codex.

See [usage examples](references/usage-example.md) for implementation, investigation, review, and documentation prompts.

## Worker defaults

- model: `gpt-5.6-luna`
- reasoning effort: `high`
- service tier: `fast`
- permissions: approvals and sandbox bypassed
- one Codex agent per pass

Ask Grok for Codex subagents when the task benefits from independent workstreams. Grok passes the `-UseSubagents` option for that delegation.

## Model selection

Ask Grok to use Sol for a delegation to run `gpt-5.6-sol`. Grok passes `-Model Sol` to the wrapper. Sol uses the same `high` reasoning effort and `fast` service tier. Luna remains the default.

## Requirements

- Grok Build running in this repository
- PowerShell 7
- Git
- an authenticated Codex CLI with access to the selected model

## Skill files

- [SKILL.md](SKILL.md) defines the orchestration and acceptance workflow.
- [Invoke-CodexAgent.ps1](scripts/Invoke-CodexAgent.ps1) invokes the selected Codex worker.
- [usage-example.md](references/usage-example.md) provides ready-to-use prompts.
