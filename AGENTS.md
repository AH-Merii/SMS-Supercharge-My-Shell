# SMS Supercharge-My-Shell

Dotfiles for fish, neovim, tmux, git and a niri desktop. `README.md` describes the layout,
the profiles and the tasks.

## Agent skills

### Issue tracker

Issues live in GitHub Issues for `AH-Merii/SMS-Supercharge-My-Shell`, worked through the
`gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage labels, unchanged: `needs-triage`, `needs-info`,
`ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` at the repo root and ADRs under `docs/adr/`, neither
created yet. See `docs/agents/domain.md`.

## Agents and tests

Lessons from multi-agent jobs. Read the file whose row matches before you start.

| When you | Read |
|---|---|
| run background agents (briefs, integration, watchdog, waiting) | `docs/agents/orchestrating-agents.md` |
| test on the live machine (launchers, leaks, post-run checks) | `docs/agents/sandbox-isolation.md` |
| add, run or keep checks in a suite | `docs/agents/test-suites.md` |
| test Neovim headless or in a GUI | `docs/agents/neovim-testing-notes.md` |
