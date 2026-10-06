# Audit checks

## Publication contents and coverage

Establish what a public clone, source archive, package, release attachment, or published site would contain. Inspect packaging allowlists, ignore rules, CI artifact upload paths, source maps, and generated documentation. Track each finding's exposure surface: current tracked files, other refs, deleted history, publishable artifacts, or local-only files.

For Git repositories, inspect status, tracked and ignored paths, refs, shallow boundaries, partial clones, submodules, and LFS availability. Available local history defines actual coverage. Remote-only refs, hosted pull-request refs, missing LFS objects, and externally stored artifacts require explicit coverage statements. A clean local scan supports a local finding only.

Inventory hidden and ignored directories with tools such as `rg --files --hidden --no-ignore`, excluding Git's object storage from ordinary file recursion. Inspect Git objects through Git tooling. Identify dependencies, caches, vendored files, and build outputs before selecting search depth; inspect them when publication rules include them or evidence indicates exposure. Track skipped large files, scanner limits, binary formats, archives, and failed reads.

## Secrets and private information

Check credentials, access tokens, private keys, connection strings, authenticated URLs, cookies, session exports, certificates containing private keys, configuration backups, deployment files, notebook outputs, and fixture data. Search for both recognized provider patterns and contextual credential assignments.

Inspect Windows user paths, UNC shares, home paths, internal hostnames, private repository URLs, cloud account identifiers, support addresses, customer data, and identifying screenshot content. Read images and document metadata when relevant. Distinguish deliberately public contact information, public identifiers, placeholders, and actual exposure using file context and supplied preferences.

Inspect commit and tag messages, author and committer identities, branch and tag names, historical blobs, and renamed or deleted files. Local reflogs and unreachable objects describe recovery exposure; classify them separately from refs intended for publication. Inventory remote URLs through redacted extraction because URL credentials can be present.

Use a dedicated scanner alongside contextual review. For installed Gitleaks versions supporting these commands, use external report paths and full redaction:

```text
gitleaks dir <project-directory> --redact=100 --report-format json --report-path <external-run-directory>/working-tree.json
gitleaks git <repository-root> --log-opts=--all --redact=100 --report-format json --report-path <external-run-directory>/history.json
```

Check help and configuration before execution. Scan all relevant refs and document effective exclusions. Interpret a findings exit status separately from scanner failure. Inspect redacted structured output for limits and findings. Protect raw candidates during fallback scans by returning file names first and redacting excerpts before tool output.

Credential verification uses local format and context. Provider calls, uploads, and revocation follow explicit authorization. Credible exposed credentials remain an action item until rotation or revocation is confirmed.

## Internal material and ignore rules

Review plans, agent state, prompts, local instruction files, conversation exports, scratch documents, debug captures, logs, backups, temporary scripts, crash dumps, and local databases. File purpose determines the finding. Public agent skills and intentional maintainer instructions can be legitimate release content.

Use `git ls-files` to establish tracking and `git check-ignore -v` to explain applicable rules. Existing tracked files remain tracked after an ignore rule is added. Check historical paths and alternate filenames when an internal artifact was renamed.

Look for realistic example data, private comments, machine-specific settings, secrets in generated bundles, screenshots of account details, and archives containing earlier project copies. A relevant ignored file can still enter a package or release artifact through its publication rules.

## Documentation and feature accuracy

Map public feature claims to implementation, reachable commands or UI, tests, and available accepted plans or conversation context. Treat planned, implemented, and verified behavior as distinct evidence states. Flag missing feature descriptions and claims that overstate current behavior when they materially affect public users.

Read the README from a new user's perspective: purpose, usable features, prerequisites, setup, configuration, run or build commands, and relevant operational limits. Check commands against manifests and scripts, examples against configuration consumers, and links against their targets. Verify sample secrets are placeholders and sample paths are portable.

Identify private planning material separately from the useful public behavior it describes. Review documentation for correction residue, internal conversations, task commentary, and instruction leakage. Preserve purposeful agent instructions in skills and protocols.

Use [meta-commentary cleanup](meta-commentary-cleanup.md) as review criteria in audit mode. Apply confirmed cleanup in remediation mode, following [documentation rules](documentation-rules.md).

## Release defects and ownership

Inspect license presence and consistency, copied assets and attribution, third-party notices, and intended repository identity. Establish evidence and request an ownership decision where it affects publication. License selection follows the owner's choice.

Check applicable lockfiles, runtime requirements, missing files referenced by scripts, machine-specific dependencies, private package feeds, hardcoded private service requirements, release version mismatches, and broken publication workflows. Investigate dependency advisories when project evidence makes them relevant; use authoritative current sources and record exact package versions and applicability.

Inspect CI permissions, credential handling, and artifact exposure where they affect the release. Use existing meaningful build, test, or packaging checks when needed to substantiate a finding. In audit mode, isolate checks that write files or install dependencies in an external copy.

Include a finding when it changes publication safety, documentation truth, or practical usability. Keep badge preferences, cosmetic redesigns, speculative architecture work, and unrelated refactors outside the report's release findings.

Gitleaks command reference: [official repository](https://github.com/gitleaks/gitleaks).
