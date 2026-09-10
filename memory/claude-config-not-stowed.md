---
name: claude-config-not-stowed
description: Why base/claude/.config/claude/settings.json shows up dirty in git status without anyone editing it, and what the claude stow package does and does not contain
metadata:
  node_type: memory
  type: project
  originSessionId: 729541b5-93a7-433a-8023-12f62068b0c2
  modified: 2026-09-10T11:22:09.407Z
---

`~/.config/claude/settings.json` is a symlink into `base/claude/.config/claude/settings.json`
(linked 2026-09-03), so editing the repo file changes live config. Claude Code rewrites this
file itself, reordering keys and adding things like `modelSettings`, so it appears modified in
`git status` with no human edit.

The package is fully stowed and contains only that settings file and a README. It used to
carry a `.claude/` tree (CLAUDE.md, agents, commands, skills, enforcement hooks); those were
deleted, not deferred, because `CLAUDE_CONFIG_DIR` points at `$XDG_CONFIG_HOME/claude`, so
`~/.claude/` is never read and they were inert. Verified 2026-09-10 at commit 69de1de.

**Why:** the dirty file is the recurring confusion. Staging it silently commits whatever
Claude Code last wrote, which is why commits here use
`git add -A -- . ':!base/claude/.config/claude/settings.json'`.

**How to apply:** exclude that path when staging unless the change is deliberate; check the
diff before committing it. Do not recreate a `.claude/` half of this package without asking,
since it would be inert.
