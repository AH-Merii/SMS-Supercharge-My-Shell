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
- Edit source files in SMS repo, then: `cd ~/SMS-Supercharge-My-Shell && stow claude`
- Fallback: ~/.config/claude/ -> ~/.claude/

# Mistake Log

When an agent makes a mistake, document it here so future sessions avoid repeating it.
This follows Hashimoto's "harness engineering" pattern: fix the system, not just the symptom.

- Sandbox blocks 1Password agent socket -- use allowUnixSockets, not dangerouslyDisableSandbox
- `WebFetch(domain:X)` rules do NOT propagate to Bash commands -- also add to sandbox.network.allowedDomains
- When user says "swarm", they mean 10+ agents minimum, not 3

# Context Management

- Use `/clear` between unrelated task phases to prevent context degradation
- For long tasks, summarize progress before clearing so the next context window has orientation
- Prefer project-level CLAUDE.md for architecture notes; keep global CLAUDE.md for universal rules
