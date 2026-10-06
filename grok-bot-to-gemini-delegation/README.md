---
title: Grok Bot Gemini Delegation
type: readme
description: Installation and operation of the Grok Bot private skill and local Gemini bridge.
status: active
date created: 2026-09-06
date modified: 2026-09-06
tags: [grok-bot, gemini, delegation]
component: [agents]
---

# Grok Bot Gemini delegation

This package connects a Grok Bot private skill to Google Gemini through Antigravity on the local Windows computer. Grok Bot coordinates and accepts the work; Gemini edits the selected repository.

## Install

1. Keep this package in the local skill directory on the Windows computer.
2. Attach [SKILL.md](SKILL.md) in a one-to-one Grok Bot conversation and ask it to save the instructions as a private skill named `grok-bot-to-gemini-delegation`. Use the frontmatter description for its usage description and the body for instructions.
3. Enable the saved skill for the intended Bot under Settings → Plugins → Yours. Reference it through `/` in the composer. See [Grok Bot's skill documentation](https://docs.x.ai/grok-bot/skills-routines-and-automations).
4. Enable local-computer execution in the desktop app and verify the Bot can run PowerShell on this Windows machine. Its local shell needs `pwsh`, Git, and authenticated `agy` on PATH. The repository and contract paths resolve on that machine.

For authentication, start an interactive `agy` session on Windows, then run `agy models`. Google's [installation guide](https://antigravity.google/docs/cli/install/) describes authentication setup.

## Use

```text
/grok-bot-to-gemini-delegation in <REPOSITORY_PATH>, have Gemini implement the approved change and validate it using the repository instructions
```

See [usage-example.md](usage-example.md) for direct bridge invocation and model selection.

| Wrapper model | Antigravity model |
| --- | --- |
| `gemini-3.7-flash` (default) | `gemini-3.7-flash-medium` |
| `gemini-3.7-flash-high` | `gemini-3.7-flash-high` |
| `gemini-3.1-pro` | `gemini-3.1-pro-high` |

Explicit Gemini slugs from `agy models`, including `gemini-3.8-flash-medium`, are also accepted. The default remains `gemini-3.7-flash`.

Pass `-UseSubagents` for user-requested Gemini subagents. This supplies worker instructions to delegate through native Antigravity tools on the selected model, wait for completion, and integrate results. See Google's [subagent documentation](https://antigravity.google/docs/cli/subagents/).

The provider wait limit is configurable with `-TimeoutSeconds`; its default is 600 seconds. Use `-TimeoutSeconds 1800` for a 30-minute wait limit.

## Runtime behavior

The self-contained bridge [Invoke-GeminiAgent.ps1](Invoke-GeminiAgent.ps1) resolves the Git repository root and edits that checkout directly. It checks model availability, starts a fresh conversation, and enables noninteractive tool approvals. The contract defines authorized scope; Grok Bot handles review and corrections.

Each invocation prints a unique `%TEMP%\grok-gemini-<id>` directory. `live.txt` records progress and diagnostics; `events.jsonl` records tool events. A completed provider response also produces `result.json` and `response.txt`. Grok Bot reads these through its local shell and retains the running shell session until completion.

Exit code zero requires provider status `SUCCESS` and a nonempty response. The Bot then verifies the actual deliverable. On failure, inspect logs and affected files before retrying, since edits can precede an error. Preserve run evidence until review and remove temporary contracts after acceptance.

Antigravity's [headless documentation](https://antigravity.google/docs/cli/headless/) describes the event and result formats. Local bridge execution and saved Bot skill activation are separate steps; the desktop Bot requires the installed skill and local-computer access to complete the whole workflow.

## Exercised behavior

On 2026-09-06, this local bridge ran a real `gemini-3.7-flash-high` correction contract from a nested directory in a temporary repository. Gemini added a discount parameter to a totals function. Independent execution returned `8` with a 20% discount, `10` with the default discount, and `0` for an empty array. The unrelated user file retained its original contents. Live events and the terminal `SUCCESS` result were captured.

Read-only execution with `gemini-3.8-flash-medium` followed a repository-specific `AGENTS.md` instruction and processed accented and Japanese item names from a directory containing spaces. A native subagent run recorded the child conversation ID, inherited model selection, completed calculation, and parent integration, with dispatch events visible in the live log. Empty contracts, an unavailable model, and a one-second provider timeout returned exit code 1.

Desktop private-skill import, per-Bot activation, and the Bot's own local-execution transport remain unverified. Follow the installation steps, then exercise the saved skill on a small local task before relying on that complete route.
