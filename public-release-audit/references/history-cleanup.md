# History cleanup

Use `git-filter-repo` for justified removal of private files, secret strings, message content, or unwanted identity information from Git history. Work in an independent external copy by default and verify its publication refs before offering original-history replacement or remote updates.

## Establish the rewrite

Record the source repository's status, branch, available refs, HEAD, shallow or partial boundaries, worktree relationships, submodules, and LFS availability. Capture ref names and object IDs in the protected run directory. Extract remote information with credential redaction.

Find every historical path and rename for each removed file. Determine where sensitive content appears: blobs, commit or tag messages, names and emails, ref names, or LFS objects. Describe the exact intended removal and which valid history and current behavior must survive.

A shallow or incomplete source supports only an incomplete history assessment. Resolve missing history within the user's network authorization, or report the gap and keep the readiness assessment pending.

For credible credentials, track revocation or rotation separately. Provider action follows its own authorization; local cleanup can proceed while that action remains open.

## Prepare an independent copy

Use unused, resolved absolute paths outside all audited worktrees. Clone the available source refs independently, with object storage detached from the source:

```text
git clone --mirror --no-local <source-repository> <external-run-directory>/sanitized.git
```

Capture the source worktree's required current fixes separately because a Git clone copies committed objects. Preserve staged and unstaged changes through reviewed snapshots or patches in the protected run directory. Treat snapshots, bundles, patches, and the original repository as sensitive recovery material.

Keep the source checkout unchanged during rewriting. A mirror has a local source remote; use `--no-fetch` for this local preparation so the rewrite operates on the captured refs. Remote-only history remains an explicit coverage gap. Verify installed `git-filter-repo` help and support for sensitive-data removal before choosing flags. An isolated tool environment can supply a missing version where the task permits it.

## Select the filter

These templates run inside the disposable mirror. Replace placeholders with verified paths and protected input files.

Remove a private file and each historical filename:

```text
git filter-repo --sensitive-data-removal --no-fetch --invert-paths --path docs/private-plan.md --path old/private-plan.md
```

Replace sensitive strings while retaining useful file content:

```text
git filter-repo --sensitive-data-removal --no-fetch --replace-text <protected-replacements-file>
```

Replace sensitive commit or tag message strings:

```text
git filter-repo --sensitive-data-removal --no-fetch --replace-message <protected-message-replacements-file>
```

Combine compatible filters into one reviewed rewrite. Read replacement syntax from the installed help or [official manual](https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt). Pass sensitive values through protected files; keep them masked in commands and output. Match literal values precisely and assess replacement effects.

Use identity mappings only for identities whose replacement is authorized. Inventory ref-name changes separately. Preserve meaningful branch and tag coverage and account for rewritten signatures. Verify filter callbacks or special LFS handling against the installed tool when those cases arise.

Keep the fresh-clone safeguard enabled. If it rejects the operation, investigate the copy and create a fresh independent clone with the complete reviewed filter. Keep partial ref rewrites reserved for an explicitly limited publication scope; complete removal requires coverage of every relevant available ref.

## Verify and prepare the release copy

Inspect filter-repo's changed-ref and commit mapping records. Compare pre- and post-rewrite refs and reachable trees. Confirm each deleted historical path is absent across relevant refs. Re-scan rewritten history and current trees for the original sensitive content using protected inputs and redacted output. Include commit and tag metadata in the targeted verification.

Check local recovery refs, reflogs, unreachable objects, and LFS handling when relevant to the candidate's actual exposure. Keep recovery material confined to private storage. A local history rewrite covers the objects and refs actually inspected.

Create an independent normal checkout from the sanitized mirror for release review. Inspect its configured remotes and remove local backup locations from the release-facing configuration. Apply reviewed current fixes using file-level changes, and inspect ignored or untracked files before including them. Prevent old history from re-entering through a merge or wholesale `.git` copy.

Verify the checkout's final contents, the intended publication refs, and existing meaningful project checks. State which release fixes remain uncommitted. The Git publication tree must incorporate required fixes before the report assesses that tree as ready.

Identify the sanitized checkout as the release candidate. Record the source checkout's remaining historical exposure and the protected recovery location separately.

## Original repository and hosted copies

When original-history replacement is explicitly authorized, prepare the verified candidate first. Confirm the original repository's status and refs still match the captured state, preserve all user work in a protected independent recovery copy, and account for linked worktrees and submodules. Select a replacement method suitable for that repository layout. Keep any recursive filesystem operation within verified absolute targets and retain rollback material.

After replacement, inspect the original repository's files, index, refs, reflogs, remotes, and object exposure. Re-run targeted scans and required project checks. Update the report to identify the directory and refs actually ready for publication.

For an existing hosted repository, capture the required remote ref changes after local verification. Remote updates use authorization naming the destination and affected refs, with current-state checks before execution. New publication similarly follows its supplied destination and scope. A mirror push can delete remote-only refs, so select ref updates from the verified intended set.

Hosted pull-request refs, cached views, forks, other clones, release attachments, CI artifacts, and LFS objects can retain earlier content. Identify relevant external cleanup as remaining actions, with verification tied to observed results. [GitHub's removal guidance](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository) covers hosted cleanup after a local rewrite.
