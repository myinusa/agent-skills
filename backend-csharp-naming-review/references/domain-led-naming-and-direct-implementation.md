---
title: Domain-Led Naming and Direct Implementation
type: guide
description: A reusable method for choosing precise code concepts, removing accidental abstractions, and carrying meaning consistently across the system.
status: active
date created: 2026-09-16
date modified: 2026-09-16
tags: [engineering, naming, design, refactoring]
component: [all]
related:
  - docs/rules/foundational-rules.md
  - docs/rules/solution-quality.md
  - docs/rules/avoid-invented-process-abstractions.md
  - docs/rules/decompose.md
---

# Domain-Led Naming and Direct Implementation

Use this rule before naming, renaming, extracting, decomposing, or introducing code structure.

## Standard

- Begin with the behaviour, data, invariant, and owner already present in the system.
- Give names to domain concepts, architectural boundaries, stored facts, and reusable rules.
- Let each type, method, field, and file justify its existence through a distinct responsibility or meaning.
- Prefer the smallest structural remedy supported by the evidence: keep, rename, move, merge, inline, or delete.
- Carry one meaning consistently through code, storage, protocols, generated models, examples, and user-facing text.
- Use established project vocabulary where it accurately describes the concept.
- Express time values with their frame of reference, event role, and unit.
- Read the type and method together as one API phrase.
- Treat a vague or process-shaped name as a prompt to inspect the surrounding design.

## Review Sequence

### 1. Establish the meaning

Read the implementation, callers, consumers, persistence, and contract definitions. Write a plain statement of what the code represents or changes.

Useful questions:

- What observable fact or behaviour exists here?
- Which domain concept owns it?
- Is this stored state, an input, a decision, an event, a policy, or a temporary calculation?
- Which invariant gives this code a reason to exist?
- Would the concept remain meaningful if the implementation changed?
- What frame of reference and unit does each temporal value use?

### 2. Inspect the existing structure

Trace the concept through its complete path:

- domain types and application code
- method names, parameters, locals, and return values
- SQL columns, parameters, and JSON paths
- schemas and protocol contracts
- generated models and mappers
- fixtures and examples
- UI properties, labels, and state classes
- diagnostics and error messages

This establishes whether one name has one meaning, several meanings, or represents obsolete data.

### 3. Set the review radius

Match the search and edit scope to the request:

- A concept review follows one fact or operation through its complete vertical slice.
- A systemic vocabulary or structural review inventories that shape across the requested production scope and classifies every occurrence independently.
- A contract review starts from the owning schema or protocol and follows generated and consuming surfaces.

Search results form a candidate inventory. Standard-library APIs, user-facing domain verbs, generated files, vendored sources, and unrelated concepts can share the same spelling. Ownership and behaviour determine which candidates belong to the change.

### 4. Decide which concept deserves a name

A named unit earns its place when it provides at least one of these:

- a domain term used by the product
- an independently meaningful invariant
- ownership of state or behaviour
- reuse across real callers
- a durable boundary or protocol
- a distinct representation required by that boundary
- ownership of a transaction, resource lifetime, idempotency rule, or retained operation result

Implementation order alone provides weak grounds for a new type or method. Intermediate stages such as resolved, prepared, applied, completed, or built require the same evidence as any other concept.

### 5. Choose the structural remedy

| Finding                                          | Direct response                       |
| ------------------------------------------------ | ------------------------------------- |
| The value or field is unused                     | Delete it                             |
| A wrapper delegates once                         | Inline it                             |
| Behaviour belongs to an existing concept         | Move it to that owner                 |
| Two names represent one fact                     | Keep one canonical representation     |
| Several stages carry the same data and invariant | Collapse them                         |
| A real concept has a vague name                  | Rename it from its domain meaning     |
| A boundary requires a distinct representation    | Map it explicitly at that boundary    |
| A rule is independently meaningful and reused    | Give the rule a focused name and home |
| An operation owns transaction semantics          | Keep the operation boundary           |

