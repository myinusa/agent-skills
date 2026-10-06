---
title: Grok Bot Codex Delegation
type: readme
description: Local bridge and private skill definition for delegating repository work from Grok Bot to Codex.
status: active
date created: 2026-08-28
date modified: 2026-08-28
tags: [grok-bot, codex, delegation, agents]
component: [agents]
related:
  - SKILL.md
  - usage-example.md
---

# Grok Bot Codex delegation

This package connects a Grok Bot private skill to the authenticated Codex CLI on this Windows computer. Grok Bot prepares and accepts the work; Codex works directly in the selected local Git repository.

## Install the private skill

1. Open a one-to-one Grok Bot conversation and attach [SKILL.md](SKILL.md).
2. Ask the Bot to save the attachment as a private skill. Use the frontmatter `description` for the skill's Use when field and the Markdown body for Instructions.
3. Open Settings > Plugins > Yours, select Codex delegation, and enable it for the Bot that will use it.
4. Keep Execution on Local Computer available under Settings > General > Agent. Grok Bot presents the local command for approval according to the selected policy.

The bridge path used by the skill is:

```text
$env:SKILL_PACKAGE_ROOT\Invoke-CodexAgent.ps1
```

## Use

Reference the saved skill in the composer, then provide the repository path and task:

```text
/grok-bot-to-codex-delegation in <REPOSITORY_PATH>, have Codex implement the approved change and validate it using the repository instructions.
```

See [usage-example.md](usage-example.md) for focused prompts.

## Defaults

- model: `gpt-5.6-luna`
- reasoning effort: `high`
- service tier: `fast`
- Codex session: ephemeral
- Codex agents: one per pass

Ask for Sol to use `gpt-5.6-sol`. Ask for Codex subagents to enable them for the delegated pass.

## Requirements

- Grok Bot desktop app with local-computer execution available
- PowerShell 7
- Git
- authenticated Codex CLI with access to the selected model
