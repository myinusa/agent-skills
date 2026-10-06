---
title: Grok Bot OpenCode Delegation
type: readme
description: Local OpenCode bridge, private Grok Bot skill, and completion webhook setup.
status: active
date created: 2026-09-11
date modified: 2026-09-11
---

# Grok Bot OpenCode delegation

Grok Bot coordinates the task and reviews the result. This package runs OpenCode on the Windows computer holding the repository, using the `opencode-no-plugins` launcher and isolated profile.

## Install the private skill

Attach [SKILL.md](SKILL.md) to a one-to-one Bot conversation and ask it to save the attachment as a private skill named `opencode-delegation`. Use its description for the selection text and its body for the instructions. Enable it for the relevant Bot under Settings → Plugins → Yours. Local-computer execution must be available on the Windows machine. [Grok Bot skill setup](https://docs.x.ai/grok-bot/skills-routines-and-automations) describes saving and enabling private skills.

```text
/grok-bot-to-opencode-delegation in <REPOSITORY_PATH>, implement the approved change, inspect the result, and send correction passes until the acceptance criteria are met.
```

Add `use provider/model` to select an identifier from the installed OpenCode model list. Model selection remains configurable per pass.

## Bridge parameters

| Parameter | Purpose |
| --- | --- |
| `-WorkingDirectory` | Required absolute target directory; ordinary folders also work. |
| `-PromptFile` | Required UTF-8 task contract on Windows. |
| `-Model` | Optional `provider/model`; omission uses OpenCode's selection. |
| `-Variant` | Optional provider-specific variant. |
| `-SessionId` | Resume a specific session in the same working directory. |
| `-RunDirectory` | Unused artifact directory; defaults to a unique temporary directory. |
| `-Background` | Start a hidden bridge process and return its JSON descriptor. |
| `-WebhookConfig` | JSON file containing the completion URL and sender key. |

Invoke scripts with `pwsh -NoProfile -File`. The worker always uses Build mode and allow-all permissions. Its launcher is `%USERPROFILE%\bin\opencode-no-plugins.ps1`; the profile root is `$env:USERPROFILE\.config\opencode-no-plugins`. The launcher imports sanitized non-plugin settings and invokes OpenCode with `--pure`. Run passes sequentially because it regenerates shared profile/overlay directories.

The bridge creates `opencode.json` with `default_agent: build` and `permission: allow` when the target has neither JSON nor JSONC configuration. Existing files retain their contents; runtime overrides establish these delegation settings. An explicit `-Model` takes precedence over OpenCode's default selection. OpenCode session history remains available for correction passes; automatic session sharing is disabled.

## Completion webhook

Create a dedicated **OpenCode bridge finished** routine in the Bot, then provide its actual webhook URL and sender key to:

```powershell
pwsh -NoProfile -File '.\Set-OpenCodeFinishWebhook.ps1' `
    -Url 'https://actual-routine-endpoint' -SenderKey 'actual-sender-key'
```

The script writes `opencode-finish-webhook.json`. [opencode-finish-webhook.example.json](opencode-finish-webhook.example.json) shows its shape. Supply that file when launching:

```powershell
pwsh -NoProfile -File '.\Invoke-OpenCodeAgent.ps1' `
    -WorkingDirectory 'C:\absolute\repository' `
    -PromptFile 'C:\absolute\contract.txt' `
    -Model 'provider/model' -Background `
    -WebhookConfig '.\opencode-finish-webhook.json'
```

The bridge sends one authenticated POST after recording the worker's final status. Configure the routine to notify the coordinating Bot with the event payload, including its run directory and watch path. The Bot then reads the result using local execution on the saved Windows machine identifier. A real routine URL/key comes from the Bot's account; the example file supplies placeholders.

Foreground execution streams output until the worker exits. Background execution returns `launched` plus the PID and artifact paths. Observe `watch.json` for `starting`, `running`, then `completed` or `failed`. For startup failures before `watch.json` exists, read `bridge.stderr.txt`. A killed bridge may leave a nonterminal watch file; compare its PID with the local process before reporting a run as active.

`events.jsonl` records raw worker events; `live.txt` records progress; `last-message.txt` records assistant text; `stderr.txt` records CLI diagnostics. The watch file records webhook delivery as `unconfigured`, `pending`, `delivered`, or `failed`. Callback delivery failures preserve the worker's status and produce a warning. Completion verifies process termination and a final `stop` event; Grok Bot verifies the actual task result.

## References

- [OpenCode CLI](https://opencode.ai/docs/cli/)
- [OpenCode configuration](https://opencode.ai/docs/config/)
- [OpenCode permissions](https://opencode.ai/docs/permissions/)
- [Grok Bot local-execution controls](https://docs.x.ai/grok-bot/approvals-security-and-privacy)