Renaming is one possible result of the review. Deletion, inlining, and consolidation often produce a clearer result.

### 6. Apply the decision systemically

Search for the concept, its casing variants, serialized field names, SQL names, aliases, and user-facing wording. Judge each occurrence by its role. A shared spelling can represent different concepts, while different spellings can represent one duplicated concept.

Classify candidates before editing. Use mechanical replacement only for an exact set whose shared meaning has already been established. Inspect affected SQL aliases, JSON paths, serialized fields, generated-source inputs, and call sites after the edit.

Update the complete path owned by the change. Regenerate derived files through the repository generator. Leave generated build outputs to their normal build or packaging process.

### 7. Verify meaning and integration

Compare the inputs, outputs, side effects, transaction ownership, persistence shape, and governing data authority before and after the change. Structural work can expose a real contract defect; evidence from the owning boundary determines whether that defect belongs in scope.

Use the narrowest relevant contract validation, build, or existing test suite. A successful compile confirms syntax and type integration. Review still confirms that the names describe the correct concepts and that redundant structure has disappeared.

## Naming Tests

A strong name answers the questions a reader actually has:

- What domain thing is this?
- What fact does it hold?
- What action occurs?
- Who owns the action?
- Which date or event does the value refer to?
- Which unit does the number use?
- Can a reader explain it in one sentence before reading the implementation?

Names gain precision from meaning. A longer name is useful when every segment distinguishes the value. Repeated context and stacked generic nouns add length while obscuring meaning.

## Context Governs Vocabulary

Word lists identify candidates for investigation. The surrounding domain supplies the verdict.

Prevalence establishes repetition. Domain evidence establishes validity.

| Term | Evidence that supports the term |
| --- | --- |
| Arrangement | A retained combination such as accepted participants, date, venue, and terms |
| Operation | Ownership of transaction execution, idempotency, mutation reporting, or another durable execution boundary |
| Resolution | A formal governance decision with a proposal, authority, and recorded outcome |
| Allocation | Assignment from a finite resource, capacity, memory, or explicitly modelled fund |
| Completed | A recognised terminal lifecycle state with observable consequences |
| Open or close | A resource lifetime or explicitly modelled availability state with defined transitions |
| Apply | A concrete domain action such as submitting a job application |
| From | A range boundary, established conversion API, or source distinction that changes meaning |

The same terms provide little information when they merely mark the next implementation step. Each occurrence receives its own semantic check.

## Call-Site and Extraction Tests

Read the call site as a sentence. The type supplies the subject and the method supplies the domain action. Generic repetition often reveals a redundant split:

```text
new BackgroundSeasonWriter().Write(...)
```

An operation object can remain precise when it owns transaction execution, idempotency, mutation summaries, and the retained result:

```text
backgroundSeasonOperation.ExecuteAsync(...)
```

Here the operation type states the work and `ExecuteAsync` invokes its established boundary.

Judge an extraction by what it clarifies or removes:

- a domain invariant gains an owner
- repeated behaviour becomes one implementation
- a durable boundary becomes explicit
- unrelated responsibilities separate cleanly
- a temporary stage, forwarding wrapper, or duplicate representation disappears

Smaller files and additional method names are neutral on their own. The resulting ownership and concepts determine the value of the extraction.

## Representative Examples

### One generic date with several meanings

Weak:

```text
currentDay
```

The same spelling can hide several clocks and event roles.

Precise forms, selected by actual use:

```text
careerDateDayNumber
eventDayNumber
fixtureScheduledDayNumber
reviewDayNumber
asOfDayNumber
```

Each name states its reference point. A systemic change classifies every occurrence before choosing its replacement.

### Repeated context

Weak:

```text
Players.PlayerQuerySupport.SelectPlayers()
```

The surrounding feature and operation already establish that players are involved. A support type with one caller usually signals displaced query logic. Keeping the selection in the concrete query may remove both the repeated name and the extra abstraction.

