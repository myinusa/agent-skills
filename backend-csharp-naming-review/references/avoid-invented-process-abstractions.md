There is a recurring design and naming problem in this codebase.

Do not default to creating abstractions, methods, types, files, or intermediate models around generic implementation actions or execution stages.

Strong warning words include:

resolve
resolver
resolved
resolution

build
builder
built

prepare
prepared
preparer
preparation

planning
projection

needs

completed
Clearance

allocation

normalize
normalized
normalizer

transform
transformed
transformer

derive
derived

compute
computed

generate
generated
generator

composite
decide
opening

initialize
initialized
initializer

configure
configured

validate
validated
validator

resolution

convert
converted
converter

load
loaded
loader

fetch
fetcher

select
selected
selector

forX
fromX

assemble
assembled
assembler

construct
constructed

Words such as these are not automatically forbidden:

handler
processor
manager
provider
service
helper
utility
engine
coordinator

But they should still be treated with suspicion when they exist mainly to give implementation logic somewhere to live.

The main problem is not the vocabulary itself.

The problem is inventing concepts from implementation verbs or execution stages and then spreading those concepts through the codebase.

Examples:

FooResolver
resolveFoo()
ResolvedFoo

FooBuilder
buildFoo()
BuiltFoo

RequestPreparer
prepareRequest()
PreparedRequest

RawConfig
NormalizedConfig
ResolvedConfig
BuiltConfig
FinalConfig

This often creates an artificial architecture where the names describe the sequence in which the program manipulates data rather than the actual domain or system concepts.

Do not narrate program execution through names.

A sequence such as:

loadX()
prepareX()
resolveX()
buildX()
processX()

is not automatically a useful model of the system.

Likewise, types such as:

RawX
PreparedX
ResolvedX
BuiltX
ProcessedX

should not exist merely because data passes through those implementation stages.

Before introducing one of these concepts, ask:

1. What concrete domain or architectural concept does this represent?

2. Does this concept need to exist independently?

3. Does it have its own invariant, responsibility, boundary, protocol, or genuinely distinct representation?

4. Am I creating a noun from a verb because some logic needs somewhere to live?

5. Am I creating a new state type because the implementation happens to perform another step?

6. Would this code be clearer if it remained part of an existing object, function, data structure, or control flow?

7. Does this operation need a name at all?

8. Am I replacing a generic word with another generic synonym while preserving the same unnecessary abstraction?

Do not assume every suspicious abstraction needs to be renamed.

Possible remediations include:

- rename it when the concept is valid but the name is vague
- use a concrete domain operation when a real operation exists
- move the behaviour onto or near an existing domain concept
- collapse multiple intermediate representations into one meaningful model
- inline the operation
- remove the method
- remove the type
- remove the file
- merge the abstraction into existing code
- express the behaviour directly through existing data or control flow
- keep the abstraction only when it represents a real concept

Sometimes the correct replacement for:

resolveFoo()

is not:

findFoo()
getFoo()
computeFoo()
fooFor()

Sometimes the correct result is that no separate operation should exist.

Likewise, replacing:

FooResolver

with:

FooProvider
FooManager
FooProcessor
FooService
FooEngine

does not fix the problem if the underlying abstraction is unnecessary.

Treat words such as Resolver, Builder, Prepared, Resolved, Built, Normalized, and similar implementation-stage terminology as design triggers.

When one appears, inspect the structure before accepting the name.

The central rule is:

Do not invent an abstraction merely to describe what the implementation is doing.

Do not invent a state merely to describe which step has already happened.

Do not assume a generic process abstraction needs a renamed replacement.

Prefer existing domain concepts, meaningful architectural boundaries, direct data relationships, and the smallest amount of named structure necessary to express the behaviour.

A good change should reduce invented vocabulary rather than merely replacing one generic term with another.


You have a recurring tendency to invent process-shaped concepts around code that does not necessarily need them. This is not just a naming issue; it can become a structural habit where you create an extra method, type, state, file, or abstraction because that pattern feels familiar or complete. Be aware of that tendency while you work here. Do not assume that the shape you have seen often in other codebases is the shape this codebase needs.

Treat your own first instinct as something to inspect, not automatically preserve. If you find yourself introducing a new layer, lifecycle stage, helper concept, or named operation, ask whether the code actually requires that concept or whether you are filling in a pattern because it is common in your training data. It is acceptable for the best change to contain less structure, fewer names, fewer files, and no replacement abstraction at all.
