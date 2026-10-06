---
title: OpenCode Image Worker Invocation
type: reference
description: Plugin-free OpenCode delegation with image attachments, model overrides, and run evidence.
status: active
date created: 2026-09-16
date modified: 2026-09-16
---

# OpenCode invocation

Use PowerShell 7 and the installed `%USERPROFILE%/bin/opencode-no-plugins.ps1` launcher. The bundled wrapper supplies Build mode, noninteractive permissions, image attachments, and disabled session sharing. The launcher runs OpenCode with `--pure` and regenerates a sanitized configuration profile and project overlay. Run all invocations sequentially, including model discovery, because these generated directories are shared. Keep the existing Gemini and Grok delegation skills unchanged.

## Model selection

The default is **Muse Spark 1.3 Contributor**, with exact ID `opencode-go/muse-spark-1.3-contributor`. Discover another requested model through the same launcher:

```powershell
rtk proxy pwsh -NoProfile -File "$env:USERPROFILE\bin\opencode-no-plugins.ps1" models --verbose
```

Resolve a display name to its exact provider/model ID. Check image input and tool-call capabilities in the model entry, then establish actual image access through a short worker invocation. Keep the requested provider and model; unavailable or ambiguous selections require user direction. Pass `-Variant` only for a supported, requested variant.

## Run a pass

Read the target project's applicable instructions and create a complete UTF-8 contract using [worker-prompt.md](worker-prompt.md). Use absolute paths. Attach original images and current rendered screenshots with `-Images`; label their roles and viewport sizes in the contract. For the first pass, request concrete image observations before authorizing implementation. Codex independently inspects the same images.

```powershell
# Resolve $skillDirectory from this skill's installed location.
$workerScript = Join-Path $skillDirectory 'scripts\Invoke-OpenCodeImageWorker.ps1'
& $workerScript -WorkingDirectory $projectRoot -PromptFile $contractPath `
    -Images @($referenceImage, $renderedScreenshot) `
    -RunDirectory $unusedRunDirectory -Background
```

For initial generation or the access check, attach only the reference images. An omitted `-Model` uses the exact default above. Supply `-Model 'provider/model'` for an explicit override. The script exits its PowerShell process; invoke through a separate `pwsh` process or a short invocation `.ps1` when orchestration needs to continue in the parent. PowerShell arrays should be passed from that script, preserving paths containing spaces.

The wrapper uses the target directory as its working directory. It leaves project configuration files intact and supplies worker settings through process-local environment variables. Its task contract defines authorized changes; worker permission settings permit tool execution and are not a file sandbox. The launcher manages only its known generated profile/cache paths. Review unexpected worker changes before further passes.

## Image access and review

The image-access contract permits inspection only: ask for concrete text, layout, and color observations from the attached pixels and the paths actually examined. Compare these with Codex's inspection before starting implementation. A claimed success, filename, or metadata alone is insufficient. Report failed image input without substituting another model.

Use `agent-browser` for the running-page preview and its screenshots, with `--headed false` for headless operation. Both agents inspect identical original/rendered images. Verification-only contracts preserve application code and originals while allowing evidence artifacts in the designated directory. Each compare → correct → verify loop follows the skill's fidelity requirements.

## Monitor and resume

Continuing an implementation is independent of continuing a provider session. For a candidate created elsewhere, rebuild the contract from its current source, original references, fresh rendering, permitted files, URL, exclusions, and known remaining work. Omit `-SessionId` to start a fresh OpenCode session with the selected model, then record its returned session ID for correction passes. The previous provider's session ID belongs to that provider and stays outside the OpenCode invocation. An unavailable old session uses the same source-and-evidence handoff.

`-Background` returns the run directory and bridge PID immediately and launches the worker hidden. Read `watch.json` for `starting`, `running`, `completed`, or `failed`, the session ID, exit code, and artifact paths. `events.jsonl` preserves raw events; `live.txt` shows readable progress; `last-message.txt` contains worker text; `stderr.txt` preserves diagnostics.

Use a fresh contract and unused run directory for every pass. Resume a correction or verification using `-SessionId` from the previous `watch.json`, the same working directory, and the same selected model. Include the full current contract and reattach the original and current rendering. Avoid implicit latest-session resumption. A model override starts a fresh session with the current evidence.

For independent comparison and verification, use a fresh session when the implementation history contains proposed corrections or acceptance predictions for the supplied capture. Preserve the implementation session ID separately for corrections. Send Codex's findings after the independent review returns.

The wrapper requires a normal process exit and a final OpenCode stop event. That establishes invocation completion; Codex separately checks task acceptance against source and images. Inspect partial output after a failure. Establish that the preceding worker has ended before retrying. Keep artifacts for the final report and unresolved work.

When progress appears stalled, inspect `watch.json`, the latest event/tool activity, partial edits, and the process tree rooted at the recorded bridge and worker PIDs. The recorded worker PID identifies the launcher PowerShell process; identify its OpenCode descendant through parentage, start time, command line, and session before taking action. Compare observations over time and distinguish model generation, a pending tool, and process exit. Silence alone warrants investigation. The wrapper writes `stderr.txt` after process termination; an empty live file leaves stderr status unknown. If `watch.json` has yet to appear, inspect `bridge.stderr.txt`, `bridge.stdout.txt`, and the returned bridge PID.

When a stalled task-owned process requires stopping, record the evidence and reason, stop only the verified invocation's process tree, and confirm its processes have exited. Preserve partial source and evidence, compare them with the allowed-file baseline, and describe remaining work in a fresh contract. Resume the explicit implementation session only after this inspection and within the skill's retry limit. Report manual intervention and interrupted rounds separately from completed reviews.

The CLI's model, attachment, session, and JSON output options are documented in the [OpenCode CLI reference](https://opencode.ai/docs/cli/).
