---
title: Grok Build OpenCode Delegation
type: readme
description: Setup and invocation of the OpenCode worker skill for Grok Build.
status: active
date created: 2026-09-11
date modified: 2026-09-11
---

# Grok Build OpenCode delegation

This folder is installed as a repository skill in `.grok/skills/grok-build-to-opencode-delegation`. Grok Build discovers it as `/grok-build-to-opencode-delegation`. Copy the complete folder into another repository's `.grok/skills/` to use it there. The worker can target any absolute working directory.

```text
/grok-build-to-opencode-delegation implement the approved invoice export change in this repository. Review the resulting files and behavior, then send correction passes as needed.
```

To select a model, add `use provider/model` with an identifier from `opencode-no-plugins`' model list. The script accepts `-Model`, `-Variant`, and `-SessionId`; the selected OpenCode provider supplies authentication and model access.

## Local invocation

PowerShell 7 and `%USERPROFILE%\bin\opencode-no-plugins.ps1` are required. Invoke the `.ps1` launcher through `pwsh`; the installed `.cmd` launcher uses Windows PowerShell.

```powershell
$contract = Join-Path $env:TEMP 'opencode-task.txt'
'Implement the approved change. Follow AGENTS.md. Return changed files and validation evidence.' |
    Set-Content -LiteralPath $contract -Encoding utf8

pwsh -NoProfile -File '.grok\skills\grok-build-to-opencode-delegation\scripts\Invoke-OpenCodeAgent.ps1' `
    -WorkingDirectory 'C:\absolute\repository' -PromptFile $contract `
    -Model 'provider/model'
```

Replace `provider/model` with an available identifier, or omit `-Model` to use OpenCode's selection. Every invocation uses Build mode, allow-all permissions, and the isolated profile at `$env:USERPROFILE\.config\opencode-no-plugins`. Runtime settings apply alongside the target's existing configuration. In a directory with neither `opencode.json` nor `opencode.jsonc`, the wrapper creates:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "default_agent": "build",
  "permission": "allow"
}
```

The installed launcher regenerates the isolated global profile from the regular profile's non-plugin settings and sanitizes the target's project configuration. Provider settings remain usable; `--pure` disables external plugins. Run delegated passes sequentially because the launcher shares its generated directories.

## Results and corrections

Each run stores its contract path and artifacts under a unique temporary directory, printed at startup. Set `-RunDirectory` to choose an unused location. `watch.json` records `starting`, `running`, then `completed` or `failed`. The final status is written before a configured webhook is sent. Process exit and a final OpenCode `stop` event determine completion; Grok separately verifies task acceptance.

Read `events.jsonl`, `live.txt`, `last-message.txt`, and `stderr.txt` for evidence. Resume a correction with `-SessionId` from `watch.json`, the same working directory, and a new contract. Run artifacts remain available for review. OpenCode stores session history for resumption; automatic session sharing is disabled for these invocations.

For asynchronous execution, the same wrapper supports `-Background`; it returns a JSON descriptor containing the bridge PID and watch path. Monitor those paths on the Windows machine. The Grok Bot package documents the completion webhook workflow.

## References

- [Grok Build skills](https://github.com/xai-org/grok-build/blob/main/crates/codegen/xai-grok-pager/docs/user-guide/08-skills.md)
- [OpenCode CLI](https://opencode.ai/docs/cli/)
- [OpenCode configuration](https://opencode.ai/docs/config/)
- [OpenCode permissions](https://opencode.ai/docs/permissions/)
