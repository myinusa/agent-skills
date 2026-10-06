---
title: "Impeccable Review Loop Workflow"
type: "runbook"
description: "Execution sequence for the bounded Impeccable evaluation and remediation loop."
status: "active"
date created: "2026-08-25"
date modified: "2026-08-25"
tags: [impeccable, audit, critique, agent-browser, remediation]
component: [agents, web]
related:
  - .agents/skills/impeccable-review-loop/SKILL.md
  - .agents/skills/impeccable-review-loop/references/report-schema.md
  - .codex/skills/codex-to-gemini-delegation/SKILL.md
---

# Workflow

## 1. Establish the run

Read the applicable repository instructions, `PRODUCT.md`, `DESIGN.md`, the installed Impeccable `SKILL.md`, and its `audit.md` and `critique.md` references. Run Impeccable's context script once with the primary resolved target.

Create a run identifier from the date and time and use these locations:

- reports: `docs/audits/YYYY-MM/YYYY-MM-DD-impeccable-review-loop-<scope>-<run-id>-<pass>.md`
- evidence and state: `.impeccable/review-loop/<run-id>/`
- state checkpoint: `.impeccable/review-loop/<run-id>/state.json`
- pass names: `baseline`, then `cycle-01` through `cycle-N`

Write `state.json` after configuration, target discovery, each evaluation pair, implementation, browser acceptance, and report completion. A resumed run reads this checkpoint and the active pass artifact, confirms the configuration, and continues from the recorded phase.

### Explicit targets

Resolve each supplied target from source and live evidence. Accepted forms include source files or directories, exact route identifiers, live URLs, user-visible page or component names, and coherent flows. Record the concrete source path, route identifier or entry interaction, live surface, required runtime context, and feature trials. Preserve input order.

### `targets: any`

Build a target manifest from the application's actual route registry, route owners and loaders, source feature entry points, and live navigation. Include primary routes, reachable contextual routes, and interactive surfaces represented by a coherent user flow. Record gated routes with their required context and observed reachability signal.

Every reachable manifest entry receives the complete audit-then-critique pair during the baseline and every post-change evaluation. Contextual variants use representative entities and states supported by the available runtime. The manifest defines the scope and prevents route names, URLs, or feature states from being inferred from convention.

## 2. Start the live surface

Load the installed CLI guidance once:

```powershell
agent-browser skills get core --full
agent-browser skills get dogfood --full
```

Probe `browser_url` and its readiness endpoint. For Foundry, readiness means `GET /__foundry/host-context` returns `transportReady: true`.

When the host is absent, start `dev_command` as a background terminal process, retain its session identifier, and wait for `FOUNDRY_BROWSER_READY`. When the configured port already serves Foundry, reuse it and record pre-existing ownership.

Create one dedicated visible browser session and retain its name for the whole run:

```powershell
agent-browser --session <run-session> --headed open http://127.0.0.1:1420
agent-browser --session <run-session> wait --load networkidle
agent-browser --session <run-session> snapshot -i
```

Use snapshot references or semantic locators for interactions. Refresh the snapshot after navigation, state changes, and rerenders. Use targeted waits for expected text, element, state, or network-idle completion.

Inspect the loaded application state before evaluation. Reuse the named runtime context when supplied. Record unavailable contexts as gated manifest entries with the exact observed reason.

## 3. Execute one evaluation pass

Create the dated pass artifact with `status: draft`, write its path to `state.json`, and append verified findings while the pass runs. Finalize the frontmatter and completion sections after the entire target manifest finishes.

### Browser exploration and feature trials

Apply the installed agent-browser `dogfood` workflow as the browser-only exploration method. Use explicit `feature_trials` first, then cover each target's primary user action and relevant navigation, loading, empty, populated, success, error, gated, boundary, and recovery states supported by the runtime.

For each target:

- capture an initial annotated screenshot and interactive snapshot
- exercise realistic user journeys through semantic locators or fresh snapshot references
- inspect page errors, console output, network requests when relevant, `a11y --json`, and `vitals --json`
- verify each browser issue with a second reproduction before adding it to the ledger
- capture one annotated screenshot for a static issue
- capture a paced repro video plus step screenshots for an interactive issue
- append the finding and evidence paths to the pass artifact immediately

Use HAR, trace, profiler, or React render capture when the observed issue calls for that evidence. Inspect visual artifacts directly with the available image-viewing tool.

### Per-target Impeccable pair

Process manifest entries sequentially. Each entry completes the following pair before the next entry begins.

#### Impeccable audit

