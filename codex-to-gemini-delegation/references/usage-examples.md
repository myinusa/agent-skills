---
title: "Gemini Delegation Usage Examples"
type: "guide"
description: "Ready-to-use prompts for delegating focused tasks from Codex to Gemini."
status: "active"
date created: "2026-08-25"
date modified: "2026-08-25"
tags: [codex, gemini, delegation]
component: [agents]
---

# Gemini Delegation Usage Examples

## Lowest-friction approach

Invoke the skill and describe the outcome in one sentence. Codex uses Gemini 3.7 Flash Medium, runs it in the current checkout, and handles the task contract and review.

```text
$codex-to-gemini-delegation use Gemini for this: investigate why checkout submission can create duplicate orders and fix the responsible code path.
```

Another short form:

```text
$codex-to-gemini-delegation ask Gemini to review the authentication flow for security and correctness issues.
```

Every implementation request includes a Codex acceptance loop. Codex reviews the result, identifies remaining gaps, and sends focused correction passes to Gemini until the stated acceptance criteria are verified.

```text
$codex-to-gemini-delegation have Gemini implement the invoice export. Assess the result against the existing requirements, return every incomplete item to Gemini as a correction pass, and continue until the acceptance criteria are satisfied.
```

## Isolated worktree

Ask for worktree mode when the task benefits from a separate working copy.

```text
$codex-to-gemini-delegation use Gemini in an isolated worktree to implement the new customer export endpoint.
```

## Read-only review

```text
$codex-to-gemini-delegation ask Gemini to review apps/backend/Features/Billing for correctness issues. Keep the task read-only and return findings by severity with file and line references.
```

## Focused implementation

```text
$codex-to-gemini-delegation have Gemini add pagination to the customer list endpoint. Keep changes within apps/backend/Features/Customers and validate with the existing backend build command.
```

## Investigation with a specific deliverable

```text
$codex-to-gemini-delegation ask Gemini to trace the source of the intermittent null reference in invoice generation. Return the likely root cause, supporting evidence, and the smallest suitable fix.
```

## Second opinion

```text
$codex-to-gemini-delegation ask Gemini for a read-only second opinion on this implementation plan. Identify missing requirements, risky assumptions, and simpler alternatives.
```

## Use stronger reasoning

Select Gemini 3.7 Flash High for tasks driven by difficult reasoning, mathematics, language interpretation, or instruction following.

```text
$codex-to-gemini-delegation use gemini-3.7-flash-high to analyze the concurrency rules in the order-processing workflow and produce a concrete race-condition timeline.
```

## Use Gemini 3.1 Pro for data-heavy work

```text
$codex-to-gemini-delegation use gemini-3.1-pro to analyze the supplied transaction dataset and identify the fields most predictive of reconciliation failures.
```

## Add useful boundaries

Short prompts work well. Add these details when scope or acceptance criteria matter:

- target files or directories
- read-only or editing scope
- expected deliverable
- validation command
- model choice

```text
$codex-to-gemini-delegation use Gemini to update only src/pricing/calculator.ts. Correct the tier boundary calculation, preserve the public API, run the existing package build, and return a concise summary of the change.
```

Direct mode uses the current checkout and includes its uncommitted files. Worktree mode starts from a selected commit in a clean detached worktree.
