# Report format

Read [documentation rules](documentation-rules.md), including its linked Markdown and cleanup rules, before creating or editing the report. Write a compact Markdown report that supports the publication decision. Choose sections that have actual content and group repeated instances under the same cause.

## Release assessment

Begin with one of these decisions and a short evidence-based reason:

- Ready within checked scope: the identified publication contents satisfy the checked release requirements, with any limited coverage described.
- Pending decisions or verification: a material scope gap, ownership choice, missing check, uncommitted release fix, or external action remains.
- Blocked by findings: a confirmed exposure or release defect requires resolution before publishing the identified contents.

Identify the candidate directory, mode, audit time, publication scope, commit and relevant refs when applicable, and material coverage limits. Use a project basename in the report; give the user the exact local artifact path in the final reply. Mask identifying path components, authenticated URLs, and sensitive ref names inside the report.

## Findings

Give each finding a stable ID and include:

| Field | Content |
| --- | --- |
| Severity and confidence | Release impact and strength of evidence |
| Location | Relative path and line, commit and path, relevant ref, or artifact |
| Exposure | How the identified publication would reveal or encounter it |
| Evidence | Brief redacted observation supporting the finding |
| Action | Specific fix or material decision needed |
| Status | Open, fixed and verified, decision needed, or external action pending |
| Verification | Actual check and result, when available |

Use a compact table for simple findings and short paragraphs for findings needing explanation. Keep secret values and identifying excerpts masked. Preserve useful navigation through relative paths and abbreviated commit IDs.

In audit mode, provide concrete remediation actions for confirmed findings. In remediation mode, show current resolution and verification, with the remaining action where applicable. Keep the report focused on the final state and necessary evidence.

## Coverage and remaining actions

Record actual scopes examined, relevant tools and versions, ref coverage, and meaningful verification outcomes briefly. State missing remote refs, shallow history, unavailable binaries or LFS content, skipped artifacts, failed checks, and inaccessible evidence when they affect the decision.

For historical cleanup, identify the sanitized candidate using a relative artifact path, changed refs, successful targeted scans, protected recovery material, and external cleanup still required. Distinguish the candidate's result from the original repository's remaining exposure.

Include remaining user or external actions only where necessary. Omit empty sections, copied scanner dumps, exhaustive passed-check lists, speculative issues, cosmetic tasks, numeric confidence scores, and promises of universal safety.
