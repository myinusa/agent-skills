---
name: fallow-dupes-batch-remediator
description: Deterministic duplicate-remediation loop for Foundry source scopes from a fresh Fallow dupes report and a family-based worklist. Use when you want the agent to regenerate current duplication artifacts through scripts/tooling/fallow-app-dupes/cli.py, select the next duplicate families for typescript/csharp/python, and consolidate selected families when they exist. Success output is a fixed/skipped duplicate-family summary with changed files and Fallow verification results.
---

# Fallow Dupes Batch Remediator

Use this skill to run the repo-owned source dupes wrapper fresh, build a current duplicate-family worklist, and remediate the next deterministic batch.
See [Usage Example](references/usage-example.md) for invocation patterns.

## Routing Boundaries

Use this skill when:
- you need a fresh duplication report for `typescript`, `csharp`, or `python`
- you want a bounded batch of duplicate families selected outside the model
- the expected fix is actual consolidation, shared helper extraction, or shared-module cleanup

Use a reporting workflow for report-only inspection, dead-code cleanup, runtime debugging, or broad review.

## Inputs

Required:
- source scope: `typescript`, `csharp`, or `python`
- batch size

Optional:
- output directory override
- log level override

Regenerate the current artifacts first. Use the stable `current-*` files from the new run.
Structural extraction is normal remediation work here.

## Workflow

### 1. Select the batch

Run the wrapper fresh and build the current worklist through the skill helper.

```bash
python .codex/skills/fallow-dupes-batch-remediator/scripts/run_batch.py typescript --limit "${BATCH_SIZE}"
```

This writes:
- `output/fallow/app-dupes/<scope>/current-report.json`
- `output/fallow/app-dupes/<scope>/current-report.txt`
- `output/fallow/app-dupes/<scope>/current-manifest.json`
- `output/fallow/app-dupes/<scope>/current-worklist.jsonl`
- `output/fallow/app-dupes/<scope>/current-selection.json`

Worklist items are duplicate families. One family can cover multiple clone groups and multiple files.

### 2. Fix the selected families

- Work in worklist order.
- Treat shared helper extraction, shared modules, utility relocation, and parameterized consolidation as the default path.
- Remove the duplication at the real boundary.
Use consolidation for real duplicate families.
Skip only when the duplicate family encodes materially different behaviour and a shared abstraction would be false.

Structural change alone is outside the skip criteria for this skill.

### 3. Verify the edits

- Re-run the wrapper on the same source scope.
- Confirm the fixed family IDs are absent from the new worklist or current report.
- Record any skipped family IDs with concrete reasons.

## Output Contract

Return:
- fixed family IDs
- skipped family IDs with brief reasons
- changed file paths
- verification command(s) and result
- residual risk or assumptions

If any batch item was skipped, the final response must include a dedicated `Skipped` section with each exact family ID and a concrete reason.

## Failure Modes

- Reusing an old report
- Treating cross-file extraction as too structural for the batch
- Fixing only one group inside a family and leaving the family alive elsewhere
- Skipping verification after the refactor
