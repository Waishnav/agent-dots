#!/bin/bash
# agent-dots installer using GNU Stow (mirrors ~/dotfiles/install.sh)
# Usage: ./install.sh [package...]
# If no packages specified, installs all (currently: agents)

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; }

if ! command -v stow &> /dev/null; then
    error "GNU Stow is required. Install with: sudo pacman -S stow"
    exit 1
fi

if [[ $# -gt 0 ]]; then
    SELECTED=("$@")
else
    SELECTED=(agents)
fi

cd "$DOTFILES_DIR"

for pkg in "${SELECTED[@]}"; do
    if [[ -d "$pkg" ]]; then
        log "Stowing $pkg..."
        stow -v --target="$HOME" "$pkg" 2>&1 | grep -v "^BUG" || true
    else
        warn "Package '$pkg' not found, skipping"
    fi
done

log "Checking for dangling skill/instruction links..."
BROKEN=$(find "$HOME/.agents" "$HOME/.codex/skills" "$HOME/.claude/skills" "$HOME/.config/opencode" "$HOME/.pi" -xtype l 2>/dev/null || true)
if [[ -n "$BROKEN" ]]; then
    warn "Dangling links found:"
    echo "$BROKEN"
else
    log "No dangling skill/instruction links."
fi

# External absolute symlink (stow refuses absolute symlinks, so it lives
# outside the stowed tree and is managed here).
OMARCHY_SRC="$HOME/.local/share/omarchy/default/omarchy-skill"
OMARCHY_DST="$HOME/.claude/skills/omarchy"
if [[ -e "$OMARCHY_SRC" ]]; then
    if [[ ! -L "$OMARCHY_DST" ]]; then
        log "Linking external omarchy skill..."
        ln -s "$OMARCHY_SRC" "$OMARCHY_DST"
    fi
else
    warn "Omarchy skill source missing: $OMARCHY_SRC"
fi

log "Done!"
