---
title: Gemini Image-to-Code Usage Examples
type: guide
description: Minimal invocations and optional plain-language controls for UI image reproduction.
status: active
date created: 2026-09-16
date modified: 2026-09-16
---

# Usage examples

## Attach an image

```text
$gemini-image-to-code reproduce this
```

Use this from the target project's conversation. Codex resolves the stack, destination, and running URL. A reference accessible only inside the conversation may require a local image path if attachment export is unavailable.

The result is a new standalone page with its own unused URL path. Codex returns the full URL; a supplied path is optional.

## Supply a file

```text
$gemini-image-to-code C:\designs\dashboard.png
```

## Choose the destination

```text
$gemini-image-to-code C:\designs\dashboard.png — put it at /design-preview/dashboard
```

## Apply it to an existing design

```text
$gemini-image-to-code use this image for the existing reports page; keep its filters and data
```

Produces a separate reports candidate and preview while retaining the current page. When ready to replace it:

```text
Swap the reviewed candidate into the reports route.
```

Design adaptation retains the existing page's content. Add `use the image's text and sample data too` when the reference content should replace it in the candidate.

## Set the comparison count

```text
$gemini-image-to-code reproduce this — do 5 comparison loops
```

Runs five compare → correct → verify loops after initial generation. Both agents compare the rendering, Gemini corrects differences, and both verify the updated rendering within the same loop. Remaining differences are reported at the limit. `1 loop` includes correction and verification. Use `at least 5 loops` to allow continued corrections beyond five. Omitting the count keeps the default minimum of three.

## Add only the details that matter

```text
$gemini-image-to-code C:\designs\billing.png — app is at http://localhost:4300, ignore the logo
```

```text
$gemini-image-to-code these two images are the desktop and mobile versions of the same page
```

Optional details include comparison count, destination, running URL, framework for a new target, model, viewport, existing page behavior, and ignored regions. Supply them in ordinary language. Omitted values come from project and image evidence, with a default minimum of three joint comparisons.
