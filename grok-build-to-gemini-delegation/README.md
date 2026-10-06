---
title: Grok Build Gemini Delegation
type: readme
description: Installation, model selection, and operation of the Grok Build Gemini delegation skill.
status: active
date created: 2026-09-06
date modified: 2026-09-06
tags: [grok-build, gemini, delegation]
component: [agents]
---

# Grok Build Gemini delegation

Grok delegates repository work to Google Gemini through the authenticated Antigravity CLI, reviews the result, and sends correction contracts until acceptance.

## Use

Start Grok Build in this repository and run:

```text
/grok-build-to-gemini-delegation implement the agreed change and validate the result using the repository instructions
```

The default is Gemini 3.7 Flash at medium reasoning. Request `gemini-3.7-flash-high`, `gemini-3.1-pro`, or an explicit Gemini slug from `agy models`. Availability is checked on each invocation. Google documents model selection in its [headless CLI guide](https://antigravity.google/docs/cli/headless/).

Pass `-UseSubagents` for user-requested Gemini subagents. The worker carries the task scope into native Antigravity assignments on the selected model, waits for completion, and integrates the results. See Google's [subagent documentation](https://antigravity.google/docs/cli/subagents/). This switch directs worker behavior through the contract; Antigravity supplies the tools.

Pass `-TimeoutSeconds 1800` when a task needs a 30-minute provider wait limit. The default is 600 seconds.

The complete skill lives in `.grok/skills/grok-build-to-gemini-delegation/`. Copy that directory into another repository's `.grok/skills/` to install it there. Run `grok inspect` from the destination repository to confirm discovery. Project skill discovery and slash commands are described in [Grok Build's skill documentation](https://docs.x.ai/build/features/skills-plugins-marketplaces).

## Requirements and execution

- PowerShell 7 (`pwsh`), Git, and Antigravity (`agy`) on the local PATH
- Cached Antigravity authentication with access to the selected Gemini model
- Grok shell execution authorized for the assigned repository work

Authenticate through an interactive `agy` session when needed, then inspect `agy models`. See Google's [installation and authentication guide](https://antigravity.google/docs/cli/install/).

The wrapper edits the selected checkout directly, including existing uncommitted files. It resolves a nested working directory to its repository root. Each pass uses a fresh Gemini conversation and enables noninteractive tool approvals. The task contract carries the authorized scope and repository constraints.

## Results and troubleshooting

Each invocation prints a separate `%TEMP%\grok-gemini-<id>` directory:

| File | Purpose |
| --- | --- |
| `live.txt` | Timestamped progress and diagnostics |
| `events.jsonl` | Provider events, including tool details |
| `result.json` | Terminal provider status and metadata, when returned |
| `response.txt` | Final worker response, when returned |

An exit code of zero requires a `SUCCESS` provider result and nonempty response. Grok still verifies the requested outcome. Authentication, model availability, malformed output, and failed provider results surface as failures. Inspect the files and current task state before retrying a failed pass: edits can precede an error.

The wrapper uses Antigravity's documented [headless event stream](https://antigravity.google/docs/cli/headless/) to expose progress. Preserve the active shell session while work runs; read `live.txt` from another shell if needed. Retain logs until review, then remove the specific run directory when its evidence is no longer needed.

See [SKILL.md](SKILL.md) for Grok's acceptance loop and [usage examples](references/usage-example.md) for contracts.

## Exercised behavior

On 2026-09-06, `grok inspect` discovered this installed skill. In a temporary repository, Grok invoked the wrapper and Gemini implemented a string slug function. Independent execution returned `hello-gemini` for padded, repeated whitespace input and an empty string for empty input. An unrelated file retained its original contents.

Direct wrapper execution exercised edits and corrections with `gemini-3.7-flash-medium` and `gemini-3.7-flash-high`. Read-only runs with `gemini-3.8-flash-medium` and `gemini-3.1-pro-high` followed a repository-specific `AGENTS.md` instruction and correctly processed Unicode data from a directory containing spaces.

Native subagent runs recorded child conversation IDs, inherited model selection, completed calculations, and parent integration. Live progress included subagent dispatch events. Empty contracts, an unavailable model, and a one-second provider timeout returned exit code 1. Provider timeout evidence was retained as an `ERROR` result.
