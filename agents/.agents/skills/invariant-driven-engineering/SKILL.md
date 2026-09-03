---
name: invariant-driven-engineering
description: Design, implement, refactor, and review maintainable TypeScript systems using typed adapter seams, explicit invariants, pure temporal cores, bounded effects, compatibility paths, and adversarial tests. Use for complex features, event-driven or concurrent state, external/provider protocols, schemas and error handling, migrations or version skew, and code accumulating unknown/isRecord guards, optional-field bags, mutable state maps, condition-heavy orchestration, broad modules, or repeated correctness fixes.
---

# Invariant-Driven Engineering

Build locally readable code whose correctness survives ordering, failure, version skew, and future change. Emulate Fable 5's strongest observed habits—typed vocabulary, concrete adapters, pure transitions, compatibility discipline, and rigorous review response—without copying its completeness bias or tendency to grow broad modules.

For substantial implementation, refactoring, or review, read [references/patterns.md](references/patterns.md) completely before changing code. Skip the reference only for a trivial, isolated edit with no dynamic input, state transition, persistence, concurrency, compatibility, or interface-design consequence.

## Core rules

1. State the behavior as invariants before choosing implementation machinery.
2. Keep `unknown` at a genuine external seam. Decode once; do not make downstream callers reinterpret records.
3. Normalize external variation through concrete adapters into one domain vocabulary.
4. Represent mutually exclusive states with discriminated types, not independent optional fields or boolean soup.
5. Put ordering and transition policy in a pure core. Keep I/O, clocks, storage, processes, and UI in a thin effectful shell.
6. Make idempotency, bounds, cancellation, ownership, and compatibility explicit where they matter.
7. Test adversarial histories and observable outcomes through the module's interface.
8. Give each module one coherent responsibility. Extract ownership, not merely lines.
9. Treat review findings as possible missing invariants. Verify them against the real execution path before fixing or dismissing them.
10. Prefer the smallest model that makes correct behavior unsurprising. Do not implement every conceivable extension.

## Workflow

### 1. Establish the model

Inspect repository conventions and the surrounding execution path. Write down, in working notes:

- Trusted and untrusted inputs.
- Domain values produced after validation.
- States and legal transitions.
- Ordering, idempotency, and ownership rules.
- Failure classes and which are retryable, terminal, or recoverable.
- Performance and resource bounds.
- Compatibility combinations that actually exist.

Do not begin by adding guards to the first failing function. Locate the seam where uncertainty should end.

### 2. Design the typed seam

- Accept `unknown` only from JSON, storage, IPC, database decoding, environment variables, or third-party/provider protocols.
- Validate at that seam with the repository's established schema library or a focused parser.
- Return a named domain type or a tagged decode error.
- Preserve raw input only when a real diagnostic or round-trip requirement exists.
- Reject a design that sends `Record<string, unknown>` into business logic or UI code.
- Use a shared adapter interface only when at least two concrete adapters exist or production and test adapters genuinely vary.

Before proceeding, apply this test: after decoding, can any ordinary downstream caller still observe `unknown` or need `isRecord`? If yes, deepen the adapter.

### 3. Encode the domain

- Use discriminated unions for lifecycle and mutually exclusive states.
- Use exhaustive tuples/records for closed sets that must remain complete.
- Use branded or validated identifiers when confusing two identifiers would be harmful.
- Keep open external strings open only until their adapter maps them into the domain.
- Avoid optional bags whose meaning depends on undocumented property combinations.
- Avoid parallel maps or booleans that together form an implicit state machine.

Do not force elaborate types onto simple behavior. A single boolean is correct when the domain truly has one independent yes/no fact.

### 4. Separate policy from effects

Express the difficult decision as a pure function where practical:

```ts
transition(state, event) -> state | decision
decode(input) -> domain value | typed error
classify(snapshot, now) -> status
merge(current, page) -> result
```

Let the effectful shell acquire input, call the pure core, persist or emit the result, and report typed failures. Inject clocks or external dependencies when deterministic verification requires it; do not create indirection without a real variation or test need.

### 5. Make temporal and failure behavior deliberate

For event-driven, asynchronous, or persisted behavior, decide explicitly:

- What happens when an event is duplicated, delayed, missing, reordered, or replayed?
- Which write wins after terminal state?
- How are retries distinguished from duplicates?
- What cancels or bounds work?
- What state may survive disconnect, restart, rollback, or deletion?
- What is atomic, and what compensation restores earlier state after partial failure?
- Which actor owns a resource and may mutate or stop it?

Prefer one clear serialization mechanism or transition owner over scattered defensive checks.

### 6. Integrate across real surfaces

Trace every applicable adapter and consumer. Decide explicitly for each provider, client, process, storage version, and reverse transition. Centralize shared policy; do not duplicate domain interpretation in web, mobile, server, and tests.

Add capability negotiation or migrations only for real mixed-version states. Do not build hypothetical compatibility machinery.

### 7. Verify through the interface

Write the smallest focused tests that prove the invariants. For temporal behavior, consider:

- Normal order.
- Duplicate input.
- Reordered input.
- Missing retained history.
- Retry after terminal or partial state.
- Cancellation, timeout, or disconnect.
- Concurrent stale and fresh results.
- Old/new version combinations.
- Rollback or compensating failure.

Use deterministic queues, deferred values, fake clocks, or in-memory adapters instead of sleeps. Test observable behavior through the same interface callers use. Do not compensate for weak integration coverage by exhaustively testing private helpers.

### 8. Perform the Fable-plus self-review

Inspect the resulting diff for:

- Repeated `unknown`, `isRecord`, record casts, or manual key copying outside one adapter.
- Independent optional fields that permit invalid combinations.
- Condition chains reconstructing a state machine.
- Several maps or refs whose ordering creates implicit state.
- New comments that describe syntax instead of invariants.
- Compatibility rules duplicated in another runtime or surface.
- A module gaining a second unrelated reason to change.
- Pure file movement presented as architectural decomposition.
- Tests concentrated on helpers while the orchestration remains untested.
- Scope added only because it might be useful later.

Refactor when these increase meaningful change cost. Do not refactor solely to satisfy a line-count target.

## Review-response protocol

When receiving a finding:

1. Reproduce or trace the alleged execution path.
2. Identify the invariant that would make the behavior correct.
3. Determine whether the current interface promises that invariant.
4. Fix the model or interface when the finding is real; avoid a symptom-only conditional.
5. Add one focused test at the interface.
6. If false, explain concretely which protocol, ordering, ownership, or idempotency fact prevents it.
7. Re-read nearby comments and tests for stale assumptions after the change.

## Completion standard

Before declaring work complete:

- Ensure dynamic input becomes trusted exactly once.
- Ensure illegal domain combinations are difficult to construct.
- Ensure the difficult behavior is concentrated behind a narrow interface.
- Ensure effects are bounded and failures preserve useful causes.
- Ensure real compatibility and reverse paths are handled.
- Ensure focused tests prove the stated invariants.
- Ensure the implementation remains the smallest coherent solution.

In the final handoff, name the principal invariant, the seam that owns uncertainty, and the focused verification performed. Mention any intentional tradeoff where completeness, compatibility, or speed increased complexity.
