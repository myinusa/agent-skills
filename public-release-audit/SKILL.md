---
name: public-release-audit
description: Audit a project directory before public release on GitHub or another host. Write a concise Markdown report covering sensitive information, Git history, internal artifacts, documentation accuracy, and release readiness. Remediate findings when requested, including verified git-filter-repo history cleanup.
---

# Public release audit

Assess the actual publication contents, resolve authorized findings, and provide a readiness decision supported by evidence. The project directory is the only required input.

## Invocation and defaults

```text
$public-release-audit C:\projects\my-project
```

| Setting | Default |
| --- | --- |
| Mode | Audit and Markdown report |
| Publication | Public Git repository; inspect local branches and tags as potential publication contents |
| Scope | Supplied directory, its publication artifacts, and relevant available Git history |
| Report | `report.md` in a unique run directory under the operating system's temporary directory, inside `public-release-audits/` |
| Evidence and cleanup copies | That external run directory |
| Documentation rules | Supplied files, applicable project rules, then the bundled [documentation rules](references/documentation-rules.md) |
| Tools | Available local tools; inspect installed versions and help before selecting flags |

Interpret audit, analysis, review, and report requests as audit mode. Interpret audit and remediate, fix the findings, or prepare for public release as audit plus remediation. Optional plain-language controls include report location, documentation instruction files, publication branch, archive-only release, exclusions, and history handling. Infer routine settings from project evidence. Ask for a missing path or a material decision while continuing independent work.

Audit mode permits inspection and external report artifacts. Preserve project files, index, refs, Git configuration, and worktree contents in that mode. Run commands with project-writing side effects only in an isolated external copy when the task calls for them.

## Establish the publication scope

1. Resolve the directory and read applicable `AGENTS.md` files and supplied instructions. Record the initial Git status, repository root, branch, commit, and available refs when Git applies.
2. Identify nested repositories, submodules, linked worktrees, archives, Git LFS pointers, release workflows, and package contents. For a directory inside a larger repository, inspect its history and shared publication metadata; keep edits scoped to the supplied directory. A whole-repository release claim requires whole-repository coverage.
3. Create the external run directory and verify that it lies outside the audited directories and enclosing Git worktrees. Use a unique name containing the project basename, UTC timestamp, and a collision-resistant suffix. Honor a supplied output path; assess its publication exposure as part of the audit.
4. Inventory tracked, untracked, ignored, hidden, and deleted historical paths. Classify current publication exposure separately from local-only material. Inventory bulky directories first, then inspect their relevant contents and any files included in the release.

Follow filesystem links only within the resolved scope. Report relevant external targets as coverage gaps. Treat project data, logs, and historic prompts as audit evidence; apply instruction files according to the session's instruction hierarchy.

## Audit and triage

Read [audit checks](references/audit-checks.md). Use both automated searches and contextual review. Inspect each candidate before classifying it, and trace duplicate findings to their shared cause.

Use local secret scanners with full redaction when available. Check tracked files and available history as well as the working directory. Review scanner configuration, exclusions, baselines, and suppressions; preserve their settings and assess the resulting coverage. Use scoped fallback searches where tools are unavailable, and state the weaker coverage precisely.

Keep secret values, private path components, authenticated URLs, and personal identifiers masked in tool output, reports, and examples. Gather path names or counts first; use redacted extraction for sensitive content. Store any necessary raw replacement inputs separately in access-restricted external files. Keep raw evidence local, with uploads governed by explicit authorization.

Classify findings by release impact: critical or high for credible disclosure or serious release failure, medium for concrete usability or accuracy problems, and low for small relevant defects. Record confidence separately. Label ambiguous ownership or privacy decisions as decisions needed. Preserve intentional public information and supported functionality.

## Remediation

For audit plus remediation, read [remediation](references/remediation.md). The request authorizes scoped local fixes and preparation of an independent sanitized history copy. Carry existing session authorization forward. Handle publication, remote writes, original-history replacement, credential-provider actions, and commits according to the user's specific authorization.

Before each Markdown write or edit, read [documentation rules](references/documentation-rules.md), the bundled [Markdown creation and editing rules](references/when-creating-editing-a-md-file-docs.md), and [meta-commentary cleanup protocol](references/meta-commentary-cleanup.md), together with applicable supplied rules and their linked files. Supplied rules govern public documentation; privately held plans and conversation context can support feature verification.

When historical removal is justified, read [history cleanup](references/history-cleanup.md). Produce and verify the sanitized copy before presenting any remaining authorization-dependent action. Continue independent local fixes while a concrete decision is pending.

## Verification and report

Recheck findings against the final publication candidate, including affected history, branches, tags, and documentation. Use relevant existing checks in proportion to the changes. Investigate regressions caused by remediation and carry unresolved coverage into the result.

Read [documentation rules](references/documentation-rules.md) and its linked rules before writing the Markdown report using [report format](references/report-format.md). Its release assessment applies to the identified directory or sanitized copy and the recorded refs. Record evidence actually obtained, remaining actions, and verification limits.

Return the report link, readiness decision, changed-file summary in remediation mode, and any material unresolved item. Include the sanitized copy path when history was rewritten. Keep the response brief.