### Generic source factories

Weak:

```text
PersonIdentity.FromRequest(request)
```

The name describes the input source. When the operation is ordinary construction, use the constructor. When a domain event creates the identity, name that event and keep the invariant with its owner.

### Process verbs

Weak:

```text
plan.Apply(state)
resolution.Resolve(input)
builder.Build(model)
```

These names narrate execution while withholding the domain effect. Inspect the body and its owner. The direct result may be an existing domain action, an inline state change, or removal of the intermediate object.

Changing one process verb to another preserves the same structural question.

### Stacked nouns

Weak:

```text
ActiveControlShareAssignments
FacilitiesInvestmentAllocation
ReviewCoverage
```

Each name combines broad nouns while leaving the represented fact uncertain. Trace the fields, producer, consumer, and governing rule before proposing a replacement. The identifier alone supplies too little evidence for a trustworthy synonym.

### Invented lifecycle states

Weak:

```text
PersonIdentityOpening
CompletedPlan
RequestClearance
```

Reserve lifecycle types for states recognised by the domain, each carrying a distinct invariant. Keep ordinary construction, returned values, and method completion in their direct forms.

### Duplicate contract fields

Weak:

```text
currentDate
careerDate
```

When both fields carry the career clock, retain the canonical contract field and remove the duplicate. Update the mapper, generated model, example, and UI property together.

### Unused observation data

Weak:

```text
PlayerContractResponseObservation(..., CareerDateDayNumber)
```

When the decision uses only the remaining fields, removal is the complete solution. Another date-shaped name would preserve dead data.

### Boundary vocabulary

Content may define:

```text
preparationLeadDays
```

Application code may derive a scheduled planning date from that value. The parser and SQL JSON path use the declared content field. The derived value receives a separate name only where it represents a separate fact.

## Common Failure Shapes

| Shape                                         | What to inspect                                                         |
| --------------------------------------------- | ----------------------------------------------------------------------- |
| A generic word replaced by a synonym          | Whether the abstraction itself has value                                |
| A new type for each implementation stage      | Whether the data or invariant actually changes                          |
| A single-method class                         | Whether it owns a transaction, resource lifetime, invariant, or boundary |
| A method named after its input source         | Whether construction or a domain action already expresses the operation |
| A facade over one call                        | Whether the call can remain direct                                      |
| A long chain of nouns                         | Which concrete fact the chain is trying to represent                    |
| The same date name across unrelated workflows | Which clock or event each value uses                                    |
| Parallel old and new contract fields          | Which single field defines the current product shape                    |
| A renamed unused field                        | Whether any consumer requires the field                                 |
| Local consistency with a mismatched schema    | Which boundary owns the authoritative vocabulary                        |
| A valid domain word appears on a warning list | Which domain definition and invariant support the word                  |
| A systemic request stops at one occurrence    | Which production scope contains the same structural shape               |
| A broad search drives a bulk replacement      | Which semantic groups exist inside the candidate inventory              |
| An abstraction contains data-driven policy    | How the single policy authority remains intact after simplification     |

## Completion Standard

Before finishing, confirm:

- Every changed name has one explainable meaning.
- Every new abstraction has a distinct responsibility or invariant.
- The review radius matches the requested concept, contract, or systemic pattern.
- Each search candidate is classified by ownership and behaviour.
- Dead fields, wrappers, states, and aliases discovered within scope are removed.
- Producers and consumers agree at storage and protocol boundaries.
- Type and method names form a direct, informative call-site phrase.
- Governing data authority and required behaviour remain coherent after structural simplification.
- Temporal values state their role and unit where ambiguity exists.
- Generated models and examples match their source contracts.
- Searches cover casing, serialization, SQL, UI, and generated-source inputs.
- Remaining occurrences have a clear reason to remain.
- The resulting design contains fewer accidental concepts or expresses the required concepts more directly.
