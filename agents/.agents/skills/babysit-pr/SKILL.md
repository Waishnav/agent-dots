---
name: babysit-pr
description: Monitor a PR through review and CI. Use when the user asks to monitor, watch, or babysit a PR.
---

# Babysit PR

Review bots are useful, even tho they are not always right.

Use the harness's PR monitoring tools when available. Otherwise, poll the PR for new comments, unresolved threads, checks, merge conflicts, and changes to the base branch using gh cli

Before acting, read the repository instructions, original request or linked issue, PR description, complete diff, and existing review conversation. Record the latest head commit and inspect required checks, requested changes, unresolved review threads, and mergeability.

Verify every finding against the current source before changing code. Ignore bot summaries, release-note comments, obsolete findings, and feedback already addressed by later code. Do not ignore a relevant unresolved thread merely because it predates the latest push.

Prioritize security, data integrity, functional correctness, concurrency, lifecycle, and compatibility findings over stylistic cleanup. Fix valid in-scope findings and CI failures at the correct boundary rather than blindly applying the suggested patch. Add focused regression coverage and run the smallest verification that proves the changed behavior. After the last fix, rerun every check affected by the accumulated changes.

If a finding is partly valid, adopt the useful part and explain why the rest conflicts with the design or security boundary. If a finding is incorrect or obsolete, leave the code unchanged and reply with concrete evidence. If it is valid but outside the PR's goal, explain the boundary and defer it rather than expanding the PR. Do not let review feedback introduce optional abstractions, unrelated cleanup, or speculative compatibility work.

Inspect the working tree before editing and preserve unrelated work. Commit and push only coherent babysitting fixes. Do not claim a runtime issue is fixed when it was only type-checked or built.

Reply to every actionable thread after the relevant fix is pushed. Mention the commit and briefly state the behavioral fix and regression proof. For rejected, partially adopted, or deferred suggestions, give the technical reason. Resolve the thread when appropriate, but leave human change requests open when only the reviewer should decide acceptance.

For a valid finding, explain the fix and its proof:

> Fixed in `12cee07`. The bridge now recreates asynchronous results inside the VM realm, preventing constructor-chain escapes. Added regression coverage for resolved values and rejected errors.

For a mixed suggestion, say what changed and why the rest did not:

> Partially adopted in `d4efd02`: child-entry resolution now fails immediately when substitution does not change the URL. The sandbox environment remains intentionally minimal so host secrets are not inherited.

For an incorrect finding, explain the existing contract:

> Not changing this. Every agent call still crosses the host bridge, where concurrency, journaling, cancellation, and replay are enforced. Keeping workflow closures inside the VM does not bypass those controls.

For valid work outside the PR's boundary, acknowledge it without silently expanding scope:

> Still relevant, but intentionally deferred to the UI follow-up. It does not affect workflow execution or the read-only snapshot contract, so it should not be mixed into the engine hardening PR.

When commenting on the user's behalf, format the reply as:

```md
[actual reply]

<details><summary>Agent info</summary>{MODEL-SLUG} through {HARNESS}</details>
```

After each push, refresh the head commit and wait for checks and review bots to evaluate that exact commit. Recheck unresolved threads rather than relying on cached comments or a bot's "addressed" marker. Distinguish repository failures from infrastructure flakes. Stay quiet when nothing has changed instead of posting filler comments.

Keep an eye on the base branch and update the PR when needed without rewriting shared history. If another PR makes this one obsolete, stop, report it, and ask before closing it.

Keep the title and description accurate when review changes materially alter the solution, risks, migrations, configuration, or rollout. Do not add verification inventories. Keep screenshots or recordings current when visible behavior changes.

Stop when required checks are green on the latest commit, no requested changes or actionable review threads remain, the PR is mergeable, and its description and evidence match the final behavior. Merge only when the user explicitly requested it; otherwise report that the PR is ready and note anything intentionally deferred.
