---
name: impeccable-review-loop
description: Run a configurable frontend improvement loop with sequential Impeccable audit and critique commands, live agent-browser feature trials, durable findings reports, and Codex or Gemini implementation. Use for repeated UI evaluation and remediation across explicit targets or an automatically discovered application scope.
---

# Impeccable Review Loop

Run a baseline evaluation, then repeat implementation and full re-evaluation for the configured number of cycles. Each evaluation completes Impeccable `audit` before Impeccable `critique` and maintains a dated Markdown audit artifact.

Read [workflow](references/workflow.md) before every run. Read [report schema](references/report-schema.md) before creating the baseline artifact. Read [usage examples](references/usage-examples.md) for invocation and resume guidance.

## Inputs

Resolve these values from the invocation:

- `targets`: `any` or a list containing at least one source path, route identifier, live URL, page, component, or user flow; default `any`
- `cycles`: implementation and re-evaluation cycles; default `5`
- `minimum_findings`: minimum combined unique findings sought during each evaluation; default `25`
- `feature_trials`: optional user journeys, states, or features that receive explicit browser coverage
- `implementer`: `codex` or `gemini`; default `codex`
- `gemini_model`: default `gemini-3.7-flash` with the Gemini implementer
- `browser_url`: default `http://127.0.0.1:1420` for Foundry
- `dev_command`: default `pnpm run dev:web` for Foundry
- `runtime_context`: default `available local application and career states`; name a particular career, club appointment, fixture, or entity when required
- `decision_policy`: default `severity-first, all in-scope findings, preserve PRODUCT.md and DESIGN.md`
- `resume_from`: optional pass artifact or `.impeccable/review-loop/<run-id>/state.json`

State the resolved configuration before application mutation. The cycle count represents implementation cycles: one baseline evaluation plus one post-change evaluation per cycle. Five cycles create six evaluation artifacts.

## Operating Contract

- Use the current checkout for every evaluator and implementer. Worktree creation falls outside this workflow.
- Invocation authorizes the two isolated Impeccable critique assessment subagents. With the Codex implementer, it also authorizes bounded implementation subagents with explicit, disjoint ownership.
- Complete Impeccable `audit` and then Impeccable `critique` for one resolved target before advancing to the next target.
- Load the installed Impeccable skill plus its audit and critique references. Preserve their scoring, severity, detector, persistence, provenance, and question generation.
- Treat `decision_policy` as the supplied answer for routine critique priority and scope questions. Preserve each question and answer in the pass artifact. A product, factual, or visual-direction choice absent from the invocation, `PRODUCT.md`, and `DESIGN.md` pauses the run.
- Use one dedicated headed `agent-browser` session. Codex owns live trials and acceptance evidence for both implementation providers.
- Apply agent-browser's version-matched `dogfood` workflow to browser exploration and reproducibility evidence. Keep Impeccable's code audit as a separate evidence source.
- Keep the selected implementation provider fixed for the run. One setup repair and retry precedes a provider-failure handoff.
- Treat `minimum_findings` as a genuine coverage floor. Continue through the defined target scope after reaching it. An exhausted surface may produce fewer findings; record the actual count and completed coverage.
- Keep findings unique, reproducible, located, severity-ranked, tied to user impact, and stable across cycles. Consolidate duplicate symptoms under one root finding.
- Start at most one development server. Stop the process started by this run and leave a pre-existing process running.
- Preserve unrelated working-copy changes. Record unexpected runtime, detector, browser, or worker behavior in the active artifact and final handoff.
- Keep each individual Impeccable command within its bounded verification ceiling. The finite outer cycle count evaluates newly changed application state.

## Completion

Complete after the configured cycles and their post-change evaluations finish. A required user decision or repeated provider failure pauses the run at its durable checkpoint.

Return artifact paths, the target manifest, score trends, findings opened and resolved per cycle, changed files, browser evidence, implementation provider, validation results, remaining findings, and unexpected behavior.
