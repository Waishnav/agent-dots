---
name: stacked-prs
description: Create and manage GitHub stacked PRs with gh stack. Use for stacked/dependent PRs, multi-layer PR workflows, cascading rebase, or breaking a large change into reviewable layers.
---

# Stacked PRs (`gh stack`)

Public preview. Same-repo only (no forks). Auto-merge unsupported.

## Model

```
top    feat/ui   → PR base: feat/api
       feat/api  → PR base: feat/auth
bottom feat/auth → PR base: main (trunk)
```

Dependencies go **down**. Merge **bottom-up only**. Each PR shows only its layer's diff. Split when concern changes (schema → API → UI) or a layer is already large enough to review alone.

## Commands

| Do | Command |
| --- | --- |
| Start | `gh stack init [branches...] [-b trunk]` |
| Next layer | `gh stack add [branch] [-Am "msg"]` (from top only) |
| Push + open PRs | `gh stack submit [--auto] [--open]` |
| Sync after merges | `gh stack sync [--prune]` |
| Cascade rebase | `gh stack rebase [--upstack\|--downstack]` then `gh stack push` |
| Navigate | `gh stack up/down [n]`, `top`, `bottom`, `trunk`, `switch` |
| Check out stack | `gh stack checkout [stack#\|PR#\|URL\|branch]` |
| Restructure | `gh stack modify` then `submit` |
| Merge | `gh stack merge [stack#\|PR#] [--yes] [--squash]` |
| Dissolve | `gh stack unstack [--local]` |
| Inspect | `gh stack view [--json]` |
| No local tracking | `gh stack link <bottom> … <top>` (jj/Sapling/etc.) |

## Agent flow

```bash
gh stack init feat/auth
# commit layer…
gh stack add -Am "API routes"
# commit layer…
gh stack submit --auto          # non-TTY; add --open if not draft
```

Adopt existing branches bottom → top: `gh stack init b1 b2 b3 && gh stack submit --auto`.

**Fix mid-stack:** checkout owning branch → commit → `gh stack rebase --upstack` → `gh stack push`. Never paper over lower-layer bugs in an upper layer.

**After bottom merges:** `gh stack sync --prune`.

## Rules that bite

1. **`submit`** creates/updates PRs. **`sync`** never opens PRs — only syncs branches/state.
2. Merge is atomic bottom → chosen PR; can't merge an upper layer alone.
3. Linear history required. Signed-commit repos: rebase **locally** (server rebase doesn't sign).
4. Fully merged stack is closed — further `submit` starts a **new** stack at trunk.
5. `add` only from the top. `modify` needs a clean tree + linear history.
6. Never open remote PRs unless the user asked. Write each layer's title/body like `file-pr`.

Docs: https://gh.io/stacks
