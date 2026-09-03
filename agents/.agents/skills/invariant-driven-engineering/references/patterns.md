# Invariant-driven engineering patterns

## Contents

1. [Use the evidence, not the persona](#1-use-the-evidence-not-the-persona)
2. [Decode once at the seam](#2-decode-once-at-the-seam)
3. [Replace optional bags with domain states](#3-replace-optional-bags-with-domain-states)
4. [Make temporal state explicit](#4-make-temporal-state-explicit)
5. [Put policy in a pure core](#5-put-policy-in-a-pure-core)
6. [Test histories, not only snapshots](#6-test-histories-not-only-snapshots)
7. [Model errors as behavior](#7-model-errors-as-behavior)
8. [Design compatibility deliberately](#8-design-compatibility-deliberately)
9. [Extract ownership, not lines](#9-extract-ownership-not-lines)
10. [Write comments that preserve invariants](#10-write-comments-that-preserve-invariants)
11. [Respond to review rigorously](#11-respond-to-review-rigorously)
12. [Keep the good completeness; reject scope inflation](#12-keep-the-good-completeness-reject-scope-inflation)
13. [Use the final checklist](#13-use-the-final-checklist)

## 1. Use the evidence, not the persona

Treat “Fable-like” as shorthand for a set of observed engineering priors, not a request to imitate prose, verbosity, file size, or a model identity.

Prefer these observed strengths:

- Normalize different external protocols into one typed vocabulary.
- Create pure reducers, classifiers, converters, and cursor codecs.
- Treat ordering, replay, idempotency, and version skew as domain behavior.
- Bound concurrency, time, retained work, and external effects.
- Preserve failure causes and distinguish retryable from terminal outcomes.
- Explain non-obvious invariants in comments.
- Convert valid review findings into stronger invariants plus focused tests.

Actively correct these observed weaknesses:

- Letting `unknown` and optional record bags travel beyond adapters.
- Reconstructing state through conditions over unrelated fields or maps.
- Duplicating domain interpretation across clients and runtimes.
- Accumulating responsibilities in broad modules.
- Testing pure helpers deeply while leaving UI or transaction orchestration thinly covered.
- Adding compatibility, fallbacks, or extensions before a real need exists.

## 2. Decode once at the seam

### Bad: TypeScript used as guarded dictionaries

```ts
function renderActivity(activity: { payload: unknown }) {
  if (typeof activity.payload !== "object" || activity.payload === null)
    return null;

  const payload = activity.payload as Record<string, unknown>;
  const taskId =
    typeof payload.taskId === "string" ? payload.taskId : undefined;
  const status =
    typeof payload.status === "string" ? payload.status : undefined;

  if (taskId && status === "running") {
    return `Running ${taskId}`;
  }

  return null;
}
```

This can be locally safe while creating a weak system. Every consumer must know external keys, missing-field behavior, and string values.

### Worse: repeat the same interpretation in several surfaces

```ts
// server
const isAgent = typeof payload.agentId === "string";

// web
const isAgent = typeof payload.agentId === "string";

// mobile
const isAgent = typeof payload.agentId === "string";
```

This destroys locality. A provider change requires coordinated edits and permits semantic drift.

### Good: decode and normalize once

Use the repository's established schema library. With Effect Schema, the shape might be:

```ts
const AgentTaskEvent = Schema.Struct({
  type: Schema.Literal("agent-task"),
  taskId: TaskId,
  status: Schema.Literal("pending", "running", "idle", "completed", "failed"),
  parentTaskId: Schema.optional(TaskId),
});

type AgentTaskEvent = typeof AgentTaskEvent.Type;

const decodeAgentTaskEvent = Schema.decodeUnknown(AgentTaskEvent);
```

Place provider-specific interpretation inside an adapter:

```ts
function adaptProviderNotification(
  input: unknown,
): Result<AgentTaskEvent, ProviderDecodeError> {
  // Validate provider shape here, then return only the domain event.
}
```

Let downstream modules accept only `AgentTaskEvent`.

### Acceptable `isRecord`

Use `isRecord` inside one compact parser when the external shape is genuinely open or partially documented:

```ts
function parseExternalTheme(input: unknown): ThemeDefinition {
  if (!isRecord(input)) throw new ThemeDecodeError("Expected an object");
  const colors = isRecord(input.colors) ? input.colors : {};
  return makeValidatedTheme(colors);
}
```

Make the parser return a complete trusted value. Do not expose the input record or require callers to repeat the guards.

### Seam test

Search the ordinary domain and UI layers for:

```text
unknown
Record<string, unknown>
isRecord(
as Record<
```

Treat matches outside adapters, codecs, diagnostics, and tests as design-review candidates—not automatic defects.

## 3. Replace optional bags with domain states

### Bad: meaning emerges from combinations

```ts
type TaskLinkage = {
  taskId?: string;
  agentId?: string;
  workflowId?: string;
  phaseIndex?: number;
  monitorId?: string;
};
```

This permits contradictory or meaningless values. Callers need conditions and comments to rediscover the intended variants.

### Good: make variants explicit

```ts
type TaskLinkage =
  | { type: "agent"; taskId: TaskId; agentId: AgentId; parentAgentId?: AgentId }
  | {
      type: "workflow";
      taskId: TaskId;
      workflowId: WorkflowId;
      phaseIndex: number;
    }
  | { type: "monitor"; taskId: TaskId; monitorId: MonitorId };
```

Use an exhaustive match or switch. Adding a variant should create compile-time work at consumers that genuinely need a decision.

### Bad: paired fields admit illegal state

```ts
type Settlement = {
  settledOverride: boolean | null;
  settledAt: string | null;
};
```

### Good: encode the actual lifecycle

```ts
type Settlement =
  | { status: "unsettled" }
  | { status: "settled"; at: Instant; source: "user" | "activity-policy" };
```

Do not introduce a union if the fields are truly independent. Model the domain, not a preference for fancy types.

## 4. Make temporal state explicit

### Bad: several containers form an invisible machine

```ts
const identities = new Map<TurnId, AgentId>();
const receiverTurns = new Map<TurnId, TurnId>();
const liveChildren = new Set<TurnId>();

if (identities.has(turnId)) {
  // ...
} else if (receiverTurns.has(turnId)) {
  // ordering-sensitive recovery path
}
```

The legal states and transitions exist only in condition ordering.

### Better: one explicit state per identity

```ts
type ChildState =
  | { status: "discovered"; childTurnId: TurnId }
  | { status: "registered"; childTurnId: TurnId; agentId: AgentId }
  | {
      status: "active";
      childTurnId: TurnId;
      agentId: AgentId;
      parentTurnId: TurnId;
    }
  | {
      status: "settled";
      childTurnId: TurnId;
      agentId: AgentId;
      outcome: Outcome;
    };
```

Use a pure transition:

```ts
function transitionChild(
  state: ChildState | undefined,
  event: ChildEvent,
): ChildState {
  // Exhaustively encode late discovery, retry, duplicate, and terminal behavior.
}
```

Keep secondary indexes only for lookup performance. Derive or update them from the authoritative state; do not let them independently define truth.

### Use conditions for real conditions

Do not eliminate `if`. Prefer clear guard clauses for validation, bounds, and exceptional exits. Reject conditions that compensate for a missing domain state or repeated decoding.

## 5. Put policy in a pure core

### Bad: mix parsing, policy, storage, and effects

```ts
async function handleNotification(raw: unknown) {
  const payload = parse(raw);
  if (payload.status === "completed") {
    await database.update(...);
    await socket.send(...);
    cache.delete(...);
  }
}
```

Tests must mock every effect to verify one transition.

### Good: separate decision from execution

```ts
type Decision =
  | { type: "ignore" }
  | { type: "persist-and-publish"; next: TaskState; event: DomainEvent };

function decide(state: TaskState, event: TaskEvent): Decision {
  // Pure ordering, idempotency, retry, and terminal policy.
}

async function handleNotification(raw: unknown) {
  const event = await adapter.decode(raw);
  const current = await repository.get(event.taskId);
  const decision = decide(current, event);
  await execute(decision);
}
```

Keep the external interface narrow. Do not export every helper merely to unit-test it; test the module through the same seam callers use.

## 6. Test histories, not only snapshots

For a stateful fold, reducer, synchronizer, cache, or queue, derive tests from valid histories:

```ts
it("keeps the first terminal outcome when completion is duplicated", ...)
it("enriches terminal state when start metadata arrives late", ...)
it("counts a retry once after a failed attempt", ...)
it("drops an older page when a revert advances the history epoch", ...)
it("does not strand a partial cache when reconnecting to an older server", ...)
```

Avoid tests that merely mirror implementation branches. Assert user-visible or persisted outcomes.

Use this temporal matrix selectively:

| Dimension     | Cases                                                        |
| ------------- | ------------------------------------------------------------ |
| Ordering      | normal, reversed, interleaved                                |
| Multiplicity  | duplicate, replay, coalesced                                 |
| Retention     | missing start, missing terminal, partial history             |
| Lifecycle     | retry, cancellation, idle/resume, terminal enrichment        |
| Concurrency   | stale response, event during merge, disconnect during work   |
| Compatibility | old client/new server, new client/old server, rollback cache |
| Failure       | first write fails, second write fails, compensation fails    |

Do not write every matrix cell automatically. Select cases that threaten a stated invariant.

## 7. Model errors as behavior

### Bad: erase the cause

```ts
try {
  return await readFile(path);
} catch {
  throw new Error("Could not read workflow");
}
```

### Good: preserve classification and cause

```ts
class WorkflowReadError extends Data.TaggedError("WorkflowReadError")<{
  reason: "not-found" | "outside-root" | "too-large" | "io";
  path: string;
  cause?: unknown;
}> {}
```

Expose only distinctions callers can act on. Preserve lower-level causes for diagnostics without leaking implementation-specific exceptions as the domain interface.

For multi-step writes, choose deliberately:

- Use a real transaction when the storage supports it.
- Compute and write one atomic value when practical.
- Use compensation only when it can reconstruct the previous state.
- If partial success is inherent, return it explicitly instead of claiming all-or-nothing behavior.

Bound external work with timeouts, concurrency limits, queue sizes, or retained-row caps when unbounded behavior can harm the system. Ensure timeout or cancellation does not violate ownership.

## 8. Design compatibility deliberately

Write down the compatibility matrix before adding machinery:

| Client             | Server    | Expected behavior                              |
| ------------------ | --------- | ---------------------------------------------- |
| old                | old       | unchanged                                      |
| old                | new       | default/full behavior                          |
| new                | old       | omit unsupported parameters and degrade safely |
| new                | new       | enable capability                              |
| rolled-back client | new cache | reject or migrate partial state safely         |

Prefer explicit capability advertisement over trial-and-error requests. Reset session-scoped capability state on disconnect. Version persisted data when an older binary could misinterpret a partial or semantically changed record as complete.

Do not add compatibility aliases for versions that never shipped or mixed states that cannot occur.

## 9. Extract ownership, not lines

### Shallow cleanup

```text
LargeSettings.tsx
  ↓ pure code movement
ColorPicker.tsx
Editor.tsx
ImportDialog.tsx
LargeSettings.tsx
```

This improves navigation but may leave state, persistence, rollback, and rendering knowledge spread across props and imports.

### Deeper cleanup

Identify coherent responsibilities and their interfaces:

```text
ThemeDefinition codec
  unknown file -> ThemeDefinition | ThemeDecodeError

ThemeLibrary
  list/install/update/remove definitions

ThemeSelection
  resolve/apply one stored selection atomically

ThemeEditor session
  draft lifecycle -> save decision | cancel restoration
```

Keep implementation details private. Apply the deletion test: if deleting the module spreads its complexity into several callers, it earns its seam.

Do not use file length as the sole metric. Split when a module has unrelated reasons to change, duplicated knowledge, or an interface nearly as complicated as its implementation.

## 10. Write comments that preserve invariants

### Weak

```ts
// Set loading to true.
loading = true;
```

### Strong

```ts
// Keep loading true while an ahead-of-stream page is parked. This prevents a
// second fetch from replacing the single pending page before the live stream
// reaches its watermark.
loading = true;
```

Comment ordering constraints, ownership, compatibility, performance bounds, intentional information loss, and counterintuitive tradeoffs. Update comments and test titles when review changes the implementation.

## 11. Respond to review rigorously

For each finding:

1. Trace the real input through adapter, domain transition, persistence, and consumer.
2. Confirm whether the alleged interleaving or state is reachable.
3. Name the missing or already-satisfied invariant.
4. Fix at the earliest seam that can enforce it for every caller.
5. Add one deterministic regression test.
6. Recheck adjacent reverse and compatibility paths.

Avoid both extremes:

- Do not accept every bot suggestion and layer conditions blindly.
- Do not dismiss a finding because the happy path appears correct.

For a false positive, explain the exact fact that prevents it: disjoint identity sets, normalized URL behavior, idempotent replacement, ownership checks, or protocol filtering.

## 12. Keep the good completeness; reject scope inflation

Completeness is valuable when it closes a real state space:

- Add the reverse transition for a new state.
- Handle an actually supported provider.
- Preserve rollback behavior for a shipped cache version.
- Bound a process that can genuinely hang or grow.

Completeness becomes harmful when it invents surface area:

- Supporting hypothetical providers through unused interfaces.
- Adding compatibility aliases for unshipped versions.
- Building an editor, import format, and plugin seam for a requirement that only needs one configuration value.
- Solving every review-adjacent enhancement in the same change.

Ask before expansion:

1. Is this required for the requested behavior to be coherent?
2. Can this state occur in a supported configuration?
3. Would omitting it create a one-way door, data loss, or misleading interface?
4. Can a smaller model make the behavior unsurprising?

## 13. Use the final checklist

### Typed seam

- [ ] Validate dynamic input once.
- [ ] Return a named trusted type.
- [ ] Keep record inspection out of consumers.
- [ ] Preserve useful decode causes without leaking raw exceptions.

### Domain

- [ ] Represent mutually exclusive states explicitly.
- [ ] Make closed sets exhaustive.
- [ ] Avoid optional combinations with undocumented meaning.
- [ ] Centralize the authoritative state machine.

### Effects and time

- [ ] Define duplicate, replay, retry, cancellation, and terminal behavior.
- [ ] Bound work and retained state.
- [ ] Serialize conflicting mutations deliberately.
- [ ] Make partial failure or rollback honest.

### Architecture

- [ ] Give each module one responsibility.
- [ ] Keep the interface smaller than the knowledge hidden behind it.
- [ ] Use concrete adapters at real seams.
- [ ] Centralize cross-surface policy.

### Verification

- [ ] Test stated invariants through the interface.
- [ ] Use deterministic interleavings instead of sleeps.
- [ ] Cover real version-skew states.
- [ ] Test complex orchestration, not only pure helpers.

### Restraint

- [ ] Remove dead paths and stale comments.
- [ ] Avoid hypothetical extensibility.
- [ ] Avoid pure movement disguised as deepening.
- [ ] Stop at the smallest coherent implementation.
