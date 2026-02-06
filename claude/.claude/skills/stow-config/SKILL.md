---
description: Dotfile management via GNU Stow from ~/SMS-Supercharge-My-Shell
autoActivateWhen: user mentions stow, dotfiles, shell config, or updating global Claude/fish/git/zsh configuration
---

# Stow Config Management

Dotfiles are managed via GNU Stow from `~/SMS-Supercharge-My-Shell/`.

## Directory Layout
Each top-level directory maps to a stow package:
- `claude/` -> Claude Code config (~/.config/claude/, ~/.claude/)
- `fish/` -> Fish shell (~/.config/fish/)
- `git/` -> Git config (~/.config/git/)
- `zsh/` -> Zsh config (~/.zshenv)
- `install/` -> Setup scripts (not stowed)

## Workflow
1. Edit source files in `~/SMS-Supercharge-My-Shell/<package>/`
2. Apply: `cd ~/SMS-Supercharge-My-Shell && stow -vt ~ <package>`
3. Verify: `ls -la ~/.<target-path>`

## Folding
By default stow symlinks entire directories ("folding"). Use `--no-folding` for packages whose target directories contain non-stow files:
- `zsh` -- target has `.zsh_history`, `hooks.zsh`, plugin state
- `tmux` -- target has plugin dirs, resurrect data
- `fish` -- target has `fish_variables`, completion cache

Example: `stow -vt ~ --no-folding zsh`

Packages like `claude` and `git` are safe to fold since stow owns the full directory.

## Rules
- Never edit symlink targets directly -- always edit source in SMS repo
- Use `stow -D <package>` to unlink, `stow -R <package>` to re-stow
- After editing any file in SMS repo, run stow before testing
