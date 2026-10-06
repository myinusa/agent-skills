---
name: codex-to-codex-cli-delegation
description: Delegate repository work from Codex to resumable Codex CLI workers while retaining orchestration, review and acceptance. Use for substantial implementation, investigation or correction assignments, with optional parallel workers and worktrees.
---

# Codex Delegation

The supervising Codex agent frames the objective, supplies context, delegates, reviews evidence and decides whether another pass is useful. CLI workers perform the repository work, including investigation, implementation decisions, edits and validation within their assigned scope.

Never commit code on your own accord.

Delegate the full requested outcome in one contract when it forms a coherent task. Split work when dependencies, editing overlap or distinct acceptance criteria make separate assignments useful. Use the current checkout by default; separate worktrees are optional. Assign an explicit working directory in either case.

Read [usage examples](references/usage-example.md) for plan handoff, optional parallel workers and interrupted-run recovery.

## Start from a short request

`Use $codex-to-codex-cli-delegation to implement <PLAN_PATH>` is a complete invocation. The supervisor reads the plan and applicable instructions, prepares worker contracts, selects coherent assignments, creates worker state directories, delegates, reviews and sends corrections through completion. Apply the documented model/execution defaults and the user's existing authorization. Take worker counts, worktree assignments and task-specific restrictions from the supplied plan or prompt when specified; otherwise use the current checkout and parallelize only independent editing scopes.

Keep a short coordination record outside the repository with worker state paths, execution handles, assignments, handoffs and remaining dependencies, and report its path. Resolve routine setup from the repository and task context. Ask only for missing information or authority that materially prevents the next action, while continuing independent work. Longer invocation examples are optional customization; the user supplies the task and any exceptions to these defaults.

## Prepare the contract

Create a UTF-8 prompt file outside the repository containing:

- Objective, expected deliverable and relevant plan phases.
- Repository context, exact working directory and owned files or feature boundaries.
- Task-specific requirements, external context and existing user authorization.
- Acceptance criteria, proportionate validation commands and end-of-assignment validation timing.
- A compact final response with `summary`, `changed_files`, `validation`, `risks` and `unresolved`.

The worker also loads repository instructions through Codex. Include transient conversation facts that it needs. Carry explicit prohibitions and supplied tool-bug warnings into the initial contract and relevant correction contracts verbatim. Preserve existing user changes and scope every edit to the assigned directory and task. The wrapper requires directory verification and absolute edit paths on every invocation. A working-directory assignment is an operational boundary; filesystem enforcement comes from the selected sandbox.

Read the assigned requirements, acceptance criteria and dependency sections completely before dispatch. Read large files in bounded consecutive sections and track coverage. Use scoped searches and compact output for discovery; when output is truncated or filtered, retrieve the omitted relevant content before making decisions. Apply the environment's RTK conventions while keeping task requirements intact. Workers read their own relevant implementation files; the supervisor reads the source needed to assess dependencies and review findings.

## Invoke the worker

Use [scripts/Invoke-CodexAgent.ps1](scripts/Invoke-CodexAgent.ps1). PowerShell 7 and an authenticated Codex CLI are required. Resolve the script relative to this skill's directory.

```powershell
& $workerScript -WorkingDirectory $repositoryRoot -PromptFile $contract -StateDirectory $workerState
```

Give each worker its own state directory outside the repository. The wrapper persists its session ID, working directory and execution settings in `session.json`. Each invocation retains its prompt, event log and final report in a separate run directory. The compact returned result identifies these files and includes the worker report and reported token usage.

Resume that worker for a correction or continuation of its current unfinished assignment:

```powershell
& $workerScript -WorkingDirectory $repositoryRoot -PromptFile $correction -StateDirectory $workerState -Resume
```

Resume uses that exact saved session. Keep the session through correction and acceptance of its current assignment. Start a fresh state directory when the same Alpha or Bravo lane begins a materially new package, carrying a concise handoff with accepted behavior, relevant decisions, current dependencies and the unchanged worktree path. This keeps the lane and filesystem continuity while bounding conversation history. Keep saved state and run files through acceptance so interrupted orchestration can recover its assignments. If a process is interrupted, establish that it has exited before resuming the session. A surviving `worker.lock` requires checking its recorded process before removing that lock.

The existing delegation defaults are Luna, high reasoning and fast service tier. `-Model Sol` selects Sol; a full model ID is also accepted. `-ReasoningEffort` and `-ServiceTier` are configurable on initial invocation. Resumes retain the saved settings. Luna suits bounded packages with clear acceptance. Sol suits packages that combine several shared authorities, schemas, generated contracts and runtime consumers, or a replacement pass after repeated incomplete reasoning.

