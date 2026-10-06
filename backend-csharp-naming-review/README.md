---
title: Backend C# Naming Review Skill
type: readme
description: Maintainer overview of the backend C# symbol inventory and naming-review ledger skill.
status: active
date created: 2026-09-16
date modified: 2026-09-16
tags: [backend, csharp, naming, agent-skill]
component: [backend, agents]
related:
  - .agents/skills/backend-csharp-naming-review/SKILL.md
code_refs:
  - apps/backend/NamingReview/NamingReview.csproj
  - package.json
---

# Backend C# Naming Review

This skill reviews hand-authored backend C# symbols in deterministic batches and keeps completed reviews in a local SQLite database.

## Prerequisites

- The repository-pinned .NET SDK is available through the backend command wrapper.
- The backend solution restores successfully.
- The current checkout is the repository root when running package commands.

## Commands

```text
pnpm backend:names:capture
pnpm backend:names:batch -- --limit 50
pnpm backend:names:batch -- --project Application --limit 50
pnpm backend:names:batch -- --folder apps/backend/Infrastructure/Competitions --limit 50
pnpm backend:names:batch -- --file apps/backend/Application/Competitions/ContinuityObservation.cs --limit 50
pnpm backend:names:batch -- --include properties,fields --limit 50
pnpm backend:names:record
pnpm backend:names:findings
pnpm backend:names:findings -- --format html --output output/backend/naming-review.html
pnpm backend:names:findings -- --format tsv --output output/backend/naming-review.tsv
pnpm backend:names:findings -- --format md --output output/backend/naming-review.md
```

The batch and default findings commands write JSON to standard output. The record command reads one review object or an array from standard input. The database is `output/backend/csharp-symbol-review.sqlite`.

The inventory stores files, classes, records, interfaces, explicitly declared methods, properties and fields. The `--include properties,fields` option controls which optional member kinds enter a batch for their separate review pass. Capture removes symbols absent from the current source inventory; a Roslyn identity preserves its review when its file moves, while a renamed declaration enters under a new identity.

## Review standard changes

When either source rule changes materially, refresh its copy under `references/` and begin a fresh audit. Remove `output/backend/csharp-symbol-review.sqlite`, then run `pnpm backend:names:capture` to create the current baseline and inventory.
