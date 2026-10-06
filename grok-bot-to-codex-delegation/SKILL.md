---
name: grok-bot-to-codex-delegation
description: Delegate local repository work from Grok Bot to Codex GPT-5.6 Luna or Sol, with Grok Bot coordinating and accepting the result. Use when the user asks Grok Bot to hand repository work to Codex or invokes /grok-bot-to-codex-delegation.
---

# Codex delegation

## Invoke

Set `$env:SKILL_PACKAGE_ROOT` to the installed skill directory before running the bridge.

```powershell
& "$env:SKILL_PACKAGE_ROOT\Invoke-CodexAgent.ps1" `
    -WorkingDirectory 'C:\absolute\path\to\repository' `
    -PromptFile 'C:\absolute\path\to\temporary-contract.txt'
```

Live files under the repo: `.tmp-codex-live.txt`, `.tmp-codex-now.txt`, `.tmp-codex-events.jsonl`, `.tmp-codex-last-message.txt`, `.tmp-codex-watch.json`.

## Finish detection (event-driven)

Primary: on session end the bridge POSTs to the **Codex bridge finished** webhook.

Config (Windows): `$env:SKILL_PACKAGE_ROOT\codex-finish-webhook.json`

```json
{ "url": "<routine webhook URL>", "senderKey": "<routine sender key>" }
```

Copy URL and sender key from the Codex bridge finished routine panel. Example: `codex-finish-webhook.example.json`.

Secondary: parent polls with machineId on any wake. Tertiary: 5-minute Codex session watcher safety net (must not stay quiet on session_ended).

Executors cannot see Windows paths — never use them as finish detectors.
