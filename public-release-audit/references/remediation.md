# Remediation

Read the current report or establish findings from the audit. Revalidate older findings against current files and refs. Preserve unrelated working changes and record the initial state before applying scoped fixes.

## Local fixes

Remove confirmed sensitive values from publishable files, replace required values with configuration lookup, and provide safe example configuration when the project needs it. Preserve behavior and verify the relevant consumer. Keep existing local credential material in a protected local location when it is needed for operation.

For private artifacts, establish their purpose and tracking first. Preserve a private recovery copy outside publication scope before removing useful material. Add specific ignore rules where appropriate. For tracked local files, untrack exact paths while retaining working copies when that is the intended outcome. Stage only changes required by a justified untracking operation and report the index change; preserve the rest of the index.

Inspect generated artifacts and packaging rules after source cleanup so the release contains the corrected content. For personal paths, update examples or configuration to use portable values supported by the project. Review binary assets and screenshots through appropriate tools when a finding requires replacing or removing them.

Read [documentation rules](documentation-rules.md), [Markdown creation and editing rules](when-creating-editing-a-md-file-docs.md), [meta-commentary cleanup](meta-commentary-cleanup.md), and supplied writing files before every Markdown edit. Apply the cleanup protocol to confirmed documentation findings within the authorized scope. Check the complete feature claims affected by a documentation finding. Preserve the document's purpose and useful public detail.

Use [history cleanup](history-cleanup.md) when private content remains in available history or other publishable refs. A current-file fix and a historical removal have separate verification requirements.

## Authorization and unresolved choices

An audit plus remediation request authorizes scoped local fixes and an independent sanitized history copy. Original-history replacement uses explicit authorization identifying the repository and operation. Keep existing authorization in effect across preparation and execution.

Commits, remote publication, remote rewrites, credential-provider changes, and license selection use their respective user authorization. Prepare a concrete verified result before requesting any remaining authorization. Continue authorized independent work while awaiting a material decision.

For exposed credentials, record revocation or rotation as required and track confirmation separately from file cleanup. For ambiguous private material or ownership, preserve recoverable data and state the exact decision required. An unresolved publication decision stays visible in the readiness assessment.

## Verify the result

Re-scan current publication contents and the relevant available refs. Check ignore behavior and tracked-path removal directly. Verify the changed documentation against current source, configuration, and actual links. Run existing checks relevant to code or packaging changes, using an external copy for checks whose side effects exceed the authorized scope.

For historical remediation, verify the sanitized copy and identify which current files or staged changes it incorporates. Carry missing current changes into the release candidate through reviewed file-level edits. Recording those changes in Git follows commit authorization. Until they are recorded, report that a Git push would publish the committed tree and list the pending release changes.

Update each finding's current status and verification evidence. State failed checks, remaining external actions, and coverage gaps. A tool failure leaves the affected finding open until alternate evidence resolves it.

Stop a repeated failed remediation attempt after diagnosing and correcting its concrete cause once. Preserve the recoverable state and report the remaining finding and failure evidence. Continue other applicable fixes.