`-PermissionMode FullAccess` is the default and passes `--dangerously-bypass-approvals-and-sandbox`, matching the original Grok wrapper. `ReadOnly` and `WorkspaceWrite` are explicit alternatives using noninteractive approval policy. Select permissions within the supervising session's authorization. Worker subagents are optional through `-UseSubagents`; ordinary workers implement their own assignment.

## Wait and coordinate

The wrapper runs synchronously. Use the supervising tool's background execution/session handle for long calls and retain that handle until completion. For parallel work, launch a separate invocation and state directory per independent worker. Shared-checkout work needs separate editing scopes; serialize changes to shared methods and generated sources. Create worktrees only when the assignment calls for isolation.

Let workers complete substantial assignments. Routine monitoring uses the wrapper execution handles and compact completion result. Read detailed event logs after an unexpected exit, a genuine activity stall, or a review finding that needs command-level evidence. CLI worker status comes from its wrapper handle and saved state; collaboration-agent tools apply to agents launched through the collaboration system. Keep progress updates compact. Maintain only the worker state paths, execution handles, assignments and dependencies needed to resume coordination. The supervisor continues through integration and follow-up assignments until the authorized outcome is complete.

Each invocation requests a native goal for the complete assigned scope, and the wrapper enables goal tools. On resume, continue the existing unfinished goal. A fresh session creates the goal for its new package. Include explicit user-supplied budgets when present. Keep the assignment bounded by its allocated phases and dependencies.

At a cross-worktree dependency handoff, transfer an authorized commit when commit authority exists. Otherwise create one scoped source patch with an explicit list of changed, added and deleted files. Transfer the accepted dependency surfaces required by the receiving package. Full working-state synchronization belongs to packages that genuinely depend on the complete integrated base.

In the verified Codex CLI 0.154.0 execution path, a final response ended `codex exec` while the native goal remained active. The supervisor supplies continuation through `-Resume` when the assignment remains unfinished. Goal persistence and process continuation are separate responsibilities.

Progress messages and individual `turn.completed` events can occur while work continues. Wait for the execution handle to report process exit before treating the invocation as finished or resuming its session. The wrapper's `completed` status describes successful process completion; acceptance requires checking the entire assignment against the resulting work. If the worker exits after partial progress, identify the remaining work and resume that same session automatically. Investigate errors or stalled progress from retained evidence. Respect user pauses, usage/budget limits and unresolved user-dependent decisions. Quiet periods alone are insufficient evidence that a worker has stopped.

## Accept the result

Prioritize implementation across the full assignment. Complete a coherent implementation batch before the first fast build. Treat each build result as one diagnostic batch: address its complete reported error set before the next build, and let each rerun confirm a completed correction batch. Run generation after its source contract shape is stable, or earlier when the generated output is required for the remaining implementation. Schedule test suites and broad validation once the package is ready for acceptance. Include this timing policy in worker contracts, with any explicit task-specific requirements.

The supervisor coordinates heavy checks on the shared machine, allowing one worker at a time to run them. A worker ready for heavy validation reports that readiness and waits for the supervisor's scheduled validation assignment. Run the broad package chain once at acceptance. Reuse sufficient existing results during review, rerun the checks affected by relevant corrections, and perform the required integrated checks at final completion. Keep assignments substantial so phase-by-phase dispatch does not recreate repeated validation.

Inspect the resulting files and behavior against the contract. Use the worker's report as navigation and its existing validation evidence where sufficient. Perform focused review of requirements and affected integration boundaries. For every Luna (`gpt-5.6-luna`) assignment, the supervisor must perform at least one review pass over the actual deliverable before acceptance, including when the worker reports success and validation passes. Check requirement coverage, implementation correctness and affected integration boundaries. Apply a higher explicitly requested review count when present; concrete findings determine further correction passes. Reuse sufficient validation evidence under the timing policy above.

When gaps remain, send a correction through the same worker session with the expected result, observed evidence and required correction. Keep implementation ownership with the worker and reassess the affected result. Continue while passes make concrete progress; investigate repeated failures and surface decisions or external conditions requiring user input. Unrelated improvement ideas stay outside the assignment.

Session continuity preserves conversation context, while the filesystem remains the current implementation authority. A replacement worker receives the remaining scope, relevant decisions and current artifacts in a fresh contract.

Authorization from the user and supervising session governs commits, integration and external actions. Execute already-authorized handoffs as part of completion. Report invocation failures, unexpected changes and unresolved work accurately. Return the delivered outcome and material remaining limits.