Run one complete `$impeccable audit <target>` agent command against the resolved source and live surface. Capture its five dimension scores, P0-P3 findings, implementation-integrity verdict, positive findings, and recommendations. Finish the audit section before critique begins.

#### Impeccable critique

Run one complete `$impeccable critique <target>` agent command after audit. Preserve its isolated Assessment A and Assessment B, detector execution, browser evidence, provenance line, critique snapshot, trend read, and cleanup accounting.

The wrapper invocation supplies permission for Assessment A and Assessment B subagents. Spawn both according to the critique reference. Each assessment uses a fresh tab in the dedicated agent-browser session.

Use agent-browser's mutable `eval` surface for the critique overlay flow: preflight page mutation, start Impeccable's `live-server.mjs --background` helper, inject the reported `detect.js` URL, collect `impeccable` console messages, and stop the helper. Record the exact fallback signal when application policy prevents injection.

The configured `decision_policy` supplies routine priority, scope, and established-design answers. Preserve each targeted critique question followed by its policy-derived answer in the pass artifact, then produce the action summary. The outer loop owns the final chat response. A question requiring new product truth, factual copy, or visual direction creates a durable user-decision checkpoint.

Run Impeccable's slug, snapshot, and trend persistence for each concrete target. Keep each target's audit and critique scores distinct.

### Consolidate the ledger

Merge audit, critique, detector, and browser-trial evidence into one ledger. Assign each root finding a run-stable identifier such as `IMP-001` when it first appears and preserve that identifier through every cycle.

Each finding carries:

- origin evidence and first-seen pass
- severity and category
- target, route or state, source location, and browser evidence
- observed behavior and user impact
- recommended root correction
- acceptance evidence
- status: `open`, `implemented`, `verified`, `regressed`, or `decision-required`

Consolidate duplicate symptoms under one canonical finding and list every contributing source. Continue through the complete manifest and defined feature trials after reaching `minimum_findings`. When exhaustive genuine coverage produces fewer findings, record the actual count and coverage evidence.

## 4. Implement the current findings

Build a severity-first batch from every open finding whose correction follows from repository and browser evidence. Group symptoms that share one root correction. Preserve each finding ID in the worker contract and acceptance review.

### Codex provider

Read every allowed file before delegation. Spawn up to two implementation subagents with disjoint file ownership. Each contract contains the objective, finding IDs, allowed paths, evidence, existing user-owned content, constraints, acceptance criteria, and validation commands. Every agent edits the shared current checkout. The parent reviews each allowed file after return and owns integration and browser acceptance.

### Gemini provider

Read every allowed file before delegation, then read the installed `$codex-to-gemini-delegation` skill and any applicable product context supplied by the repository. Create a UTF-8 task contract outside the repository and invoke `Invoke-GeminiAgent.ps1` in Direct mode against the repository root with the selected model alias.

The contract includes objective, deliverable, allowed paths, constraints, finding IDs, evidence, acceptance criteria, validation, and the response fields `summary`, `changed_files`, `validation`, `risks`, and `unresolved`.

Send sequential contracts for overlapping file ownership. Codex reviews the actual files and browser behavior after every pass. Two unchanged correction passes finish the batch with the unresolved finding IDs recorded.

## 5. Verify and re-evaluate

Run the proportionate frontend build or type check for changed UI code. Re-run affected browser flows in the same session and confirm every acceptance condition.

For each changed visual state, capture a matched baseline and after screenshot at the same viewport and runtime state, then create a visual diff:

```powershell
agent-browser --session <run-session> diff screenshot --baseline <before.png> --output <diff.png> --full
```

Refresh snapshots, inspect snapshot diffs, console output, page errors, accessibility results, and performance evidence relevant to the change. Update finding statuses and `state.json`.

Execute the next full evaluation pass across the manifest and write its cycle artifact. Compare with the preceding pass:

- opened, carried, resolved, and regressed finding counts
- audit score delta per target
- critique score delta per target with every denominator preserved
- browser and feature-trial outcomes
- changed files and implementation provider

Repeat implementation and full re-evaluation through `cycle-N`.

## 6. Finish and clean up

Close the dedicated browser session:

```powershell
agent-browser --session <run-session> close
```

Stop the development process through its retained terminal session when this run started it. Leave a pre-existing development process running. Remove temporary Gemini contracts after review. Keep reports, state, screenshots, videos, and diagnostic evidence.

The final handoff gives report paths, the target manifest, score trends, finding movement, changed files, validation, remaining findings, decision checkpoints, and unexpected behavior.
