---
name: grok-build-to-gemini-delegation
description: Delegate repository work from Grok Build to Google Gemini through Antigravity, with Grok reviewing and accepting each pass. Use for Gemini delegation requests or /grok-build-to-gemini-delegation.
---

# Gemini delegation

Grok owns orchestration, context, review, integration, and acceptance. Gemini performs investigation, implementation, edits, and validation within the assigned repository scope.

Delegate a coherent requested outcome in one contract. Split work when distinct sequencing or acceptance criteria make separate passes useful. Read [usage examples](references/usage-example.md) for contracts and correction passes.

## Prepare the contract

Create a uniquely named temporary UTF-8 text file outside the repository. Include:

- objective and deliverable
- repository path, allowed files, and applicable repository instruction paths
- relevant conversation facts, user requirements, and constraints
- authorized actions, mutation scope, and treatment of existing user changes
- acceptance criteria and proportionate validation commands
- response fields: `summary`, `changed_files`, `validation`, `risks`, `unresolved`

Each pass starts a fresh conversation. Supply complete context in initial and correction contracts. For read-only work, specify read-only scope explicitly. The wrapper asks Gemini to read applicable `AGENTS.md` files and referenced rules.

Use Grok's file-writing tool to create the contract when available. For shell-only creation, execute the PowerShell example in a PowerShell shell or a temporary `.ps1` file so multiline text and `$` characters survive the outer shell unchanged.

## Invoke Gemini

Use `gemini-3.7-flash` by default. Honor an explicit model selection:

| Wrapper model | Antigravity model |
| --- | --- |
| `gemini-3.7-flash` | `gemini-3.7-flash-medium` |
| `gemini-3.7-flash-high` | `gemini-3.7-flash-high` |
| `gemini-3.1-pro` | `gemini-3.1-pro-high` |

An explicit Gemini model slug from `agy models`, such as `gemini-3.8-flash-medium`, is also accepted. Keep the default unless the task or user selects another model; resolve every selection against the available model list.

Tell the user the selected model and delegated task. Resolve the installed skill directory from this file's location, then invoke its wrapper in PowerShell 7:

```powershell
$repositoryRoot = (& git rev-parse --show-toplevel).Trim()
$skill = Join-Path $repositoryRoot '.grok\skills\grok-build-to-gemini-delegation'
pwsh -NoProfile -File (Join-Path $skill 'scripts\Invoke-GeminiAgent.ps1') `
    -WorkingDirectory $repositoryRoot `
    -PromptFile $contract `
    -Model gemini-3.7-flash
```

The example uses the project-local installation. The wrapper accepts a repository root or nested directory, resolves the root, and edits that checkout directly. A user-requested isolated checkout can be passed as `WorkingDirectory`; Grok owns its setup and integration.

Antigravity uses cached authentication and checks the selected model against `agy models`. The wrapper enables noninteractive tool approvals with `--dangerously-skip-permissions`; the contract defines authorized scope. One Gemini worker handles each pass by default. Pass `-UseSubagents` when the user requests Gemini subagents. Gemini assigns independent work through native Antigravity subagents on the selected model, integrates their results, and returns to Grok for acceptance.

The provider wait limit defaults to 600 seconds. Set `-TimeoutSeconds` to suit a longer task. On timeout or interruption, inspect the recorded conversation and affected files before retrying; the provider may already have performed work.

## Observe and accept

Keep the shell session alive until the command completes. For asynchronous shell execution, retain its session identifier and poll that session. The wrapper prints a unique run directory under the local temporary directory. Read `live.txt` for progress, `events.jsonl` for tool evidence, `result.json` for provider status, and `response.txt` for the final response. A quiet interval alone establishes no failure.

Exit code zero means Antigravity returned a successful, nonempty response. Grok then inspects changed files and actual behavior against every acceptance criterion, preserving unrelated user changes.

For remaining gaps, write a fresh correction contract with the original scope plus expected result, observed evidence, and required correction for each gap. Invoke the same model in the same checkout and reassess. Continue while passes make concrete progress. Report unresolved work when two consecutive correction passes leave the same gap unchanged, an external condition prevents completion, or a user decision is required.

Report invocation failures and unexpected changes. Repair a demonstrated contract or environment defect before retrying once. A model availability failure requires a user-selected model change. Commits, merges, rebases, pushes, releases, and deployments require explicit user authorization carried into the contract.

Remove temporary contracts after acceptance. Keep run evidence until the result has been reviewed; report the final outcome, changed paths, actual validation, and remaining gaps.
