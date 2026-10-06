---
title: Gemini Image to Code
type: guide
description: Reproduce UI reference images through Gemini with repeated visual review by Codex and Gemini.
status: active
date created: 2026-09-16
date modified: 2026-09-16
---

# Gemini Image to Code

Attach a UI image in your project conversation and write:

```text
$gemini-image-to-code reproduce this
```

Codex infers the project's stack, a new destination, and the running app address. Gemini implements the image, then both agents compare rendered screenshots. The default is at least three rounds, continuing for visible differences while progress continues. Add `do 5 comparison loops` to set a fixed total, or `at least 5 loops` to set a minimum. Any positive whole-number count is supported.

The output is a newly authored standalone page with its own directly visitable URL, such as `/design-preview/dashboard`. Codex chooses an unused descriptive path when you omit one and returns the full URL. Existing routes remain intact. The page reproduces the reference's content and visual scope. Explicit adaptation requests may specify existing content or behavior to preserve in the new page; an explicit swap request integrates it into an existing route.

The original image governs layout, typography, colors, spacing, and assets. Human face contents are excluded by default while their surrounding geometry is preserved. Additional exclusions and overrides can be supplied in ordinary language.

All visual components, markup, layouts, and styles are created from scratch. Existing UI components remain excluded from reuse regardless of similarity, including wrapped, copied, or restyled versions. Applying a design to an existing page preserves its required behavior through the newly authored visual implementation.

## Requirements

- A target project with its application already running.
- Reference images accessible as local files to both agents.
- Authenticated Antigravity (`agy`), PowerShell 7, RTK, and `agent-browser`.
- An image-viewing capability for each agent.

The skill invokes Antigravity directly and resolves models through `agy models`. Its default is Gemini 3.7 Flash High (`gemini-3.7-flash-high`); an explicit selection can use any available Gemini model. General delegation remains unchanged. The workflow verifies actual image access before implementation. Verification consists of browser rendering, image inspection, and scoped source review; application startup and lint/build/test commands are outside its scope.

Each loop includes comparison by both agents, correction by Gemini where needed, and verification of the resulting rendering by both agents. Initial generation is separate from the count. One loop includes a correction opportunity and final verification. Review permits evidence artifacts while preserving application source and reference images. Supplied viewports define visual comparison targets; additional responsive designs require an explicit request.

The result includes a preview URL, candidate paths, selected and completed review counts, screenshot evidence, and any remaining discrepancies. Exact unidentified fonts, unavailable assets, or interrupted review remain explicit limitations. Reaching a fixed comparison limit with remaining differences, or persistent lack of progress, produces an incomplete fidelity report.

See [usage examples](usage-examples.md), [skill instructions](SKILL.md), and [worker prompt](references/worker-prompt.md).
