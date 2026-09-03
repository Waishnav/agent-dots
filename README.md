# agent-dots

Version-controlled global agent instructions and skills, stowed into `$HOME`.
Mirrors the `~/dotfiles` (GNU Stow) workflow.

## Layout

Single Stow package `agents/` holds the whole tree. Canonical sources live in
one place; per-agent paths are symlinks to them:

- Instructions: `agents/.codex/AGENTS.md` is canonical.
  `agents/.claude/CLAUDE.md` and `agents/.config/opencode/AGENTS.md`
  symlink to it. `agents/AGENTS.md` (stows to `~/AGENTS.md`) is separate
  content (OS/dotfiles policy), not the same file.
- Skills: `agents/.agents/skills/<name>` is canonical. Per-agent skill dirs
  (`~/.codex/skills`, `~/.claude/skills`, `~/.config/opencode/skills`,
  `~/.pi/agent/skills`) symlink each skill back to it.

## Install

```bash
cd ~/agent-dots
./install.sh
```

Or one package explicitly: `./install.sh agents`.

## Verify

```bash
find ~ -xtype l | grep -E 'skills|AGENTS|CLAUDE'  # expect no output
```

## Known drift (not committed, reinstall via skill tool)

These were dangling symlinks with no surviving content at migration time,
so they are intentionally absent. Reinstall them and re-run `./install.sh`
to fold them back in:

- anthropic-frontend-design, figma, grill-me, frontend-design, find-skills,
  playwriter, gws-shared, gws-gmail, gws-calendar, minimalist-entrepreneur,
  subagent-delegation

Lockfiles (`.skill-lock.json`) record original install sources.

## External links

`~/.claude/skills/omarchy` points outside the repo (absolute path into
the omarchy install). Stow refuses absolute symlinks, so it is not part
of the stowed tree — `install.sh` creates it.

## Secrets policy

`*opencode.json*`, `auth.json`, `*.credentials.json`, `cli.json`,
`service.json`, sessions/caches/sqlite are gitignored. Commit
`*.example` templates instead if a config needs sharing.
