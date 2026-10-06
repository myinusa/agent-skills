---
title: Codex Delegation Usage Examples
type: guide
description: Plan handoff prompts, optional worker isolation and recovery for resumable Codex delegation.
status: active
date created: 2026-09-12
date modified: 2026-09-12
tags: [codex, delegation, orchestration]
component: [agents]
related:
  - .agents/skills/codex-to-codex-cli-delegation/SKILL.md
---

# Usage examples

## Normal invocation

```text
Use $codex-to-codex-cli-delegation to implement <PLAN_PATH>.
```

The skill handles worker setup, task contracts, session persistence, reviews and follow-up assignments. It reads the plan's dependencies and explicit restrictions and uses the documented defaults. Add preferences only when they differ from the plan or skill defaults.

For an existing orchestrator prompt:

```text
Use $codex-to-codex-cli-delegation and follow prompts/possible-orchestrator-1.md.
```

That prompt supplies the repository's plan path, worker instructions and repository-specific restrictions.

## Optional detailed instructions

Use this longer example when customizing the delegation behavior. It includes explicit authorization for local commits and integration; select that authorization to match the task.

```text
Use the Codex delegation skill at .agents/skills/codex-to-codex-cli-delegation/SKILL.md.
You own implementation and acceptance of the plan at <PLAN_PATH>.

Read its requirements, acceptance criteria and dependencies completely, using
consecutive sections for large files. Read the applicable repository instructions.

Delegate coherent implementation assignments to resumable CLI workers. Use the
current checkout unless the task requires a separate worktree. Use the skill's
default Luna model, high reasoning, fast service tier and full access.

I authorize implementation, local commits and local integration needed to complete
this plan. Keep pushes, publishing and deployments outside this assignment.

Let workers choose implementation details within the plan and repository rules.
Review their actual changes and send concrete corrections through their saved
sessions. Continue through the remaining assignments and integration automatically.
Investigate missed requirements and integration problems within the agreed scope.

Keep explicit restrictions and tool-bug warnings intact in worker contracts.
Resolve routine technical decisions from the plan and repository evidence.
Bring unresolved product choices to me, with the specific decision needed, while
continuing independent work.

Keep detailed worker output in the run files. Read compact reports first and inspect
logs when a finding or failure needs them. Save a short coordination record outside
the repo with worker state paths, live execution handles, assignments, completed
commits, dependencies and remaining decisions. Update it at handoffs and give me
its absolute path so the run can be resumed after an interruption.

Finish when the authorized implementation meets the plan's acceptance criteria.
Report completed work and any remaining external or user-dependent items accurately.
```

For an existing task-specific orchestrator prompt, supply its path alongside the plan. The supervisor reads both and carries the task-specific restrictions and review requirements into the assignments.

## Two workers, optional worktrees

Add this when parallel implementation is useful:

```text
Use two CLI workers. Assign independent work according to the plan's dependencies.
Give each worker a separate state directory and saved session.

Alpha works in <CURRENT_CHECKOUT>.
Bravo works in <BRAVO_WORKTREE>.
I authorize creating Bravo's local branch/worktree from the agreed starting commit
and merging completed work locally. Preserve existing unrelated work.

Verify each worker's exact directory before edits and use absolute edit paths.
Keep each worker inside its assigned checkout. Coordinate shared-file changes and
integration yourself. Dispatch the next ready assignment when its dependencies land.
```

For shared-checkout work, assign both workers the same directory and give them distinct editing scopes. Serialize overlapping edits. A single worker needs only one state directory and conversation.

## Start and resume from PowerShell

The supervising agent writes the task contract as a UTF-8 file and uses the wrapper. These variables represent the actual selected paths:

```powershell
$workerScript = Join-Path $repositoryRoot '.agents/skills/codex-to-codex-cli-delegation/scripts/Invoke-CodexAgent.ps1'
& $workerScript -WorkingDirectory $repositoryRoot -PromptFile $contract -StateDirectory $workerState

# After that invocation has completed, send a related assignment or correction.
& $workerScript -WorkingDirectory $repositoryRoot -PromptFile $correction -StateDirectory $workerState -Resume
```

The wrapper reports the session ID, run status, final report, log paths and CLI-reported token usage. A successful process exit starts the supervisor's acceptance review; task completion follows the actual requirements and implementation evidence. Resume retains the worker's saved execution settings.

Each assignment requests a native goal. The supervisor waits while the process runs and resumes the same session when a final response leaves the assignment unfinished. The verified CLI execution path can exit with an active goal, so `/goal` alone supplies goal state while the supervisor supplies cross-process continuation. Phase-progress messages leave the full assignment outstanding until its acceptance criteria are met.

## Recover an interrupted supervising session

```text
Continue the delegation run described in <COORDINATION_RECORD_PATH>.
Read the current worker session.json files and retained reports. Establish which
processes are still running before resuming workers. Preserve active work and use
the saved session IDs for completed workers that need follow-up assignments.
Continue from the remaining work and current filesystem state.
```

Worker session persistence supports recovery. The wrapper runs when invoked and the supervisor drives subsequent assignments; automatic restart after the supervising process exits requires a separate launcher. CLI usage reports expose consumption; this skill currently provides no enforced spending or token ceiling.
