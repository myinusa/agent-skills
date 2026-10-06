---
title: Grok Bot Gemini Delegation Examples
type: guide
description: Requests and local PowerShell invocation for the Grok Bot Gemini bridge.
status: active
date created: 2026-09-06
date modified: 2026-09-06
tags: [grok-bot, gemini, delegation]
component: [agents]
---

# Usage examples

## Requests to Grok Bot

```text
/grok-bot-to-gemini-delegation in <REPOSITORY_PATH>, have Gemini implement the agreed change, preserve unrelated edits, and run the existing build
```

```text
/grok-bot-to-gemini-delegation use gemini-3.7-flash-high to investigate the import failure in <REPOSITORY_PATH>; keep repository access read-only
```

```text
/grok-bot-to-gemini-delegation use gemini-3.1-pro to review the data transformation in <REPOSITORY_PATH> and report correctness gaps with file references
```

```text
/grok-bot-to-gemini-delegation use gemini-3.8-flash-medium with Gemini subagents in <REPOSITORY_PATH> to investigate the independent import and export paths, then integrate the findings
```

Grok Bot passes `-UseSubagents` for the requested delegation. For a longer worker pass, add `-TimeoutSeconds 1800` to the local bridge invocation.

## Local bridge invocation

Create the contract and invoke the bridge on the local Windows computer:

```powershell
$contract = Join-Path ([IO.Path]::GetTempPath()) ('gemini-contract-' + [guid]::NewGuid() + '.txt')
@'
Objective: Explain the repository's import entry points.
Scope: Read-only investigation. Read applicable AGENTS.md and referenced rules.
Acceptance: Provide source-backed findings and keep the repository unchanged.
Response: summary, changed_files, validation, risks, unresolved.
'@ | Set-Content -LiteralPath $contract -Encoding utf8

pwsh -NoProfile -File "$env:SKILL_PACKAGE_ROOT\Invoke-GeminiAgent.ps1" `
    -WorkingDirectory 'C:\absolute\path\to\repository' `
    -PromptFile $contract `
    -Model gemini-3.7-flash
```

Review the reported run directory and inspected source. For a correction, create a new contract carrying the original scope and the expected result, observed evidence, and required correction. Use the same model and repository for the next pass. Remove the temporary contracts after acceptance.
