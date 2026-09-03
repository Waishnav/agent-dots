# Cleanup audit matrix

Use only dimensions relevant to the changed behavior. State the threatened invariant before adding a test or mechanism.

## Contents

1. Change reconstruction
2. State and type boundaries
3. Temporal behavior
4. Effects and ownership
5. Performance and UI lifecycle
6. Compatibility and identity
7. Restraint and self-review

## 1. Change reconstruction

- Read the original diff, not only the final file.
- Identify behavior lost during broad rewrites.
- Separate inherited defects from problems introduced during cleanup.
- Distinguish model-attributed commits from unattributed or merged ancestry.
- Compare comments and tests with the current execution path.

## 2. State and type boundaries

| Question | Warning sign | Preferred correction |
|---|---|---|
| Where does input become trusted? | Several consumers call `isRecord` | Decode once at one adapter |
| What state is authoritative? | Caller snapshots or copied booleans | Re-read or derive at point of use |
| Are variants mutually exclusive? | Optional-field bag | Discriminated union when the domain warrants it |
| Is a closed set complete? | String `if/else` dispatch | Exhaustive typed mapping or switch |
| Is identity canonical? | IDs derived from partial display data | Validated canonical representation |

Search hits for `unknown`, `Record<string, unknown>`, `isRecord`, casts, and condition chains are review candidates, not automatic defects.

## 3. Temporal behavior

Consider:

- Normal, reversed, and interleaved order.
- Duplicate, replayed, coalesced, and missing events.
- A stale result completing after a fresh result.
- State changing between an initial read and a side effect.
- Cancellation or disposal while work is pending.
- Retry after partial or terminal state.
- Attach after the resource has already completed or exited.
- Reconnect, remount, reload, rollback, and recycled-instance reuse.

Useful policies include epochs, serialized queues, idempotent replacement, canonical lifecycle derivation, and point-of-use reads. Choose one policy that matches the invariant; do not combine mechanisms reflexively.

## 4. Effects and ownership

- Which component owns each listener, timer, process, allocation, subscription, or session?
- Does every partial initialization path free what it acquired?
- Does teardown cancel, flush, persist, or intentionally discard pending work?
- Are there two channels performing the same external effect?
- Can a failed read be mistaken for an empty successful value and overwrite valid state?
- Is lower-level failure classification preserved when callers need it?
- Are external calls bounded by a real timeout, queue, concurrency, or retained-state limit?

## 5. Performance and UI lifecycle

- What rerenders, remounts, reallocates, or crosses a bridge on every event?
- Does context or `extraData` invalidate every row for state consumed by one child?
- Can recycled local state leak to another entity?
- Does resize repaint stale pixels for one frame?
- Does a debounce still debounce after cleanup?
- Are scroll, focus, keyboard, selection, IME, hover, and pointer capture preserved?
- Is derived geometry computed in one coordinate space and updated atomically with its consumers?

Treat dropped frames, scroll jumps, stale labels, focus loss, and duplicate RPCs as correctness failures when users can observe them.

## 6. Compatibility and identity

- Query exact protocol capabilities or flags instead of approximating them.
- Test actual browser or platform differences that the code supports.
- Keep platform details behind a typed adapter when semantics are shared.
- Do not invent compatibility for versions or providers that cannot coexist.
- Allocate IDs from every authoritative and locally pending source.
- Make artifacts identify their own provenance when copied metadata can drift.

## 7. Restraint and self-review

Reject or separate:

- Configurability groundwork without a current requirement.
- New fonts, polish, controls, or platform features discovered during cleanup.
- A global registry introduced to avoid understanding ownership.
- A broad shared component whose variants preserve most duplication as branches.
- Complexity suppressions used instead of assessing the state model.
- File movement whose new interface hides no knowledge.

After the fix, replay the original counterexample and inspect neighboring reverse paths. Then inspect the cleanup for a new counterexample of its own.
