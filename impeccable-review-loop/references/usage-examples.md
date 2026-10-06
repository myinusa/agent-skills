---
title: "Impeccable Review Loop Usage Examples"
type: "guide"
description: "Ready-to-use prompts for automatic and targeted Impeccable review and remediation runs."
status: "active"
date created: "2026-08-25"
date modified: "2026-08-25"
tags: [codex, impeccable, frontend, examples]
component: [agents, web]
related:
  - .agents/skills/impeccable-review-loop/SKILL.md
  - .agents/skills/impeccable-review-loop/README.md
---

# Usage Examples

## Five-cycle automatic Codex run

```text
/goal Use $impeccable-review-loop across the Foundry frontend.
targets: any
cycles: 5
minimum_findings: 25
implementer: codex
runtime_context: available local application and career states
decision_policy: severity-first, implement every in-scope finding supported by PRODUCT.md and DESIGN.md
```

The baseline inventories the application and records a target manifest. Every cycle implements verified findings and runs a fresh evaluation across the manifest in the current checkout.

## Five-cycle targeted Gemini run

```text
/goal Use $impeccable-review-loop on the squad and tactics workspaces.
targets:
- career/squad
- career/tactics
cycles: 5
minimum_findings: 25
implementer: gemini
gemini_model: gemini-3.7-flash
runtime_context: current active career with a club appointment
```

Gemini receives bounded Direct-mode contracts. Codex owns the development host, implementation review, correction contracts, and browser acceptance.

## One focused page

```text
Use $impeccable-review-loop.
targets:
- career/inbox
feature_trials:
- select and read a message
- empty inbox
- loading and recovery behavior
cycles: 2
minimum_findings: 25
implementer: codex
```

## Source component and live flow

```text
Use $impeccable-review-loop.
targets:
- apps/web/src/features/career-setup/CareerSetup.tsx
- the complete new-career setup flow
cycles: 3
minimum_findings: 25
implementer: codex
runtime_context: application launch state
```

## Explicit browser settings

```text
Use $impeccable-review-loop.
targets:
- career/club
- career/matches
cycles: 3
browser_url: http://127.0.0.1:1420
dev_command: pnpm run dev:web
implementer: codex
```

## Resume a run

```text
/goal Resume $impeccable-review-loop from:
resume_from: .impeccable/review-loop/20260825-143000/state.json
```

The skill confirms the stored configuration and continues from the recorded pass, target, and phase.
