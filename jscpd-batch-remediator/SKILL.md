---
name: jscpd-batch-remediator
description: Deterministic duplicate-remediation loop for Meridian Python or backend C# code from a fresh jscpd report and a cluster-based worklist. Use when you want the agent to regenerate the current jscpd artifacts through the repo-owned wrapper for the requested profile, select the next duplicate clusters, and actually consolidate them instead of deferring because the fix crosses files. Do not use for raw lint cleanup, one-off runtime debugging, or repo-wide code review with no remediation intent. Success output is a fixed/skipped duplicate-cluster summary with changed files and jscpd verification results.
---

# JSCPD Batch Remediator

Use this skill to run the repo-owned `jscpd` wrapper fresh, build a current duplicate-cluster worklist, and remediate the next deterministic batch.
See [Usage Example](references/usage-example.md) for invocation patterns.

## Routing Boundaries

Use this skill when:
- you need a fresh duplicate report for Meridian Python or backend C# code
- you want a bounded batch of clone clusters selected outside the model
- the expected fix is actual consolidation, helper extraction, or shared-module cleanup

Do not use this skill when:
- the task is just to inspect a report without making code changes
- the input is not `jscpd` duplicate data
- the request is mainly runtime debugging, test repair, or unrelated refactoring

Negative examples:
- "Tell me whether this script is fast"
- "Run every Python quality tool in the repo"
- "Review these files for style issues"

## Inputs

Required:
- profile (`python` or `csharp`)
- target scope or explicit path list
- batch size

Optional:
- output directory override
- explicit path mode via repeated `--path`
- log level override

Hard constraint: always regenerate the current artifacts first. Do not reuse stale dated reports from `output/jscpd/`.
Hard constraint: structural extraction is normal remediation work here. Do not skip a cluster just because the fix spans multiple files, needs a helper, or changes local module boundaries.

## Workflow

### 1. Select the batch

Run the wrapper fresh and build the current worklist through the skill helper.

```bash
python3 .codex/skills/jscpd-batch-remediator/scripts/run_batch.py --profile "${PROFILE}" "${TARGET_SCOPE}" --limit "${BATCH_SIZE}"
```

This writes:
- `output/<profile-dir>/<current-prefix>-report.json`
- `output/<profile-dir>/<current-prefix>-report.html`
- `output/<profile-dir>/<current-prefix>-manifest.json`
- `output/<profile-dir>/<current-prefix>-worklist.jsonl`
- `output/<profile-dir>/<current-prefix>-selection.json`

Worklist items are clone clusters, not raw pair rows. One cluster can cover multiple duplicate pairs and multiple files.

### 2. Fix the selected clusters

- Work in worklist order.
- Treat helper extraction, shared dataclasses, utility modules, and parameterized consolidation as the default path.
- Remove the duplication at the real boundary instead of papering over it with local micro-variations.
- Do not use comments, suppression, or config churn as a substitute for consolidation.
- Skip only when the duplicate block encodes materially different behaviour and a shared abstraction would be false.

Structural-change alone is never a valid skip reason for this skill.

### 3. Verify the edits

- Re-run the wrapper on the touched scope or touched files.
- Confirm the fixed cluster IDs are absent from the new worklist or report.
- Record any skipped cluster IDs with concrete reasons.

## Output Contract

Return:
- fixed cluster IDs
- skipped cluster IDs with brief reasons
- changed file paths
- verification command(s) and result
- residual risk or assumptions

If any batch item was skipped, the final response must include a dedicated `Skipped` section with each exact cluster ID and a concrete reason.

## Failure Modes

- Reusing an old report instead of regenerating `current-jscpd-*` artifacts
- Treating cross-file extraction as "too structural" for the batch
- Fixing only one side of a clone pair and leaving the cluster alive elsewhere
- Skipping verification after the refactor
