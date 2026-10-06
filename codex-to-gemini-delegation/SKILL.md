---
name: codex-to-gemini-delegation
description: Delegate one explicitly selected, bounded task from Codex to an authenticated Gemini worker through Antigravity CLI, then have Codex assess and return correction passes until acceptance. Uses the current checkout by default or an isolated worktree when requested. Use only when the user invokes $codex-to-gemini-delegation or directly asks Codex to delegate a specific task to Gemini.
---

# Gemini Delegation

Codex owns decomposition, architecture, integration, review, and final acceptance. Give Gemini one stateless task with an objective result.

Read [usage examples](references/usage-examples.md) when the user wants ready-to-use invocation patterns.

## Choose a worker

- `gemini-3.7-flash`: default for bounded coding, review, documentation, and repository analysis.
- `gemini-3.7-flash-high`: use when the task depends on unusually difficult reasoning, mathematics, data analysis, language interpretation, or instruction following.
- `gemini-3.1-pro`: use for data-heavy work where Gemini 3.1 Pro is specifically useful or requested.

Honor a user-selected model. A missing model alias is an error that requires user-visible reporting.

## Prepare the task

Create a temporary UTF-8 text contract outside the repository containing:

- objective and deliverable
- repository context and allowed paths
- constraints and excluded work
- acceptance criteria and useful validation commands
- required response fields: `summary`, `changed_files`, `validation`, `risks`, and `unresolved`

The worker receives no conversation history and cannot delegate further. Include every fact it needs.

## Choose an execution mode

Use `Direct` mode by default. Pass the current repository root as `WorkingDirectory`. Gemini sees the current working copy, including uncommitted files, and its edits land directly in that checkout.

Use `Worktree` mode when the user requests isolation or the task needs a separate working copy. Create a clean linked worktree detached from the relevant commit with `git worktree add --detach <temporary-path> <commit>` and keep the path outside the primary checkout.

Before invocation, send one progress update:

```text
Delegating to <model alias>: <brief task>
```

Invoke the bundled wrapper:

```powershell
$geminiSkill = Join-Path $HOME '.codex\skills\codex-to-gemini-delegation'
& (Join-Path $geminiSkill 'scripts\Invoke-GeminiAgent.ps1') `
    -WorkingDirectory $repositoryRoot `
    -Model gemini-3.7-flash `
    -PromptFile $contract
```

For isolated execution, pass `-Mode Worktree` and the detached worktree root. The wrapper validates its clean, linked, detached state before invocation.

The wrapper enables Antigravity's non-interactive permission mode inside the selected working directory, validates the requested model against `agy models`, and leaves global Git configuration unchanged.

## Run the acceptance loop

After every Gemini pass, Codex independently inspects the resulting files and behavior against the task's acceptance criteria. Treat the worker summary as navigation; use the repository state and validation results as acceptance evidence.

When criteria remain incomplete:

1. Create a new correction contract for the same task and working directory.
2. List each remaining gap as a concrete `expected`, `observed`, and `required correction` item.
3. Include relevant file paths, runtime evidence, failed acceptance checks, and constraints from the original contract.
4. Ask Gemini to address only those gaps and return the standard response fields.
5. Invoke the same model again, then reassess the complete result.

Continue while each pass makes concrete progress. Complete the task when Codex has verified every acceptance criterion. End the loop with an unresolved report when two consecutive correction passes leave the same gap unchanged, validation cannot run because of an external condition, or the next correction requires a user decision or expanded scope.

Direct mode reuses the current checkout automatically. For correction passes in worktree mode, reuse the same worktree and pass `-AllowExistingChanges` to the wrapper.

For a read-only task, state that requirement in the contract and inspect the worker result for reported changes. For an editing task, review the files Gemini changed, preserve unrelated working-copy changes, and run proportionate validation. Worktree-mode changes require review and integration into the primary checkout.

Workers never commit, merge, rebase, push, release, or deploy. Remove the temporary contract after review. Remove a temporary worktree after its results have been reviewed and integrated.

Repair a contract, context, or environment defect and retry the failed invocation once. Report a repeated invocation failure or capability mismatch; model changes require an explicit user choice when the requested model cannot complete the task.
