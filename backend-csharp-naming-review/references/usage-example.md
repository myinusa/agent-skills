---
title: Backend C# Naming Review Usage Examples
type: guide
description: Examples for capturing, batching, recording and reporting backend C# naming reviews.
status: active
date created: 2026-09-16
date modified: 2026-09-16
tags: [backend, csharp, naming, usage]
component: [backend, agents]
related:
  - .agents/skills/backend-csharp-naming-review/SKILL.md
---

# Usage examples

## Default batch

```powershell
pnpm backend:names:capture
pnpm backend:names:batch -- --limit 50
```

The output contains a `symbols` array and `remaining_unreviewed` count. Review each symbol with its source context before recording a result.

## Targeted batches

```powershell
pnpm backend:names:batch -- --project Application --limit 10
pnpm backend:names:batch -- --folder apps/backend/Infrastructure/Competitions --limit 10
pnpm backend:names:batch -- --file apps/backend/Application/Competitions/ContinuityObservation.cs --limit 10
pnpm backend:names:batch -- --include properties,fields --limit 50
```

Project, folder and file values are repository-relative where they identify paths. Batch ordering is stable by project, path, line, kind, name and symbol key.

## Record accepted names

```powershell
@'
{
  "symbol_key": "<symbol_key from batch output>",
  "status": "accepted",
  "meaning": "<plain statement of the represented fact or behaviour>",
  "reason": "<evidence from the declaration and its callers>",
  "proposals": []
}
'@ | pnpm backend:names:record
```

## Record a name awaiting a decision

```json
{
  "symbol_key": "<symbol_key from batch output>",
  "status": "awaiting-decision",
  "meaning": "<plain statement of the represented fact or behaviour>",
  "reason": "<evidence from the declaration, containing type and callers>",
  "proposals": [
    {
      "name": "<proposed name from the review>",
      "reason": "<individual reasoning for this proposal>"
    },
    {
      "name": "<second proposed name from the review>",
      "reason": "<individual reasoning for this proposal>"
    }
  ]
}
```

Pipe that object or an array of objects to `pnpm backend:names:record`. The command validates the symbol identity, status, meaning, evidence and proposal count before one SQLite transaction records the reviews.

## Resolve an awaiting decision

Keeping the current name records the same `symbol_key` as `accepted` with the confirmed meaning, reason and an empty `proposals` array.

Choosing a proposed name starts a separate code-change task. Run capture after that rename. The previous symbol leaves the inventory and the replacement enters the next batch as unreviewed.

## Findings reports

```powershell
pnpm backend:names:findings
pnpm backend:names:findings -- --format html --output output/backend/naming-review.html
pnpm backend:names:findings -- --format tsv --output output/backend/naming-review.tsv
pnpm backend:names:findings -- --format md --output output/backend/naming-review.md
```

HTML and Markdown group every proposal beneath its symbol. TSV repeats symbol details on each proposal row.
