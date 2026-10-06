---
title: "Impeccable Review Loop Report Schema"
type: "reference"
description: "Required frontmatter, checkpoint state, and content fields for each Impeccable review-loop evaluation artifact."
status: "active"
date created: "2026-08-25"
date modified: "2026-08-25"
tags: [impeccable, audit, report, findings]
component: [agents, web]
related:
  - .agents/skills/impeccable-review-loop/SKILL.md
  - docs/reference/2025-10-07-yaml-front-matter-quick-reference.md
---

# Report Schema

Each evaluation pass maintains one date-prefixed audit document with valid project frontmatter. Create it as `draft` at pass start and set it to `completed` after the manifest finishes.

## Frontmatter fields

Use:

- `title`: scope and pass name
- `type: audit`
- `description`: one-sentence scope and outcome
- `status`: `draft` during execution, then `completed`
- `date created` and `date modified`
- `tags: [impeccable, frontend, audit, review-loop]`
- `component`: concrete frontend surface or `[frontend]` for `targets: any`
- `scope`: target manifest summary
- `auditor: Codex with Impeccable`
- `depth: comprehensive`
- `verdict`: current pass verdict
- `review_pass`: `0` for baseline, then `1` through `N`
- `phase`: `baseline` or `cycle-01` through `cycle-N`
- `implementation_status`: `pending`, `partial`, or `complete`
- `skill: impeccable-review-loop`
- `code_refs`: inspected and changed source paths
- `evidence_refs`: browser screenshots, videos, diffs, and runtime artifacts
- `related`: preceding pass and relevant product or design documents

## Body sections

Use this order:

1. Run configuration and checkpoint
2. Target manifest and coverage
3. Feature trials
4. Impeccable audit reports
5. Impeccable critique reports
6. Consolidated finding ledger
7. Implementation batch and provider result
8. Browser acceptance evidence
9. Score and finding delta
10. Unexpected behavior
11. Remaining work or completion state

Append each verified browser finding during exploration. Append audit and critique subreports as each target pair completes.

## Finding ledger columns

| Field       | Meaning                                                                                       |
| ----------- | --------------------------------------------------------------------------------------------- |
| ID          | Run-stable root finding identifier                                                            |
| First seen  | Baseline or cycle where the finding opened                                                    |
| Sources     | Audit, critique, detector, browser, accessibility, performance, or feature-trial evidence     |
| Severity    | P0, P1, P2, or P3                                                                              |
| Category    | Accessibility, performance, theming, responsive, integrity, design, functional, UX, or content |
| Target      | Route, component, state, and source location                                                  |
| Finding     | Specific reproducible observed behavior                                                       |
| Impact      | Concrete effect on the player                                                                 |
| Correction  | Root correction with enough detail for an implementer                                        |
| Evidence    | Screenshot, video, snapshot, diff, console, detector, source, trace, or runtime reference     |
| Status      | Open, implemented, verified, regressed, or decision-required                                  |

## Checkpoint state

`state.json` records:

- run identifier and resolved configuration
- target mode and complete manifest
- active pass, target, and phase
- completed target pairs and cycles
- development server and browser session ownership
- pass artifact and evidence paths
- finding ledger identifiers and statuses
- implementation provider and latest worker result
- pending decision, failure, or next action

## Delta rules

Compare each cycle with the immediately preceding evaluation. Keep score trends keyed by target and preserve distinct audit and critique scales. For critique results with different applicable maxima, show every denominator and compare percentage movement.

Finding counts distinguish newly opened, carried, resolved, and regressed items. A root correction may resolve several related symptoms; retain their evidence under the canonical run-stable ID.
