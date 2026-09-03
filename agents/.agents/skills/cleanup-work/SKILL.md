---
name: cleanup-work
description: Audit, harden, and simplify an existing implementation after an AI-generated or broad first pass. Use when Codex is asked to clean up work, perform a reliability pass, prepare code for merge, address review findings, reduce GPT-style TypeScript such as repeated unknown/isRecord guards or condition-heavy orchestration, or investigate races, duplicated truth, lifecycle gaps, weak adapter boundaries, performance regressions, and feature-overhaul fallout.
---

# Cleanup Work

Perform a semantic second pass over an existing change. Preserve good architecture, repair missing invariants, and remove complexity made unnecessary by the stronger model. Do not equate cleanup with formatting, file splitting, or adding abstractions.

For stateful, concurrent, protocol-facing, cross-platform, or broad changes, read [references/audit-matrix.md](references/audit-matrix.md) completely before proposing edits.

## Respect the requested mode

- For review, analysis, or diagnosis, inspect and report; do not edit.
- For cleanup, fixing, hardening, or implementation, edit the smallest coherent scope and verify it.
- Treat unrelated worktree changes as user-owned. Do not erase or reformat them.

## Classify scope before editing

Assign every candidate change one purpose:

- **Repair:** restore behavior lost or broken by the implementation.
- **Harden:** make ordering, failure, lifecycle, protocol, or compatibility behavior deliberate.
- **Simplify:** remove redundant state, parameters, paths, copies, or abstractions.
- **Enhancement:** add new product behavior.

Implement repair, hardening, and simplification. Exclude enhancement unless the user requested it or it is required to make the existing behavior coherent. When uncertain, report it separately instead of smuggling it into cleanup.

## Workflow

### 1. Reconstruct the change

Read the originating diff or branch history before judging the final files. Trace the changed behavior through its contracts, adapters, state owner, effects, consumers, tests, and applicable surfaces.

Resolve the comparison point explicitly. Prefer the user-supplied base, PR base, or merge-base with the target branch. If only a commit is supplied, inspect its parents and adjacent commits, choose the smallest contiguous range supported by the evidence, and state the assumption. Do not pull unrelated merged ancestry into the audit.

Record:

- The requested behavior and what the first pass actually changed.
- Trusted inputs and genuinely untrusted boundaries.
- Authoritative state and any derived or copied state.
- Resource owners and teardown paths.
- Performance-sensitive paths.
- Real platform, provider, browser, or version combinations.

Do not rewrite an implementation merely because another model authored it. Preserve parts whose interfaces and invariants are already sound.

### 2. Build a cleanup ledger

For each real problem, write a compact ledger entry:

```text
Purpose: repair | harden | simplify
Evidence: reachable execution path or reproducible counterexample
Invariant: fact that must remain true
Owner: earliest seam able to enforce it for every caller
Change: smallest coherent correction
Proof: focused test or deterministic verification
```

Reject findings based only on taste, line count, hypothetical extensibility, or a search match.

### 3. Repair the model before symptoms

Prefer these transformations when supported by evidence:

- Captured value crossing an async boundary → re-read authoritative state at the point of use.
- UI flags approximating lifecycle → derive from the domain entity's lifecycle.
- Generic protocol boolean or heuristic → query and represent the exact protocol fact.
- Parallel implementations → normalize through one semantic adapter or display model.
- Several fields, maps, or refs forming an implicit machine → one explicit state and transition owner.
- Duplicated configuration or version → one source of truth with executable convergence checks.
- Competing effect paths → one owner or serialization mechanism.
- Partial initialization or deferred work → explicit failure and teardown policy.

Delete parameters, branches, state, files, invalidation inputs, and alternate UI paths made obsolete by the stronger model.

### 4. Contain dynamic TypeScript

Keep `unknown`, `Record<string, unknown>`, `isRecord`, manual key inspection, and casts at genuine external seams such as JSON, storage, IPC, databases, environment variables, or provider protocols.

Decode once into a named trusted type. Ordinary domain, orchestration, and UI code must not reinterpret the same external record. Do not ban `unknown` or `if`; reject their repeated use as substitutes for a domain model.

Prefer:

- Discriminated unions for mutually exclusive states.
- Exhaustive mappings for closed sets.
- Branded or validated identifiers where identity confusion is harmful.
- Pure derivations or transitions for ordering-sensitive policy.
- Narrow adapters for real platform or provider differences.

Avoid replacing a small conditional with an abstraction that hides no meaningful complexity.

### 5. Audit time, ownership, and bounds

Exercise relevant counterexamples from the audit matrix. Pay particular attention to:

- State captured before `await`, callbacks, queued work, or mount completion.
- Values captured when starting fire-and-forget, forked, deferred, or callback-driven effects, even when no local `await` appears.
- Duplicate, delayed, reordered, missing, or replayed events.
- Overlapping async operations and which result wins.
- Focus, keyboard, scroll, selection, recycling, remount, disconnect, and disposal.
- Debounce/throttle final-state policy and hot-path effect frequency.
- Failed reads followed by writes, partial persistence, and stale callbacks.
- IDs allocated from incomplete or lagging sources.

Define one winner, owner, bound, or compensation rule rather than layering guards across callers.

### 6. Verify the invariant

Add the smallest focused proof at the interface that owns the behavior. Prefer deterministic counterexamples over sleeps and broad snapshots.

Test the risky history, not merely the final state. Examples include:

- A new send begins before its server turn exists.
- A webview swaps during a state update.
- An older async result completes after a newer request.
- A recycled row receives another entity.
- A resource is disposed inside a debounce window.
- An external read fails before a later save.
- A protocol flag differs from a tempting heuristic.

Run only relevant repository checks unless the user requests a wider suite.

### 7. Review the cleanup itself

Re-read the final diff as hostile input. Check for:

- A fix applied too broadly, defeating a debounce, cache, or render bound.
- Callback dependencies still closing over old state.
- New global registries, optional escape hatches, variant-heavy shared components, or lint suppressions.
- Repeated `unknown`, `isRecord`, string dispatch, casts, or manual copying outside the decoder.
- Comments or tests describing an earlier iteration.
- Feature groundwork or polish unrelated to the invariant.
- Helper tests passing while the integration path remains unproved.

If cleanup introduced a new problem, correct it before handoff. Iterative self-review is part of the workflow, not evidence of failure.

## Handoff

For edit mode, report:

- What was repaired, hardened, and simplified.
- The principal invariants and their owning seams.
- Focused verification performed.
- Enhancements deliberately excluded.
- Remaining risks or findings that lacked evidence.

For review-only mode, report proposed repairs by severity, the evidence and invariant for each, verification that should be added, assumptions about the comparison range, and checks not run. Do not phrase proposals as completed changes.

Do not call code “clean” merely because it is more abstract. Explain how the result reduces change cost or makes incorrect states and interleavings harder to express.
