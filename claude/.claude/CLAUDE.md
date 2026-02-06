# Runtime Preferences

- Always use bun/bunx instead of npm/npx/node
- Always use uv run/uv pip instead of raw python/pip
- Use the built-in Grep tool or rg -- never raw grep
- Use the built-in Glob tool or fd -- never raw find

# Workflow

- For tasks with 3+ steps, use TaskCreate to track progress
- Launch parallel research/explore agents with run_in_background: true -- plan ALL search angles upfront in a single message, never drip-feed agents
- Prefer parallel tool calls over sequential when no dependencies exist
- For non-trivial tasks, start in Plan mode and pour energy into the plan
- Verify before committing: run tests, lint, and typecheck first
- When correcting a repeated mistake, suggest updating CLAUDE.md so it doesn't recur

# Dotfiles (GNU Stow)

- Source: ~/SMS-Supercharge-My-Shell/claude/
- Edit source files in SMS repo, then: stow -vt ~ claude
- Fallback: ~/.config/claude/ -> ~/.claude/
