---
title: "Crack Tech Debt Audit Usage Examples"
type: "guide"
description: "Prompt examples for explicitly invoking the crack-tech-debt-audit skill."
status: "active"
date created: "2026-08-12"
date modified: "2026-08-12"
tags: [skills, audit, technical-debt, examples]
component: [agents, docs]
related:
  - .codex/skills/crack-tech-debt-audit/SKILL.md
---

# Crack Tech Debt Audit Usage Examples

Use this skill only by explicitly naming `crack-tech-debt-audit`.

## Full Repository Audit

```text
Use crack-tech-debt-audit on this repo in full-repo mode.
```

Expected result: creates a new crack audit artifact (Foundry default: `docs/audits/YYYY-MM/YYYY-MM-DD-<scope>-crack-tech-debt-audit.md`) with a full repository technical-debt and architecture audit that names exact files, folders, patterns, and consequences.

## Scoped Module Audit

```text
Use crack-tech-debt-audit on apps/backend in scoped-module mode.
```

Expected result: audits only the requested scope and makes the scope clear in the report metadata.

## Repeat Run

```text
Use crack-tech-debt-audit in repeat-run mode and update the existing crack audit artifact for this scope.
```

Expected result: reads the existing audit, verifies stale findings, marks resolved items only after checking evidence, and tags new findings.

## Triage Only

```text
Use crack-tech-debt-audit on packages/ui in triage-top-10 mode.
```

Expected result: produces up to the ten highest-impact findings only.

## Delta Audit

```text
Use crack-tech-debt-audit in delta-since-commit mode for changes since main.
```

Expected result: focuses on debt introduced or exposed by recent changes while still checking nearby context before judging.

## Large Repository Audit

```text
Use crack-tech-debt-audit on this repo in full-repo mode. Use multiple read-only agents by module if the runtime supports it, then synthesize and dedupe centrally.
```

Expected result: parallel module-level findings are merged into one ranked audit.

## Direct Findings Prompt

```text
Use crack-tech-debt-audit on apps/web in scoped-module mode. Do not compress findings. Name the exact files, repeated patterns, and consequences, and do not pad the report with plans or checklists.
```

Expected result: the audit remains read-only and reports concrete structural problems directly.

## What Should Not Trigger This Skill

```text
Review this pull request.
```

Use a normal code-review workflow instead.

```text
Fix the lint errors in apps/web.
```

Use a lint or implementation workflow instead.

```text
Make a plan for this feature.
```

Use a planning workflow instead.
