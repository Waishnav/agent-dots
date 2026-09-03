---
name: open-pr
description: Use when the user asks to file, open, or create a PR
---

# Open PR

Before filing, check whether a PR for the branch already exists. Read repository instructions and any PR template, inspect the final diff against the intended base, and confirm the branch contains one coherent concern. Never open or update a PR unless the user explicitly requested that remote action.

## Prepare the PR

1. Identify the intended base branch and review the full diff against it.
2. Inspect recent merged PRs and git history for repository-specific title conventions.
3. Check for unrelated changes, generated files, debug output, secrets, migration requirements, configuration changes, and user-facing documentation drift.
4. Run the smallest relevant verification required by the repository before filing. Keep verification results in the agent's handoff, not in the PR body.
5. Push only when the user has explicitly requested filing the PR and pushing is a necessary part of that workflow.
6. Update an existing PR for the branch instead of opening a duplicate.

## Write the title

Follow the repository's established convention. Prefer a concise, human-readable title that explains the outcome or why the change matters. Use a Conventional Commit-style title only when that matches the repository.

Prefer:

> fix(workflow): stop nested calls from exceeding the run limit

Avoid:

> refactor(workflow): add shared atomic counter and semaphore guard

## Write the body

Write for a human reviewer, not as an agent handoff.

Open with the user or system problem and its observable impact. Then briefly explain the chosen solution and any design decision a reviewer must understand. Derive the problem from the user's original request, issue, or product context rather than reverse-engineering a list of changed files.

Keep the body proportional to the change. A small PR often needs only one or two short paragraphs and no headings.

Include risks, migrations, rollout requirements, configuration changes, stacked-PR dependencies, important alternatives, or intentional limitations only when they materially affect review, deployment, or later work. Link the originating issue when one exists. Follow a required repository PR template, but keep its free-form prose concise and remove optional boilerplate that adds no review value.

Do not include:

- `Summary`, `Validation`, `Verification`, `Test plan`, `Commits`, `Commit structure`, `Files changed`, or `Implementation details` sections
- inventories of files, functions, classes, commits, tests, or implementation steps
- commands that were run, checklists of passing tests, or CI results
- claims that merely restate the diff
- generic filler such as "improves maintainability," "adds comprehensive tests," or "ensures robustness" without a concrete, review-relevant meaning
- agent attribution unless repository instructions explicitly require it

Add one of those sections only when the user explicitly asks for it or a repository template requires it. Even then, include only information that a reviewer cannot obtain directly from the diff or CI.

Prefer:

> A runaway workflow could make an unbounded number of agent calls, consuming resources indefinitely. Workflow runs now stop after 256 calls, including calls made by nested workflows, and report a clear call-limit error.

Avoid:

> ## Summary
>
> - enforce a hard budget of 256 agent calls
> - share the budget through the runtime
> - reject calls before semaphore acquisition
>
> ## Validation
>
> - npm test
> - npm run build

## Open or update the PR

Use the prepared title and body without inventing additional sections at submission time. Open a ready PR by default when the implementation and verification are complete. Use a draft only when the user asks for one or the work is intentionally incomplete.

After submission, report the PR URL and keep the local handoff separate: summarize what changed, verification performed, and anything unresolved there rather than copying that operational report into the PR description.
