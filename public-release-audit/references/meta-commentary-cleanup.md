# Meta-Commentary Cleanup Protocol

Apply this protocol when the user asks you to clean files, folders, documentation, prompts, plans, notes, or other written artefacts for leaked AI scaffolding, meta-commentary, defensive writing, prompt bleed, correction residue, or instruction leakage.

Your job is to edit the provided target files directly. Do not only review, list issues, or propose changes. Make the cleanup changes in place unless the user explicitly asks for a review only.

Treat the target path as the working scope. If the target is a directory, recurse through nested files and folders without asking for permission first.

## Core Objective

Clean the artefacts so they read as final, user-facing or maintainer-facing documents rather than transcripts of how they were produced.

The future reader should see the intended content, not the correction history, prompt logic, model self-defence, or evidence that an AI was instructed to avoid a mistake.

Remove or rewrite text that talks about the writing process instead of serving the document’s actual purpose.

## What To Remove Or Rewrite

Look for and clean:

- instruction leakage
- meta-commentary about the task
- prompt bleed from earlier instructions
- defensive wording that proves compliance
- correction-history language
- unnecessary contrasts caused by earlier corrections
- “do this, not that” phrasing where the final document should simply say what to do
- AI-style caveats that do not help the reader
- references to what the user asked, wanted, corrected, clarified, or requested
- sentences that explain why wording changed
- notes that belong in private working context rather than the artefact
- over-explicit warnings against a mistake that is no longer present
- chat-shaped phrasing inside durable documentation
- sections that describe the process of reviewing, updating, or generating the document instead of the final result

Common signals include wording such as:

- “instead of”
- “rather than”
- “do not confuse this with”
- “the user asked”
- “as requested”
- “this was changed to”
- “the previous version”
- “avoid saying”
- “we should not”
- “this document now”
- “the correction”
- “the prompt”
- “the model”
- “AI-generated”
- “not X, but Y”
- “this is intended to”
- “make sure to”
- “ensure that the agent”
- “the agent should”

Do not remove these phrases blindly. Use judgement. Some warnings, comparisons, or instructions may be legitimate content.

## Reader-Audience Rule

For each suspicious sentence, ask:

Would this sentence make sense to a future reader who never saw the chat, prompt, correction, or implementation discussion?

If yes, it may be legitimate.

If no, remove it or rewrite it into direct document content.

The final artefact should speak to its actual audience:

- operators
- maintainers
- developers
- reviewers
- users
- future agents reading durable instructions

It should not speak to the temporary chat context unless the file is explicitly a prompt, protocol, or instruction document where that context is part of the content.

## Rewrite Style

Prefer direct, final wording.

Examples:

Bad:
“Use Bravo rather than Alpha.”

Better:
“Use Bravo.”

Bad:
“This section was updated to avoid suggesting Alpha.”

Better:
Remove the sentence, or state the current rule directly.

Bad:
“The agent should not describe this as a legacy workflow.”

Better:
“Current workflow: [describe the workflow].”

Bad:
“As requested, this plan avoids creating tests.”

Better:
“Test creation is out of scope for this plan.”

Bad:
“This documentation now reflects the new API.”

Better:
“The API uses [current behaviour].”

Bad:
“Do not mention the old command.”

Better:
Use the current command and omit the old one, unless historical context is genuinely useful.

## Preserve Legitimate Content

Do not remove useful content merely because it contains a contrast or warning.

Keep comparisons when they help the reader make a correct decision, such as:

- migration notes
- deprecated versus current command tables
- compatibility warnings
- security warnings
- operational cautions
- known limitations
- intentional exclusions
- troubleshooting guidance
- historical notes that explain why an old path still exists

When keeping a contrast, make sure it serves the reader rather than exposing the writer’s correction process.

## Scope Rules

Edit only files within the provided target unless a directly linked index, inventory, or reference file must be updated to stay consistent.

Do not perform unrelated rewrites.

Do not change technical meaning.

Do not change commands, paths, API names, configuration keys, environment variables, schema names, or code examples unless the cleanup requires removing unsupported or leaked wording around them.

Do not convert a cleanup pass into a documentation redesign.

Do not over-polish prose. Prioritise removing residue, improving clarity, and preserving factual meaning.

## File Handling

If the target is a directory:

1. Build an inventory of relevant text-based files under the target.
2. Recurse into nested folders.
3. Prioritise documentation, Markdown, MDX, plain text, prompts, plans, READMEs, runbooks, reference files, and generated-looking prose artefacts.
4. Skip binary files, lockfiles, vendored dependencies, build outputs, cache directories, and generated artefacts unless the user explicitly includes them.
5. Preserve frontmatter, headings, links, code fences, examples, and formatting unless they contain the issue being cleaned.

## Cleanup Workflow

1. Read any repo-local instructions that apply to the target.
2. Inventory the target files recursively.
3. Scan for likely meta-commentary, instruction leakage, prompt bleed, correction residue, and defensive writing.
4. Read each candidate file in context before editing.
5. Edit the file directly to remove or rewrite confirmed issues.
6. Preserve the file’s purpose, structure, and technical meaning.
7. If a cleanup changes surrounding wording, check the nearby section still reads naturally.
8. Run lightweight validation where available, such as Markdown formatting, link checks, frontmatter validation, or repository-specific docs checks.
9. If validation fails because of your edits, fix the issue.

## Calibration Rules

Start with breadth before depth. Do not clean one obvious phrase across many files while missing other forms of residue.

Avoid literal search-and-replace unless the phrase is clearly safe to change everywhere.

Avoid technicality for its own sake. A sentence is a problem only if it leaks process, confuses the reader, adds defensive noise, preserves correction history, or makes the artefact feel chat-shaped.

Avoid overcorrection. Some documents are prompts or protocols, so instructions to an agent may be legitimate. Clean leaked scaffolding, not the actual purpose of the file.

Avoid flattening useful nuance. If a warning is genuinely needed, rewrite it as reader-facing guidance rather than removing it.

## When Unsure

If a sentence may be legitimate, inspect the surrounding file purpose before changing it.

If the file is a prompt or protocol, agent-facing instructions may be valid content. Only remove meta-commentary that talks about the creation, correction, or previous conversation rather than the durable instruction.

If a claim cannot be safely rewritten without changing meaning, leave it intact and mention it in the final response as a remaining uncertainty.

## Final Response

After editing, respond briefly with:

- target reviewed
- files changed
- main classes of cleanup performed
- validation run, if any
- any uncertain items left unchanged
