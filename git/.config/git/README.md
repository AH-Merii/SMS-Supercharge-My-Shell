# Git Configuration

Modern Git configuration based on 2025-2026 best practices from Git core developers.

See [CONFIG.md](CONFIG.md) for detailed settings documentation.

## Alias Quick Reference

| Alias       | Command                       | Description                                  |
| ----------- | ----------------------------- | -------------------------------------------- |
| `st`        | `status`                      | Show status                                  |
| `co`        | `checkout`                    | Checkout branch                              |
| `sw`        | `switch`                      | Switch branch (modern)                       |
| `ci`        | `commit`                      | Commit changes                               |
| `lg`        | `log --graph...`              | Pretty graph log                             |
| `dog`       | `log --all --oneline --graph` | Full graph view                              |
| `last`      | `log -1 HEAD`                 | Show last commit                             |
| `oops`      | `commit --amend --no-edit`    | Amend without editing message                |
| `reword`    | `commit --amend`              | Edit last commit message                     |
| `fixup`     | `commit --fixup`              | Create fixup commit                          |
| `wip`       | `commit -am 'WIP: ...'`       | Quick WIP commit (with optional description) |
| `ws`        | wipsquash                     | Squash WIP commits                           |
| `uncommit`  | `reset --soft HEAD~1`         | Undo commit, keep staged                     |
| `undo`      | `reset HEAD~1 --mixed`        | Undo commit, unstage                         |
| `rs`        | `restore`                     | Restore file                                 |
| `rss`       | `restore --staged`            | Unstage file                                 |
| `sync-main` | checkout main, pull, rebase   | Sync branch with main                        |
| `p`         | `push`                        | Push to remote                               |
| `fp`        | `push --force-with-lease`     | Safe force push                              |
| `re`        | `rebase`                      | Rebase shortcut                              |
| `stash-all` | `stash push -u`               | Stash including untracked                    |
| `who`       | `shortlog -sne`               | List contributors                            |
| `changes`   | `log -p --follow`             | Full diff history of a file                  |
| `filelog`   | `log --oneline --follow`      | Compact commit history of a file             |
| `untrack`   | `rm --cache --`               | Stop tracking file, keep on disk             |
| `aliases`   | list all aliases              | Show all aliases                             |

## Post-Clone Setup

The `[user]` section and `allowed_signers` file are stripped from commits via clean filters. After cloning, populate them locally:

```bash
# Set your identity
git config --file ~/.config/git/config user.email "you@example.com"
git config --file ~/.config/git/config user.name "Your Name"

# Add your key to allowed_signers (for verifying signatures)
echo "you@example.com ssh-ed25519 AAAA..." > ~/.config/git/allowed_signers
```

> **Note:** The signing key is auto-detected from the 1Password SSH agent via `gpg.ssh.defaultKeyCommand = ssh-add -L`. No manual `user.signingkey` is needed.

### Commit signing with 1Password

The config uses SSH commit signing via 1Password. The cross-platform wrapper `op-ssh-sign` detects macOS vs Linux automatically.

**Requirements:**

- [1Password](https://1password.com/) desktop app with SSH agent enabled
- SSH key added to your 1Password vault and configured as a signing key

The 1Password SSH agent socket is configured in fish (`conf.d/03-ssh-agent.fish`) and zsh (`.zprofile`), with a traditional ssh-agent fallback when 1Password isn't available.

## Example Workflows

### Quick feature branch

```bash
git sw -c feature/new-thing    # Create and switch to branch
# ... make changes ...
git wip                        # Quick WIP commit
git p                          # Push (auto-sets upstream)
```

### WIP workflow - Save work quickly and clean up later

```bash
# Development with WIP commits
git commit -m "Add authentication"    # Meaningful base commit
git wip "form basics"                 # WIP: form basics
git wip "validation"                  # WIP: validation
git wip                               # WIP: work in progress

# Option 1: Squash into new commit
git ws -m "Add login form"            # All WIPs → single "Add login form" commit

# Option 2: Interactive squash into base
git ws                                # Opens editor to squash into "Add authentication"
```

#### Simple WIP save and restore

```bash
# You're in the middle of work and need to switch context
git wip                        # Creates commit with message "WIP: work in progress"
git wip "halfway done"         # Or with a description: "WIP: halfway done"

# Later, when you come back:
git uncommit                   # Undo the WIP commit, keeps changes staged
# or
git undo                       # Undo the WIP commit, unstages changes

# Now continue working and make a proper commit
git ci -m "Add feature X"
```

### Fixup workflow - Clean up commits before pushing

```bash
# You made a commit but then noticed a typo or forgot something
git lg                         # View recent commits
# Output shows:
#   a1b2c3d - Add user login feature
#   e4f5g6h - Update README

# Make your fix, then create a fixup commit targeting the commit to fix
git add .
git fixup a1b2c3d              # Creates "fixup! Add user login feature"

# Now rebase to squash the fixup into its target
git re -i main             # autoSquash reorders fixup commits automatically
# The fixup commit will be squashed into a1b2c3d

# Force push to update the branch (safe because --force-with-lease)
git fp
```

### Another fixup example - Fixing the previous commit

```bash
# Oops, forgot to add a file to the last commit
git add forgotten-file.js
git fixup HEAD                 # Target the most recent commit

# Interactive rebase to squash
git rebase -i HEAD~2           # Rebase last 2 commits
# Git auto-reorders the fixup, just save and exit
```

### Who contributed to this repo?

```bash
git who
# Output:
#    42  John Doe <john@example.com>
#    31  Jane Smith <jane@example.com>
#    15  Bob Wilson <bob@example.com>

# See who contributed to a specific file
git who -- path/to/file.js

# See contributions in a date range
git who --since="2024-01-01" --until="2024-12-31"
```

## Utilities

Scripts in `~/.local/bin/` that extend git:

| Script          | Description                                                                   |
| --------------- | ----------------------------------------------------------------------------- |
| `op-ssh-sign`   | Cross-platform 1Password signing wrapper (detects macOS vs Linux)             |
| `git-whichside` | Shows ours vs theirs during conflicts (rebase, merge, cherry-pick, stash pop) |

Usage: `git whichside` — run it when you hit a conflict to see which side is which.

### Clone shortcuts

```bash
git clone gh:user/repo         # Expands to git@github.com:user/repo
git clone gl:user/repo         # Expands to git@gitlab.com:user/repo
```
