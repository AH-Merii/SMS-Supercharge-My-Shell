# Claude Code Configuration

Global Claude Code configuration managed via [GNU Stow](https://www.gnu.org/software/stow/) from `~/SMS-Supercharge-My-Shell/claude/`.

Apply changes: `cd ~/SMS-Supercharge-My-Shell && stow -vt ~ claude`

## Directory Structure

```
claude/
├── .claude/                          # -> ~/.claude/
│   ├── CLAUDE.md                     # Global instructions (loaded every session)
│   ├── agents/
│   │   └── code-searcher.md          # Read-only code analysis agent
│   ├── commands/                     # Slash commands (/command-name)
│   │   ├── review-pr.md              # /review-pr <number>
│   │   ├── setup.md                  # /setup
│   │   └── spec.md                   # /spec <task description>
│   └── skills/                       # Auto-activating skills (on-demand context)
│       ├── ci-workflow/SKILL.md      # GitHub Actions conventions
│       ├── debugging/SKILL.md        # Systematic debugging pattern
│       ├── fish-shell/SKILL.md       # Fish shell scripting
│       ├── git-workflow/SKILL.md     # Conventional commits, PR workflow
│       └── stow-config/SKILL.md     # Dotfile management via stow
└── .config/claude/                   # -> ~/.config/claude/
    ├── settings.json                 # Permissions, hooks, sandbox, plugins
    └── hooks/
        ├── enforce-uv.sh            # Blocks raw python/pip -> use uv
        ├── enforce-rg.sh            # Blocks raw grep -> use Grep tool or rg
        ├── enforce-fd.sh            # Blocks raw find -> use Glob tool or fd
        ├── prettier-format.sh       # Auto-formats files on write/edit
        ├── check-actions-versions.sh # Validates GH Action versions on save
        ├── notify-stop.sh           # Bell + notification when Claude finishes
        ├── notify-notification.sh   # Bell + notification when Claude needs input
        ├── validate-env.sh          # Checks required tools on init/maintenance
        └── skill-eval.sh            # Suggests skills based on prompt keywords
```

## How It Works

### CLAUDE.md (always loaded)
Minimal instructions Claude can't infer on its own: runtime preferences (bun, uv, rg, fd), workflow patterns (task tracking, parallel agents), and stow conventions. Everything else is handled by hooks or skills.

### Skills (loaded on demand)
Skills auto-activate based on `autoActivateWhen` frontmatter when the user's prompt matches keywords. This keeps the context window lean -- only relevant instructions load.

| Skill | Activates when you mention... |
|-------|-------------------------------|
| stow-config | stow, dotfiles, shell config, symlink |
| ci-workflow | CI, GitHub Actions, workflows |
| fish-shell | fish, fish functions, conf.d |
| git-workflow | commit, PR, git workflow |
| debugging | bug, error, debug, investigate |

### Slash Commands
| Command | Usage |
|---------|-------|
| `/review-pr 123` | Comprehensive PR review with checks |
| `/setup` | Scan project, check tools, list targets |
| `/spec add auth` | Write spec.md with plan before coding |

### Hooks

**Enforcement (PreToolUse)** -- deterministic guardrails that block bad commands and inject context reminders for allowed-but-suboptimal ones.

**Formatting (PostToolUse)** -- auto-runs prettier and action version checks on every file write/edit.

**Notifications (Stop/Notification)** -- terminal bell (tmux -> Ghostty dock bounce) + macOS notification via terminal-notifier.

**Environment (Setup)** -- validates all required tools are installed on `claude --init`.

**Skill Suggestions (UserPromptSubmit)** -- evaluates every prompt against skill keywords and injects reminders.

### Permissions
- **defaultMode**: `acceptEdits` -- file edits auto-accept
- Sandbox enabled with auto-allow for bash
- gh CLI: read operations auto-allowed, write operations require confirmation
- Denied: sudo, curl, wget, ssh, eval, chmod 777, scp, rsync, git reset/clean
- Ask: git add/commit/push, package installs, destructive rm

## Required Tools

Checked by `validate-env.sh` on init:

```
bun uv fish git gh stow fd rg jq btca
```

Optional: `terminal-notifier` (macOS notifications)

Install missing tools: `brew install <tool>`
Install btca: `bun add -g btca`
