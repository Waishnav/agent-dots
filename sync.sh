#!/bin/bash
# sync.sh — fold $HOME-side additions (usually made by agents) back into agent-dots.
#
# What it does:
#   - New skill dirs/files under ~/.codex|claude|opencode|pi skills dirs
#     move to agents/.agents/skills/<name> (canonical), with a symlink left
#     for the harness where they were found (per-harness scoping preserved).
#   - New command files (*.md) move to the matching repo commands dir.
#   - Warns if an AGENTS.md/CLAUDE.md is a real file instead of a repo link
#     (an agent overwrote the symlink), or if a name collides with canonical.
#   - Never touches secrets, caches, sessions, or machine dirs (.system, ...).
#
# What it does NOT do: commit. Review `git status`, then commit + push.
# Usage: ./sync.sh

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$REPO_ROOT/agents"

if ! command -v stow &> /dev/null; then
    echo "[-] GNU Stow is required. Install with: sudo pacman -S stow" >&2
    exit 1
fi

# harness skills subdir -> relative link prefix (from repo subdir to canonical)
declare -A PREFIX=(
    [".codex/skills"]="../../.agents/skills"
    [".claude/skills"]="../../.agents/skills"
    [".config/opencode/skills"]="../../../.agents/skills"
    [".pi/agent/skills"]="../../../.agents/skills"
)

SKIP_NAMES='^(\.system|\.git|node_modules|__pycache__|\.cache)$'
moved=0

for sub in "${!PREFIX[@]}"; do
    src="$HOME/$sub"
    [[ -d "$src" ]] || continue
    for entry in "$src"/*; do
        [[ -e "$entry" || -L "$entry" ]] || continue
        name="$(basename "$entry")"
        [[ "$name" =~ $SKIP_NAMES ]] && continue
        if [[ -L "$entry" ]]; then
            case "$(readlink "$entry")" in
                *agent-dots*) continue ;;  # managed link, nothing to do
            esac
            echo "[skip] foreign symlink (leaving alone): $sub/$name"
            continue
        fi
        if [[ -e "$REPO/$sub/$name" && ! -L "$REPO/$sub/$name" ]]; then
            continue  # intentional real-dir override committed in repo (e.g. pi web-perf)
        fi
        if [[ -e "$REPO/.agents/skills/$name" ]]; then
            echo "[conflict] $sub/$name already exists in canonical — merge manually:"
            echo "  diff -rq \"$entry\" \"$REPO/.agents/skills/$name\""
            continue
        fi
        echo "[adopt] $sub/$name -> .agents/skills/$name"
        mv "$entry" "$REPO/.agents/skills/$name"
        ln -s "${PREFIX[$sub]}/$name" "$REPO/$sub/$name"
        moved=$((moved + 1))
    done
done

# New command files
for pair in ".claude/commands:$HOME/.claude/commands" ".config/opencode/commands:$HOME/.config/opencode/commands"; do
    repo_sub="${pair%%:*}"
    home_dir="${pair##*:}"
    [[ -d "$home_dir" ]] || continue
    for entry in "$home_dir"/*.md; do
        [[ -e "$entry" || -L "$entry" ]] || continue
        name="$(basename "$entry")"
        [[ -L "$entry" ]] && continue  # managed link
        if [[ -e "$REPO/$repo_sub/$name" ]]; then
            echo "[conflict] $repo_sub/$name exists in repo — merge manually"
            continue
        fi
        echo "[adopt] $repo_sub/$name"
        mv "$entry" "$REPO/$repo_sub/$name"
        moved=$((moved + 1))
    done
done

# Instruction files must remain repo symlinks — flag real files
for f in "AGENTS.md" ".codex/AGENTS.md" ".claude/CLAUDE.md" ".config/opencode/AGENTS.md"; do
    target="$HOME/$f"
    if [[ -e "$target" && ! -L "$target" ]]; then
        echo "[warn] $f is a REAL file, not a repo link — an agent overwrote it:"
        echo "  diff \"$target\" \"$REPO/$f\""
    fi
done

if [[ "$moved" -gt 0 ]]; then
    echo "[+] Restowing..."
    stow -d "$REPO_ROOT" --target="$HOME" agents 2>&1 | grep -v "^BUG" || true
fi

echo "[+] Done ($moved adopted). Review and commit:"
echo "  cd $REPO_ROOT && git status --short"
