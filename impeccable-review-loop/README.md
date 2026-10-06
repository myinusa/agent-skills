---
title: "Impeccable Review Loop"
type: "readme"
description: "Configurable Impeccable audit, critique, implementation, and live browser re-evaluation cycles for Foundry UI work."
status: "active"
date created: "2026-08-25"
date modified: "2026-08-25"
tags: [codex, impeccable, frontend, audit, browser]
component: [agents, web]
related:
  - .agents/skills/impeccable-review-loop/SKILL.md
  - .agents/skills/impeccable-review-loop/references/usage-examples.md
---

# Impeccable Review Loop

This project-local Codex skill runs a scored frontend improvement loop across automatically discovered or explicitly selected Foundry surfaces. It combines Impeccable's technical audit, design critique, live `agent-browser` feature trials, and current-checkout implementation by Codex subagents or Gemini.

## Default run

```text
$impeccable-review-loop
targets: any
cycles: 5
minimum_findings: 25
implementer: codex
runtime_context: available local application and career states
```

`targets: any` inventories the route registry, reachable contextual routes, source-owned frontend surfaces, and live navigation. Every reachable manifest entry receives the audit-then-critique pair in each evaluation. Explicit targets accept source paths, exact route identifiers, live URLs, page or component names, and user flows.

The run starts with a baseline evaluation. Each cycle implements the current verified findings and creates a fresh post-change evaluation. Five cycles produce one baseline report and five cycle reports.

Reports live in `docs/audits/YYYY-MM/`. Browser evidence and resumable state live under `.impeccable/review-loop/<run-id>/`. Each report carries the target manifest, score deltas, stable finding ledger, implementation outcomes, feature trials, and evidence links.

Foundry defaults:

- development command: `pnpm run dev:web`
- browser URL: `http://127.0.0.1:1420`
- viewport class: desktop from `960x680` upward, with `1440x900` as the primary review size
- runtime context: available local application and career states
- implementation provider: Codex native subagents
- execution location: current checkout

For a durable multi-turn run, invoke the skill through `/goal` with the same parameters. See [usage examples](references/usage-examples.md).
