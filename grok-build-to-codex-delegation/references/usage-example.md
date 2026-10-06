---
title: Codex Delegation Usage Examples
type: guide
description: Ready-to-use Grok Build prompts for delegating repository work to Codex.
status: active
date created: 2026-08-25
date modified: 2026-08-27
tags: [grok-build, codex, delegation, examples]
component: [agents]
related:
  - .grok/skills/grok-build-to-codex-delegation/SKILL.md
  - .grok/skills/grok-build-to-codex-delegation/README.md
---

# Codex Delegation Usage Examples

## Complete implementation

```text
/grok-build-to-codex-delegation implement the customer export feature from the existing requirements. Have Codex perform the repository work and validation, then review the result and return correction passes until the acceptance criteria are satisfied.
```

## Focused change

```text
/grok-build-to-codex-delegation have Codex update the invoice calculation in apps/backend. Keep edits within the billing feature and run the existing backend build.
```

## Investigation

```text
/grok-build-to-codex-delegation ask Codex to trace the intermittent null reference in invoice generation. Keep the repository read-only and return the likely cause with file and line evidence.
```

## Code review

```text
/grok-build-to-codex-delegation delegate a read-only review of the authentication flow to Codex. Prioritize correctness and security findings with file and line references.
```

## Documentation

```text
/grok-build-to-codex-delegation have Codex update the operator guide for the current deployment workflow. Follow the repository documentation rules and validate the changed frontmatter.
```

## Codex subagents

```text
/grok-build-to-codex-delegation have Codex use subagents for this task. Divide the independent backend, frontend, and documentation workstreams, integrate their results, and validate the complete implementation.
```

## Sol model

```text
/grok-build-to-codex-delegation use Codex GPT-5.6 Sol for this task. Keep high reasoning and the fast service tier, then review and accept the repository result.
```

## Explicit scope and acceptance

```text
/grok-build-to-codex-delegation use Codex to correct pagination in apps/backend/Features/Customers. Preserve the public API, keep the change within that feature, and accept the result when the existing backend build succeeds and page boundaries return the expected records.
```

## Authorized commit

```text
/grok-build-to-codex-delegation have Codex implement the approved configuration change, validate it, and create a commit after Grok accepts the result.
```
