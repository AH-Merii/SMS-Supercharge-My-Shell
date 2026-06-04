---
description: Trusted sources and methodology for researching Claude Code configuration, workflows, sandbox settings, and permissions
autoActivateWhen: user asks about Claude Code configuration, sandbox permissions, settings.json, allowedDomains, hooks, Claude Code workflows, custom agents, subagents, agent teams, or agent design best practices
---

# Claude Code Configuration Research

## Trusted Sources

When researching Claude Code configuration, sandbox settings, permissions, workflows, or best practices, prioritize content from these high-quality authors:

| Author             | Focus Areas                                             | Where to Find                |
| ------------------ | ------------------------------------------------------- | ---------------------------- |
| Simon Willison     | LLM security, sandboxing, prompt injection, tool safety | simonwillison.net, Twitter   |
| Ben Davis          | Claude Code workflows, practical configuration          | Blog, Twitter                |
| Andrej Karpathy    | AI coding workflows, vibe coding, productivity          | Twitter (@karpathy), YouTube |
| Mitchell Hashimoto | Systems tooling, terminal (Ghostty), infra patterns     | mitchellh.com, Twitter       |
| Boris Cherny       | TypeScript, developer tooling, type-safe patterns       | Blog, Twitter                |

## Search Strategy

1. **Always append the current year** to searches (e.g., "Claude Code sandbox 2026") -- the meta changes very fast with frequent updates
2. **Prioritize sources from the last 3 months** over anything older; Claude Code ships breaking changes regularly
3. **Cross-reference with official docs** at code.claude.com/docs/en/ -- author advice may be outdated
4. **Check the changelog** at github.com/anthropics/claude-code/releases for recent setting changes

## Search Queries Template

For any Claude Code config topic, run these searches:

```
"<author name> Claude Code <topic>" (for each trusted author)
"Claude Code <topic> <current year>"
site:code.claude.com <topic>
site:github.com/anthropics/claude-code <topic>
```

## Official Documentation (Starting Points)

These are entry points -- always search for additional official docs specific to the topic at hand:

- Sandbox: code.claude.com/docs/en/sandboxing
- Permissions: code.claude.com/docs/en/permissions
- Settings: code.claude.com/docs/en/settings
- Security: code.claude.com/docs/en/security
- Hooks: code.claude.com/docs/en/hooks
- Changelog: github.com/anthropics/claude-code/releases

There are many more official doc pages beyond this list. When researching a specific topic, also search code.claude.com/docs/en/ for relevant pages not listed here.

## Key Config File Locations (Lookup Order)

When reading or editing config files, check locations in this order:

1. **Stow source (canonical):** `~/SMS-Supercharge-My-Shell/claude/` -- edit here first, then re-stow
2. **Symlink target:** `~/.config/claude/` -- usually a symlink from step 1
3. **Fallback default:** `~/.claude/` -- for settings.local.json or files not managed by stow

| File                                                            | Purpose                                           |
| --------------------------------------------------------------- | ------------------------------------------------- |
| `~/.config/claude/settings.json`                                | Global user settings (stow-managed from SMS repo) |
| `~/.claude/settings.local.json`                                 | Machine-local overrides (not in git)              |
| `.claude/settings.json`                                         | Project shared settings                           |
| `.claude/settings.local.json`                                   | Project local overrides                           |
| `/Library/Application Support/ClaudeCode/managed-settings.json` | Org-managed (macOS)                               |
