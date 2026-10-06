---
title: Gemini Delegation Examples
type: guide
description: Grok Build invocation, task contracts, and correction passes for Gemini repository work.
status: active
date created: 2026-09-06
date modified: 2026-09-06
tags: [grok-build, gemini, delegation]
component: [agents]
---

# Usage examples

## Requests to Grok Build

```text
/grok-build-to-gemini-delegation implement the approved export change, preserve unrelated edits, and run the existing build
```

```text
/grok-build-to-gemini-delegation use gemini-3.7-flash-high to investigate the date parsing failure; keep the checkout read-only and report the cause with file references
```

```text
/grok-build-to-gemini-delegation use gemini-3.1-pro to review the supplied data transformation and explain any correctness gaps
```

```text
/grok-build-to-gemini-delegation use gemini-3.8-flash-medium with Gemini subagents to investigate the independent import and export paths, then integrate the findings
```

Grok passes `-UseSubagents` for the requested delegation. For a longer worker pass, add `-TimeoutSeconds 1800` to the wrapper invocation.

## Local invocation

Run in PowerShell 7 from the repository root:

```powershell
$repositoryRoot = (& git rev-parse --show-toplevel).Trim()
$contract = Join-Path ([IO.Path]::GetTempPath()) ('gemini-contract-' + [guid]::NewGuid() + '.txt')
@'
Objective: Investigate how this repository parses dates.
Scope: Read-only repository investigation. Read applicable AGENTS.md and referenced rules.
Deliverable: Explain the parsing entry points and one concrete failure mechanism, with file references.
Acceptance: Findings are supported by inspected source. Keep the repository unchanged.
Response: summary, changed_files, validation, risks, unresolved.
'@ | Set-Content -LiteralPath $contract -Encoding utf8

pwsh -NoProfile -File (Join-Path $repositoryRoot '.grok/skills/grok-build-to-gemini-delegation/scripts/Invoke-GeminiAgent.ps1') `
    -WorkingDirectory $repositoryRoot -PromptFile $contract
```

Inspect the response and source before accepting. Remove the contract after review with `Remove-Item -LiteralPath $contract`.

## Correction contract

Include the original objective, scope, repository rules, and acceptance criteria, followed by concrete gaps:

```text
Expected: The exported timestamp retains the input timezone offset.
Observed: The provided example loses +01:00 in the output; see the attached command output and affected function path.
Required correction: Preserve the offset through the export transformation and rerun the same example.
Response: summary, changed_files, validation, risks, unresolved.
```

Invoke the same wrapper and model in the same checkout, then independently inspect the complete result.
