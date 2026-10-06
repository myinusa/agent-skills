---
name: grok-bot-to-gemini-delegation
description: Delegate local repository work from Grok Bot to Google Gemini through Antigravity, with Grok Bot reviewing and accepting each pass. Use for Gemini delegation requests or /grok-bot-to-gemini-delegation.
---

# Gemini delegation

Grok Bot owns orchestration and acceptance. Gemini performs investigation, implementation, edits, and validation on the user's local Windows computer.

## Prepare the contract

Establish the local repository path, requested outcome, allowed files, constraints, and acceptance criteria. Ask for the repository path when it remains unknown.

Create a uniquely named temporary UTF-8 text file using the local-computer shell. Include the objective, deliverable, repository and instruction paths, relevant conversation facts, user requirements, authorized actions, mutation scope, acceptance criteria, and useful validation commands. Request response fields `summary`, `changed_files`, `validation`, `risks`, and `unresolved`.

Create multiline contracts within a PowerShell shell or a temporary `.ps1` file. Preserve literal `$` characters, quotes, and newlines across the Bot's outer shell boundary.

Each pass starts a fresh conversation. Include complete context in every contract. Gemini reads applicable repository `AGENTS.md` files and referenced rules. Specify read-only scope explicitly for investigation and review tasks.

## Invoke locally

Set `$env:SKILL_PACKAGE_ROOT` to the installed skill directory before running the bridge.

Use `gemini-3.7-flash` by default, mapped to `gemini-3.7-flash-medium`. Honor explicit requests for `gemini-3.7-flash-high` or `gemini-3.1-pro` (mapped to `gemini-3.1-pro-high`).

An explicit Gemini model slug listed by local `agy models`, such as `gemini-3.8-flash-medium`, is also accepted.

Tell the user the selected model and delegated work. Execute through Grok Bot's local Windows shell, where the repository, contract, and authenticated Antigravity CLI are available:

```powershell
pwsh -NoProfile -File "$env:SKILL_PACKAGE_ROOT\Invoke-GeminiAgent.ps1" `
    -WorkingDirectory 'C:\absolute\path\to\repository' `
    -PromptFile 'C:\absolute\path\to\temporary-contract.txt' `
    -Model gemini-3.7-flash
```

Resolve `%USERPROFILE%` on the local Windows computer. The Bot's cloud filesystem and local Windows filesystem are separate. Confirm local-computer execution is available before creating the contract or invoking the bridge; request access if it is unavailable.

The wrapper resolves nested paths to the Git repository root and works directly in that checkout. It checks model availability and enables Antigravity's noninteractive tool approvals with `--dangerously-skip-permissions`. The contract defines authorized scope. One Gemini worker handles each pass by default. Pass `-UseSubagents` for user-requested Gemini subagents; Gemini uses native Antigravity delegation on the selected model and integrates all results before returning to Grok Bot.

The provider wait limit defaults to 600 seconds. Set `-TimeoutSeconds` to suit a longer task. On timeout or interruption, inspect the recorded conversation and affected files before retrying; the provider may already have performed work.

## Observe and accept

Retain the local shell session until completion, polling its session identifier when execution is asynchronous. The wrapper prints a unique local temporary run directory containing `live.txt`, `events.jsonl`, `result.json`, and `response.txt`. Read these through the local shell. A quiet interval alone establishes no failure.

Exit code zero establishes provider success with a nonempty response. Independently inspect resulting files and behavior against the acceptance criteria, preserving unrelated user changes. Run validation consistent with the user request and repository instructions.

For remaining gaps, create a fresh correction contract with original scope and each gap's expected result, observed evidence, and required correction. Invoke the same bridge and model in the same checkout, then reassess. Continue while passes make concrete progress. Report unresolved work when two consecutive corrections leave the same gap unchanged, an external condition prevents completion, or a user decision is required.

Report invocation failures and unexpected repository changes. Repair a demonstrated contract or environment defect before retrying once. A model availability failure requires a user-selected model change. Commits, merges, rebases, pushes, releases, and deployments require explicit user authorization carried into the contract.

Remove temporary contracts after acceptance and retain run evidence until reviewed. Return the outcome, changed paths, actual validation, and remaining gaps.

## Grok Bot close monitoring (required)

After starting Watch-GeminiDelegation or Invoke-GeminiAgent in the background, Grok must AwaitShell that session until `COMPLETED SUCCESS`, `FAILED after`, or `ATTENTION` stall/success/failure. Do not rely on a 5-minute routine as the primary wake. The watchdog writes `.grok/gemini-attention.json` on terminal/stall events.
