---
title: OpenCode Image to Code
type: guide
description: Reproduce UI reference images through OpenCode with repeated visual review by Codex and OpenCode.
status: active
date created: 2026-09-16
date modified: 2026-09-16
---

# OpenCode Image to Code

Attach a UI image in your project conversation and write:

```text
$opencode-image-to-code reproduce this
```

Codex infers the project's stack, a new destination, and the running app address. OpenCode implements the image, then both agents compare rendered screenshots. The default is at least three rounds, continuing for visible differences while progress continues. Add `do 5 comparison loops` to set a fixed total, or `at least 5 loops` to set a minimum. Any positive whole-number count is supported.

New work produces a newly authored standalone page with its own directly visitable URL, such as `/design-preview/dashboard`. Codex chooses an unused descriptive path when you omit one and returns the full URL. Existing routes remain intact. The page reproduces the reference's content and visual scope. Explicit adaptation requests may specify existing content or behavior to preserve in the new page; an explicit swap request integrates it into an existing route.

The original image governs layout, typography, colors, spacing, and assets. Human face contents are excluded by default while their surrounding geometry is preserved. Additional exclusions and overrides can be supplied in ordinary language.

For new work, all visual components, markup, layouts, and styles are created from scratch. Unrelated existing UI components remain excluded from reuse regardless of similarity, including wrapped, copied, or restyled versions. Applying a design to an existing page preserves its required behavior through the newly authored visual implementation.

To continue an existing implementation, write `$opencode-image-to-code resume this page against this reference` and identify the page when it is unclear from context. Codex retains that candidate's files, URL, and candidate-owned code, captures its current rendering, and starts the comparison/correction workflow. The implementation may come from Gemini, Claude, Codex, another OpenCode model, or any other author. Source files and the original reference provide the handoff; the previous provider's session or credentials are optional. OpenCode uses the default worker model or your requested override.

A count supplied with a resume request means additional loops unless stated as a total. A documented interrupted budget carries forward its verified completed loops; an unknown prior budget starts the default minimum of three new loops.

## Requirements

- A target project with its application already running.
- Reference images accessible as local files to both agents.
- Authenticated OpenCode through `%USERPROFILE%/bin/opencode-no-plugins.ps1`, PowerShell 7, RTK, and `agent-browser`.
- An image-viewing capability for each agent.

The default worker model is Muse Spark 1.3 Contributor (`opencode-go/muse-spark-1.3-contributor`). Users can request another model by name or exact `provider/model` ID; Codex resolves availability through `opencode-no-plugins`. The bundled wrapper always uses that launcher, which runs OpenCode with external plugins disabled. Codex retains orchestration and acceptance. The workflow verifies actual image access before implementation. Verification consists of browser rendering, image inspection, and scoped source review; application startup and lint/build/test commands are outside its scope.

Run passes sequentially. Each run preserves events, diagnostics, the final message, and session information in a separate evidence directory. See [OpenCode invocation](references/opencode.md) for the wrapper and model selection.

Each loop includes comparison by both agents, correction by OpenCode where needed, and verification of the resulting rendering by both agents. Initial generation is separate from the count. One loop includes a correction opportunity and final verification. Review permits evidence artifacts while preserving application source and reference images. Supplied viewports define visual comparison targets; additional responsive designs require an explicit request.

Each reviewer records findings before seeing the other's current findings. Corrections use the reconciled observations, including typography, assets, icons, content, and geometry. Capture evidence includes actual font/image readiness and the enlarged regions used for fine-detail review. The candidate follows the inferred project stack and route convention.

The result includes a preview URL, candidate paths, selected and completed review counts, screenshot evidence, and any remaining discrepancies. Exact unidentified fonts, unavailable assets, or interrupted review remain explicit limitations. Reaching a fixed comparison limit with remaining differences, or persistent lack of progress, produces an incomplete fidelity report.

See [usage examples](usage-examples.md), [skill instructions](SKILL.md), and [worker prompt](references/worker-prompt.md).
