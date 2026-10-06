---
title: Antigravity Invocation for Image to Code
type: reference
description: Direct Gemini invocation with access to reference images and rendered screenshots.
status: active
date created: 2026-09-16
date modified: 2026-09-16
---

# Antigravity invocation

Use the installed CLI's `agy --help` and `agy models` to resolve supported options and the exact requested Gemini ID. Work in the target project directory. Git membership is optional. Resolve paths before invocation and preserve prompt text as an argument value.

## Establish visual access

Before initial implementation, ask Gemini to open the reference files with an image-capable tool and describe concrete visible details. Use a read-only prompt, omit automatic permission approval, and add each reference directory to the workspace. Compare its observations with Codex's own image inspection. File names, metadata, and a claim of success alone establish insufficient evidence. On the first rendered comparison, confirm the same capability with the actual screenshot as well.

For this check, use `--mode plan` with slash-command expansion enabled. The installed CLI warns that plan mode has no effect with `--disable-slash-commands`. Treat plan mode as a requested mode and inspect the actual result and permission behavior.

## Invoke an implementation or correction

Prepare a UTF-8 contract with the worker prompt, then execute the following with resolved task variables. `$imageDirectories` contains the distinct parent directories of the reference files. `$evidenceDirectory` contains rendered screenshots. Include those directories on every invocation.

```powershell
$workerPrompt = Get-Content -LiteralPath $contractPath -Raw -Encoding utf8
$workerArguments = @(
    '--dangerously-skip-permissions', '--disable-slash-commands',
    '--model', $workerModel, '--print-timeout', '10m',
    '--add-dir', $projectRoot, '--add-dir', $evidenceDirectory
)
foreach ($imageDirectory in $imageDirectories) {
    $workerArguments += @('--add-dir', $imageDirectory)
}
$workerArguments += @('-p', $workerPrompt)
Push-Location -LiteralPath $projectRoot
try {
    rtk proxy agy @workerArguments
    $workerExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
```

Capture tool output and exit status in the task record. A nonzero exit, empty result, permission failure, or reported image-access failure leaves the invocation incomplete. Retain partial edits for inspection. Check for a still-running worker before retrying after a timeout. Use a new complete contract for each invocation; each call starts without the preceding conversation.

The image directories provide access to input files; the worker contract separately limits permitted edits. Keep reference images unchanged. Review-only calls preserve application source and reference images while allowing screenshots, comparison artifacts, and findings in the designated evidence directory. Use the invocation above for evidence-producing review with those explicit limits. Reserve the read-only plan invocation for inspecting supplied images where all required evidence already exists.
