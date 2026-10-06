---
title: "Crack Tech Debt Audit Implemented Improvements"
type: "reference"
description: "Implemented audit controls and preserved quality guardrails for crack-tech-debt-audit."
status: "active"
date created: "2026-08-12"
date modified: "2026-08-12"
tags: [skills, audit, technical-debt, reference]
component: [agents, docs]
related:
  - .codex/skills/crack-tech-debt-audit/SKILL.md
---

# Crack Tech Debt Audit Implemented Improvements

This file lists the implemented controls in `crack-tech-debt-audit`.

## Implemented

1. **Audit modes**
   The skill requires one mode: `full-repo`, `scoped-module`, `delta-since-commit`, `repeat-run`, or `triage-top-10`.

2. **Severity rubric**
   Critical, High, Medium, and Low are calibrated by impact, blast radius, security exposure, operational risk, and maintainability cost.

3. **Evidence standard**
   Findings must include one evidence type: `code`, `test`, `tool`, `history`, `docs`, or `runtime`.

4. **Specificity over generic observations**
   Findings name the exact files, folders, repeated patterns, stale artefacts, and concrete consequences.

5. **Optional deterministic orientation helper**
   `.codex/skills/crack-tech-debt-audit/scripts/orient_audit.py` reports largest files, most-changed files, size/churn overlap, manifest files, and generated candidates when that data sharpens the audit.

6. **Exclusion policy**
   The skill explicitly excludes generated files, vendored code, lockfiles, compiled assets, snapshots, bulk migrations, minified bundles, and third-party examples unless they are in scope or materially risky.

7. **Anti-ceremony delivery**
   The deliverable omits default remediation plans, quick-win checklists, smoke-test sections, and process-heavy follow-up unless the user explicitly asks for them.

## Guardrails Preserved

- Enough orientation before judgment.
- File-line citations for concrete findings.
- Hard-edged audit voice.
- No default remediation.
- No rewrite recommendations unless justified.
- No padding.
- Required "things that look bad but are actually fine" section.
