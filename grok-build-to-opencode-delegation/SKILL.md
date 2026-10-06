---
name: grok-build-to-opencode-delegation
description: Delegate repository implementation, investigation, review, or documentation from Grok Build to OpenCode, with Grok retaining orchestration and acceptance. Use for requests to delegate to OpenCode or /grok-build-to-opencode-delegation.
when-to-use: Use OpenCode as the repository worker while Grok frames the task and reviews its result.
argument-hint: task, repository path, and optional provider/model
compatibility: Windows, PowerShell 7, and the opencode-no-plugins PowerShell launcher.
---

# OpenCode delegation

Grok owns the objective, task contract, review, correction passes, and final acceptance. OpenCode investigates, implements, and validates within the assigned working directory. Delegate a coherent requested outcome in one pass; sequence separate passes when dependencies require it.

## Prepare

Resolve the intended repository root or explicit working directory to an absolute path. Resolve this skill's directory from its loaded location. The wrapper also supports ordinary directories.

Write a UTF-8 contract outside the repository containing the objective, relevant paths and conversation context, authorized edits, acceptance criteria, and useful validation commands. Ask for `summary`, `changed_files`, `validation`, `risks`, and `unresolved`. Include repository instructions that the worker needs, especially instructions outside its working directory. Preserve existing user changes.

Tell the user which work OpenCode will perform. Keep one delegated pass active at a time: the installed launcher regenerates shared profile and project-overlay directories.

## Run

Set `$env:SKILL_PACKAGE_ROOT` to the installed skill directory before running the wrapper.

Invoke through PowerShell 7:

```powershell
$skill = $env:SKILL_PACKAGE_ROOT
& (Join-Path $skill 'scripts\Invoke-OpenCodeAgent.ps1') `
    -WorkingDirectory $repositoryRoot -PromptFile $contract
```

Pass `-Model 'provider/model'` for an explicit model and `-Variant 'high'` only when that model supports the variant. An omitted model uses OpenCode's configured/default selection. Discover identifiers using:

```powershell
pwsh -NoProfile -File "$env:USERPROFILE\bin\opencode-no-plugins.ps1" models
```

The wrapper launches `opencode-no-plugins.ps1` with the profile root `$env:USERPROFILE\.config\opencode-no-plugins`. That launcher uses OpenCode's `--pure` mode and a sanitized project overlay. The worker runs in `build` with allow-all permissions. A new working directory receives an `opencode.json` with these defaults; existing JSON/JSONC is preserved, with permission and Build settings applied to this invocation. These permissions cover the worker process; the contract defines its authorized task scope.

A fresh pass starts a new session. For a correction that needs the previous context, pass `-SessionId` from that run's `watch.json`, keeping the same directory and selected model. Specify a new contract and a fresh run directory for every pass. Resume an explicit session to keep correction work associated with the correct task.

## Review

The wrapper prints its artifact directory. `watch.json` contains status, session ID, process IDs, exit code, and artifact paths; `events.jsonl` holds raw OpenCode events; `live.txt` holds readable progress; `last-message.txt` holds assistant text; `stderr.txt` holds CLI diagnostics. `-RunDirectory` can select an unused artifact directory. The wrapper's exit code and `completed` status mean the worker ended normally; assess task success against the actual files and behavior.

Read the worker's result, inspect the affected files, and perform proportionate validation under repository rules. Send a correction contract to OpenCode when evidence shows a gap. Continue while passes make concrete progress. Report failures and unexpected changes. Surface an unresolved external dependency or a required user decision with its evidence.

Keep implementation ownership with OpenCode throughout this loop. Commits, pushes, merges, releases, deployments, and external messages follow the user's explicit authorization. Return the accepted result, validation performed, and remaining limitations.

Read [README.md](README.md) for setup and invocation examples.

## Windows host notes

When launching from Grok Build through tk proxy pwsh -Command, the host strips dollar variables from the command string. Write a .ps1 file that contains the Invoke-OpenCodeAgent call, then run pwsh -NoProfile -File against that script. Put contracts in a UTF-8 file under the user grok directory, outside the repository.

Use -Background for a long pass. Watch watch.json for completed or ailed. A new contract and a new -RunDirectory are required for every pass. Pass -SessionId from the previous watch.json when the correction needs the same OpenCode session.

gent-browser open invoked through tk proxy can remain running after it has already printed a successful page title. Stop that hung process and keep using the same --session for snapshot, click, and screenshot.
