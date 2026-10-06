---
name: grok-build-to-codex-delegation
description: Delegate repository implementation, investigation, review, or documentation work from Grok to Codex GPT-5.6 Luna or Sol at high reasoning, with Grok retaining orchestration and acceptance. Use when the user asks Grok to hand work to Codex, delegate to Codex, use Codex as the worker, or runs /grok-build-to-codex-delegation.
when-to-use: Use Codex as the repository worker while Grok plans, reviews, and accepts the result.
argument-hint: task for Codex
compatibility: Requires PowerShell 7 and an authenticated Codex CLI with access to the selected model.
---

# Codex Delegation

Grok owns orchestration: it frames the objective, supplies context, delegates, reviews evidence, and decides whether another pass is useful. Codex performs the repository work, including investigation, implementation decisions, edits, and validation within the assigned scope.

Read [usage examples](references/usage-example.md) when the user wants invocation examples or help phrasing a delegation request.

Delegate the user's full requested outcome in one contract when it forms a coherent task. Split work when distinct sequencing, permissions, or acceptance criteria make separate passes useful.

## Prepare the contract

Create a temporary UTF-8 text file outside the repository containing:

- the objective and expected deliverable
- repository context, working scope, and relevant paths
- task-specific user requirements and external context
- acceptance criteria and useful validation commands
- the authorized repository actions and mutation scope
- the response fields `summary`, `changed_files`, `validation`, `risks`, and `unresolved`

The contract is Codex's complete task context. Codex also loads the repository's `AGENTS.md` instructions through the CLI. Include the transient conversation facts needed for completion.

Codex works directly in the current checkout and sees its existing files and user changes. Preserve existing user changes and keep edits within the assigned scope.

## Invoke Codex

Tell the user which work is being delegated. Resolve the repository root so the skill also works when Grok starts from a nested directory, then run the bundled wrapper:

```powershell
$repositoryRoot = (& git rev-parse --show-toplevel).Trim()
$skill = Join-Path $repositoryRoot '.grok\skills\codex-delegation'
& (Join-Path $skill 'scripts\Invoke-CodexAgent.ps1') `
    -WorkingDirectory $repositoryRoot `
    -PromptFile $contract
```

Pass `-UseSubagents` when the user requests Codex subagents. The wrapper enables the Codex multi-agent feature and asks the worker to use subagents for suitable independent workstreams.

Luna is the default model. Pass `-Model Sol` when the user requests Sol:

```powershell
& (Join-Path $skill 'scripts\Invoke-CodexAgent.ps1') `
    -WorkingDirectory $repositoryRoot `
    -PromptFile $contract `
    -Model Sol
```

Both models use `high` reasoning and the `fast` service tier. The wrapper uses an ephemeral Codex session, loads the repository's Codex instructions, and passes `--dangerously-bypass-approvals-and-sandbox`. State the authorized actions and repository mutation scope explicitly in the contract. The default worker is a single Codex agent.

## Accept the result

After every pass, inspect the repository state and run proportionate validation against the contract. Treat the Codex response as navigation and the resulting files and behavior as acceptance evidence.

When gaps remain, create a correction contract for the same working directory. Record each gap with the expected result, observed evidence, and required correction. Keep implementation ownership with Codex and reassess the complete result after each correction pass.

Continue while each pass makes concrete progress. Finish when every acceptance criterion is verified. Return unresolved work when an external condition prevents validation, a user decision or expanded authorization is needed, or Codex reports a capability mismatch.

Commits, merges, rebases, pushes, releases, and deployments require the user's explicit request. Remove temporary contract files after the acceptance loop. Report invocation failures and unexpected repository changes to the user.
