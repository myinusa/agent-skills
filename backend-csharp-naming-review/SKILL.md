---
name: backend-csharp-naming-review
description: Review backend C# symbol names in source context, record accepted or awaiting-decision results in the repository SQLite ledger, and present naming proposals.
---

# Backend C# Naming Review

Use this skill for the repository's backend C# naming inventory and durable review ledger. The executable captures current production symbols and stores review records in `output/backend/csharp-symbol-review.sqlite`.

Before any review or proposal work, read these references in full:

- [Domain-led naming and direct implementation](references/domain-led-naming-and-direct-implementation.md)
- [Avoid invented process abstractions](references/avoid-invented-process-abstractions.md)

## Workflow

1. Capture the current inventory with `pnpm backend:names:capture`.
2. Request the next batch with `pnpm backend:names:batch -- --limit 50`.
3. Review each returned symbol in its declaration, containing type, nearby members, direct callers and consumers. Trace storage, protocol and generated surfaces when the name crosses those boundaries.
4. Record each review through `pnpm backend:names:record`, using `accepted` when the current name clearly represents its meaning and `awaiting-decision` when user judgement is required.
5. For `awaiting-decision`, provide one to four proposals. Every proposal has its own `name` and `reason`. Accepted reviews use an empty `proposals` array.
6. Present the batch count, accepted symbols, awaiting decisions and proposal reasoning. Calculate the final remaining count as `remaining_unreviewed` from the batch output minus the reviews recorded for that batch; symbols left unrecorded because required context was unavailable remain in that count.

A symbol with unavailable required context remains unreviewed and is reported to the user. Code changes follow a separate user-directed task after the findings are reviewed.

When the user keeps a current name, record the same symbol as `accepted` with an empty proposals array. When the user chooses a replacement, carry out the rename only through a separately authorized code task. The next capture removes the previous symbol identity and adds the replacement as unreviewed.

## Inputs

The default batch is 50 symbols. Use a positive `--limit` for another size. Scope a batch with `--project`, `--folder` or `--file`. Add `--include properties,fields` for the optional member pass. Use `pnpm backend:names:findings` to list recorded awaiting decisions.

For review JSON shapes and recording examples, read [usage examples](references/usage-example.md).

Findings reports use `--format html|tsv|md` with `--output <path>`. HTML and Markdown group proposals under each symbol; TSV repeats symbol details once per proposal.
