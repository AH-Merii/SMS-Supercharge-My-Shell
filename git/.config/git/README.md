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

The `[user]`, `[gpg "ssh"]`, and `[url "..."]` sections are stripped from commits via a clean filter. After cloning, run `ggh` to configure:

```bash
# Standard SSH setup
ggh init --name "Your Name" --email "you@example.com"

# Or with 1Password
ggh op init --name "Your Name" --email "you@example.com"
```

For org-specific accounts:

```bash
# Standard SSH org
ggh add --org MyOrg --name "Your Name" --email "you@work.com"

# 1Password org
ggh op add --org MyOrg --name "Your Name" --email "you@work.com"
```

> **Note:** `ggh add`/`ggh op add` create a per-org SSH key, SSH host alias, and `url.insteadOf` rewrite. The URL rewrite means you can clone with standard `git@github.com:Org/repo.git` URLs — git transparently routes to the org-specific key. Two `includeIf` conditions are set (one for the host alias, one for `github.com:Org/**`) so both old and new clone URLs resolve the correct identity.

### Commit signing

The config uses SSH commit signing. `ggh` sets up signing automatically — it supports both standard SSH keys and 1Password-backed keys.

**Requirements:**

- `ggh` CLI (`~/.local/bin/ggh`)
- For 1Password: desktop app with SSH agent enabled

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
| `ggh`         | GitHub SSH setup CLI — manages keys, signing, org configs, allowed_signers    |
| `op-ssh-sign`   | Cross-platform 1Password signing wrapper (detects macOS vs Linux)             |
| `git-whichside` | Shows ours vs theirs during conflicts (rebase, merge, cherry-pick, stash pop) |

Usage: `git whichside` — run it when you hit a conflict to see which side is which.

### Clone shortcuts

```bash
git clone gh:user/repo         # Expands to git@github.com:user/repo
git clone gl:user/repo         # Expands to git@gitlab.com:user/repo
```
