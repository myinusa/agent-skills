---
title: Grok Bot Codex Delegation Usage Examples
type: guide
description: Example Grok Bot prompts for delegating local repository work to Codex.
status: active
date created: 2026-08-28
date modified: 2026-08-28
tags: [grok-bot, codex, delegation, examples]
component: [agents]
related:
  - SKILL.md
  - README.md
---

# Grok Bot Codex delegation usage examples

## Implementation

```text
/grok-bot-to-codex-delegation in <REPOSITORY_PATH>, have Codex implement the customer export endpoint from the existing requirements. Follow the repository instructions, review the result, and use correction passes until the acceptance criteria are met.
```

## Investigation

```text
/grok-bot-to-codex-delegation in <REPOSITORY_PATH>, ask Codex to trace the intermittent null reference in invoice generation. Keep the repository read-only and return the likely cause with file and line evidence.
```

## Code review

```text
/grok-bot-to-codex-delegation in <REPOSITORY_PATH>, delegate a read-only review of the authentication flow to Codex. Prioritize correctness and security findings with file and line references.
```

## Documentation

```text
/grok-bot-to-codex-delegation in <REPOSITORY_PATH>, have Codex update the operator guide for the current deployment workflow. Follow the repository documentation rules and perform only the validation they authorize.
```

## Sol

```text
/grok-bot-to-codex-delegation use Codex GPT-5.6 Sol for this task in <REPOSITORY_PATH>. Keep high reasoning and the fast service tier, then review and accept the repository result.
```

## Codex subagents

```text
/grok-bot-to-codex-delegation have Codex use subagents for this task in <REPOSITORY_PATH>. Give each subagent an independent workstream, integrate the result, and validate the complete outcome.
```
