# Public release audit

Audit a project before publishing it on GitHub or another public host. The skill examines sensitive information, Git history, internal files, documentation, and practical release readiness. It produces a concise Markdown report and can remediate findings.

## Usage

Supply the project directory:

```text
$public-release-audit C:\projects\my-project
```

For audit and remediation:

```text
$public-release-audit C:\projects\my-project audit and remediate
```

The default mode produces a report. Reports, evidence, and sanitized history copies go into a unique directory under the operating system's temporary directory, outside the project. The final response links to the report.

## Coverage

- Credentials, personal paths, private endpoints, identity details, and sensitive data in source, configuration, assets, and available history.
- Tracked and ignored files, internal plans and notes, logs, archives, screenshots, generated outputs, package contents, and release workflows.
- README feature accuracy, setup instructions, configuration examples, links, licensing, dependencies, and concrete release defects.

Findings include a location, release impact, recommended action, and verification status. Coverage gaps remain visible in the release assessment.

## Remediation

Remediation applies scoped local fixes and rechecks their effects. Markdown reports and documentation edits follow the bundled [Markdown creation and editing rules](references/when-creating-editing-a-md-file-docs.md) and [meta-commentary cleanup protocol](references/meta-commentary-cleanup.md), together with supplied instruction files and applicable project rules. [Documentation rules](references/documentation-rules.md) describes their application.

Historical removal uses `git-filter-repo` in an independent copy by default. The report identifies the sanitized copy, the affected refs, and the original checkout's remaining exposure. Replacing original history, creating commits, publishing, remote updates, and credential-provider changes follow specific user authorization. Existing authorization carries forward.

## Optional controls

Add a report destination, documentation rule paths, publication branch, archive-only scope, or explicit exclusions in ordinary language. Only the project directory is required. See [usage examples](usage-examples.md).

## Requirements

Use an agent with filesystem and command access. Git enables history inspection. A local secret scanner such as Gitleaks improves secret coverage; `git-filter-repo` supports history remediation. The skill reports unavailable tools and affected coverage. Tool installation follows the environment's conventions and task authorization.

Copy this folder into your agent's supported skills directory to make it discoverable, keeping its references and `agents/openai.yaml` together. [SKILL.md](SKILL.md) contains the execution instructions.
