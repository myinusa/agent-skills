---
name: grok-bot-to-opencode-delegation
description: Delegate local repository implementation, investigation, review, or documentation from Grok Bot to OpenCode. Use when asked to delegate to OpenCode or invoke /grok-bot-to-opencode-delegation, with Grok Bot orchestrating and accepting the work.
---

# OpenCode delegation

Grok Bot owns the task contract, sequencing, evidence review, corrections, and acceptance. OpenCode performs the repository work. Run the bridge through local-computer execution on the Windows machine that holds the repository. Keep that machine's identifier with the run descriptor for subsequent reads.

## Prepare the pass

Resolve the user's repository or working directory to an absolute Windows path. Write a temporary UTF-8 contract on that machine containing the objective, relevant context and instructions, scope of authorized changes, acceptance criteria, validation commands, and requested response fields: `summary`, `changed_files`, `validation`, `risks`, `unresolved`. Preserve existing user changes. Delegate the complete coherent task and keep one pass active at a time because the launcher regenerates shared configuration directories.

The package is available through `$env:SKILL_PACKAGE_ROOT`. The bridge uses `%USERPROFILE%\bin\opencode-no-plugins.ps1` and `$env:USERPROFILE\.config\opencode-no-plugins`, with Build mode and allow-all permissions. The contract determines authorized task scope. The bridge creates a minimal `opencode.json` when the working directory has neither JSON nor JSONC configuration; existing configuration is preserved and runtime overrides establish the worker permissions.

## Invoke

Set `$env:SKILL_PACKAGE_ROOT` to the installed skill directory before running the bridge.

Use local PowerShell 7:

```powershell
pwsh -NoProfile -File "$env:SKILL_PACKAGE_ROOT\Invoke-OpenCodeAgent.ps1" `
    -WorkingDirectory 'C:\absolute\repository' `
    -PromptFile 'C:\absolute\temporary-contract.txt'
```

The foreground command streams progress until exit. Keep its local execution handle and read its output until it finishes. Pass `-Model 'provider/model'` to select an explicit model. Omit the parameter to use OpenCode's selection. List identifiers through `pwsh -NoProfile -File "$env:USERPROFILE\bin\opencode-no-plugins.ps1" models`. `-Variant` passes a supported provider-specific variant. Pass a known `-SessionId` for correction work in the same directory; use a fresh contract and artifact directory for every pass.

## Background completion

For work that should wake the Bot on completion, configure a dedicated **OpenCode bridge finished** routine using the webhook URL and sender key supplied by its actual routine panel. Have the Bot save those values with `Set-OpenCodeFinishWebhook.ps1 -Url ... -SenderKey ...` on Windows. The destination is `opencode-finish-webhook.json` beside the bridge.

Launch with both `-Background` and `-WebhookConfig "$env:SKILL_PACKAGE_ROOT\opencode-finish-webhook.json"`. Save the returned JSON descriptor and local machine identifier in the parent conversation. `launched` acknowledges process creation. Read `watch.json` to confirm the worker reached `running`; inspect `bridge.stderr.txt` if it exits before writing that file.

The bridge POSTs `event: opencode.session_ended`, `status: completed|failed`, `repo`, `sessionId`, `exitCode`, `bridgePid`, `runDirectory`, `watchPath`, `lastMessagePath`, and `finishedAt`, with `Authorization: Bearer <senderKey>`.

Configure the routine to notify the parent Bot of this run descriptor. The parent reads the matching watch/result files using local execution on the saved machine and resumes the acceptance loop. Cloud executors use the callback payload as the notification; Windows file reads belong on the local machine. Match the run directory to the delegated pass. Treat callbacks as notifications and confirm their status from the local files.

Choose foreground execution when completion will be consumed through the local execution handle. Background callback delivery is recorded separately as `webhookStatus`; a failed delivery leaves the completed/failed worker status and artifacts available. Report the delivery failure when inspecting the run.

## Accept

Read `watch.json`, `last-message.txt`, and relevant events from the returned artifact directory. `events.jsonl` contains raw events, `live.txt` readable progress, and `stderr.txt` CLI diagnostics. Read artifacts on the Windows machine. Normal worker completion is distinct from fulfilling the contract.

Inspect affected files and validate behavior proportionately under repository rules. Send OpenCode a correction contract for evidenced gaps and retain implementation ownership with the worker. Continue while passes make progress. Report unexpected changes, invocation failures, external dependencies, and outstanding decisions. Commits, pushes, merges, releases, deployments, and external messages follow the user's explicit authorization.
