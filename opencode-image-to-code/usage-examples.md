---
title: OpenCode Image-to-Code Usage Examples
type: guide
description: Minimal invocations and optional plain-language controls for UI image reproduction.
status: active
date created: 2026-09-16
date modified: 2026-09-16
---

# Usage examples

## Attach an image

```text
$opencode-image-to-code reproduce this
```

Use this from the target project's conversation. Codex resolves the stack, destination, and running URL. A reference accessible only inside the conversation may require a local image path if attachment export is unavailable.

The result is a new standalone page with its own unused URL path. Codex returns the full URL; a supplied path is optional.

## Supply a file

```text
$opencode-image-to-code C:\designs\dashboard.png
```

## Choose the destination

```text
$opencode-image-to-code C:\designs\dashboard.png — put it at /design-preview/dashboard
```

## Apply it to an existing design

```text
$opencode-image-to-code use this image for the existing reports page; keep its filters and data
```

Produces a separate reports candidate and preview while retaining the current page. When ready to replace it:

```text
Swap the reviewed candidate into the reports route.
```

Design adaptation retains the content and behaviour specified in the request. State that choice in the task contract; clarify materially ambiguous content choices. Ordinary reproduction uses the image's visible text and data.

## Resume an existing implementation

```text
$opencode-image-to-code resume this page against this reference
```

```text
$opencode-image-to-code continue /design-preview/dashboard from where Gemini left off — reference C:\designs\dashboard.png
```

```text
$opencode-image-to-code resume src/design-preview-home/HomePreviewStandalonePage.tsx using this image — do 2 more comparison loops
```

Continues the selected candidate in place, preserving its URL and candidate-owned components. Codex infers the remaining context and captures the current page before corrections. Any previous model or provider is supported through the existing files and original reference; an old chat, session ID, or provider account is optional. OpenCode remains the worker, using Muse Spark 1.3 Contributor by default. Add a requested model in the same way as for new work.

Resume counts apply to additional loops unless specified as a total. An interrupted, documented budget retains verified completed loops; an unknown budget uses the default minimum of three new loops.

## Set the comparison count

```text
$opencode-image-to-code reproduce this — do 5 comparison loops
```

Runs five compare → correct → verify loops after initial generation. Both agents compare the rendering, OpenCode corrects differences, and both verify the updated rendering within the same loop. Remaining differences are reported at the limit. `1 loop` includes correction and verification. Use `at least 5 loops` to allow continued corrections beyond five. Omitting the count keeps the default minimum of three.

## Select a worker model

```text
$opencode-image-to-code reproduce this — use Muse Spark 1.3 Contributor
```

Muse Spark 1.3 Contributor is already the default. To choose another model, add `use provider/model` with its exact ID from `opencode-no-plugins models`, or give its unambiguous display name. The selected model must support image input and tool use. Model changes remain explicit.

## Add only the details that matter

```text
$opencode-image-to-code C:\designs\billing.png — app is at http://localhost:4300, ignore the logo
```

```text
$opencode-image-to-code these two images are the desktop and mobile versions of the same page
```

Optional details include comparison count, destination, running URL, framework for a new target, model, viewport, existing page behavior, and ignored regions. Supply them in ordinary language. Omitted values come from project and image evidence, with a default minimum of three joint comparisons.
