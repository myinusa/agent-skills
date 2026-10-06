# Usage examples

## Audit and report

```text
$public-release-audit C:\projects\my-project
```

Inspects the directory and relevant available history, then writes an external Markdown report. Audit mode preserves the project files and Git state.

## Audit and remediate

```text
$public-release-audit C:\projects\my-project audit and remediate
```

Applies scoped local fixes, checks the resulting project, and prepares a verified independent history copy when historical removal is needed.

## Supply documentation rules

```text
$public-release-audit C:\projects\my-project audit and remediate.
Follow C:\writing-rules\public-docs.md and C:\writing-rules\readme.md
when editing public documentation.
```

The agent reads those files and their linked rules, together with the [bundled documentation rules](references/documentation-rules.md), before editing Markdown. Available project plans and conversation context support the README feature check.

## Choose the report destination

```text
$public-release-audit C:\projects\my-project.
Write the report to C:\release-reviews\my-project.md.
```

## Define the publication contents

```text
$public-release-audit C:\projects\my-project.
The public release will contain main and the v1.0 tag.
```

```text
$public-release-audit C:\projects\my-project.
I am releasing a source archive of the current directory.
```

The report distinguishes the selected release contents from other local exposure. Archive scope includes the actual archive or packaging rules when available.

## Authorize original-history cleanup

```text
$public-release-audit C:\projects\my-project audit and remediate.
I authorize replacing the local repository's history with the verified
sanitized history, preserving my working files and a private recovery copy.
```

Original-history replacement proceeds after verification, within the supplied authorization. The report records the recovery location and any existing remote cleanup still required.

## Continue from a report

```text
$public-release-audit C:\projects\my-project remediate the findings in
C:\release-reviews\my-project.md, using C:\writing-rules\public-docs.md.
```

Rechecks the report against current files and refs, resolves applicable findings, and writes the final verified assessment.
