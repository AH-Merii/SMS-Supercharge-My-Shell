# Git Configuration

Modern Git configuration based on 2025-2026 best practices from Git core developers.

The [settings reference](#settings-reference) at the bottom documents every option in `config`.

## Alias Quick Reference

| Alias       | Command                       | Description                                  |
| ----------- | ----------------------------- | -------------------------------------------- |
| `st`        | `status`                      | Show status                                  |
| `co`        | `checkout`                    | Checkout branch                              |
| `sw`        | `switch`                      | Switch branch (modern)                       |
| `ci`        | `commit`                      | Commit changes                               |
| `lg`        | `log --graph...`              | Pretty graph log with signature status       |
| `dog`       | `log --all --oneline --graph` | Full graph view                              |
| `last`      | `log -1 HEAD`                 | Show last commit                             |
| `oops`      | `commit --amend --no-edit`    | Amend without editing message                |
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

Usage:

```bash
# See which side is which during a conflict
git whichside
```

## Settings reference

Settings in `config` grouped by impact.

### Performance

| Setting                  | Value  | Description                              |
| ------------------------ | ------ | ---------------------------------------- |
| `core.fsmonitor`         | `true` | OS file system monitor for faster status |
| `core.untrackedCache`    | `true` | Cache untracked files                    |
| `fetch.all`              | `true` | Fetch from all remotes                   |
| `fetch.writeCommitGraph` | `true` | Speeds up log/blame/merge-base           |

### Workflow

| Setting                | Value     | Description                                 |
| ---------------------- | --------- | ------------------------------------------- |
| `init.defaultBranch`   | `main`    | Default branch for new repos                |
| `pull.rebase`          | `merges`  | Rebase on pull, preserving merge commits    |
| `push.autoSetupRemote` | `true`    | Auto-create upstream tracking on first push |
| `push.default`         | `current` | Push current branch to same-named remote    |
| `rebase.autoSquash`    | `true`    | Auto-reorder fixup! commits during rebase   |
| `rebase.autoStash`     | `true`    | Auto-stash dirty worktree before rebase     |
| `rebase.updateRefs`    | `true`    | Auto-move stacked branch pointers on rebase |
| `rerere.enabled`       | `true`    | Remember conflict resolutions               |
| `rerere.autoupdate`    | `true`    | Auto-stage rerere resolutions               |
| `commit.gpgSign`       | `true`    | Sign all commits                            |
| `commit.verbose`       | `true`    | Show diff in commit message editor          |
| `tag.gpgSign`          | `true`    | Sign all tags                               |

### Diff & Display

| Setting               | Value                      | Description                           |
| --------------------- | -------------------------- | ------------------------------------- |
| `diff.algorithm`      | `histogram`                | Cleaner, more readable diffs          |
| `diff.colorMoved`     | `plain`                    | Highlight moved code blocks           |
| `diff.colorMovedWS`   | `allow-indentation-change` | Detect moved+reindented code as moves |
| `diff.mnemonicPrefix` | `true`                     | Use i/ w/ instead of a/ b/ in diffs   |
| `diff.renames`        | `true`                     | Detect renamed files in diffs         |
| `tag.sort`            | `version:refname`          | Sort tags by semantic version         |
| `column.ui`           | `auto`                     | Column output for branches/tags       |
| `branch.sort`         | `-committerdate`           | Recent branches first                 |
| `blame.coloring`      | `highlightRecent`          | Highlight recent changes in blame     |
| `blame.date`          | `relative`                 | Show relative dates in blame          |

### Fetch & Cleanup

| Setting           | Value  | Description                         |
| ----------------- | ------ | ----------------------------------- |
| `fetch.prune`     | `true` | Auto-remove deleted remote branches |
| `fetch.pruneTags` | `true` | Also prune deleted tags             |

### Merge & Conflict

| Setting               | Value    | Description                     |
| --------------------- | -------- | ------------------------------- |
| `merge.conflictStyle` | `zdiff3` | Shows base version in conflicts |
| `merge.ff`            | `false`  | Always create merge commits     |

### Integrity

| Setting                | Value  | Description                              |
| ---------------------- | ------ | ---------------------------------------- |
| `transfer.fsckObjects` | `true` | Validates object integrity on fetch/push |

### Delta Pager

The config uses [delta](https://github.com/dandavison/delta) as the pager.

| Setting                      | Description                                      |
| ---------------------------- | ------------------------------------------------ |
| `navigate = true`            | Use n/N to jump between hunks                    |
| `line-numbers = true`        | Show line numbers                                |
| `hyperlinks = true`          | Clickable file paths (terminal support required) |
| `syntax-theme = OneHalfDark` | Syntax highlighting theme                        |
| `tabs = 4`                   | Tab width for display                            |
| `true-color = always`        | Force true-color output                          |
| `file-modified-label`        | Label for modified files                         |
| `wrap-max-lines = unlimited` | No line wrapping limit                           |

#### Responsive Side-by-Side

Side-by-side is defined as a named feature (`[delta "side-by-side"]`) and toggled via `core.pager`. The pager command checks terminal width at invocation — side-by-side activates when the terminal is >= 160 columns wide.

#### Interactive Diff

`interactive.diffFilter = delta --color-only` enables delta syntax highlighting during `git add -p`.

### Org URL Rewrites

`ggh add` and `ggh op add` configure `url.<base>.insteadOf` rules so that standard `github.com` clone URLs transparently route to the correct SSH host alias:

```ini
[url "git@github-acme:Acme/"]
    insteadOf = git@github.com:Acme/
```

This means `git clone git@github.com:Acme/repo.git` works directly — git rewrites the URL at connect time so SSH picks the org-specific key via the host alias. No need to remember custom hostnames when cloning.

### Help

| Setting            | Value    | Description                         |
| ------------------ | -------- | ----------------------------------- |
| `help.autocorrect` | `prompt` | Prompt before auto-correcting typos |

### Misc

| Setting                        | Value                                          | Description              |
| ------------------------------ | ---------------------------------------------- | ------------------------ |
| `core.editor`                  | `nvim`                                         | Default editor           |
| `safe.directory`               | `*`                                            | Trust all directories    |
| `versionsort.prereleaseSuffix` | `-pre`, `.pre`, `-beta`, `.beta`, `-rc`, `.rc` | Pre-release tag ordering |

### Commit Signing (SSH)

| Setting                      | Value                           | Description                                        |
| ---------------------------- | ------------------------------- | -------------------------------------------------- |
| `gpg.format`                 | `ssh`                           | Use SSH keys instead of GPG                        |
| `user.signingkey`            | `<path>`                        | File path to public key, set by `ggh`              |
| `gpg.ssh.program`            | (platform-specific)             | Direct path to op-ssh-sign binary (1Password only) |
| `gpg.ssh.allowedSignersFile` | `~/.config/git/allowed_signers` | Local signature verification                       |

Signing is configured by `ggh init` or `ggh op init`. The `user.signingkey` points to a public key file on disk (e.g., `~/.ssh/github_jane`). Git reads the key from the file, so re-exporting the `.pub` file after key rotation is enough — no config change needed.

#### 1Password SSH Key Routing

Standard SSH keys use `IdentityFile` pointing at the private key. 1Password keys have no private key on disk, but SSH accepts public key files as key selectors — it tells the agent "sign with the key matching this public key." Combined with `IdentitiesOnly yes`, this pins each Host to exactly one key.

| Directive        | Purpose                                                        |
| ---------------- | -------------------------------------------------------------- |
| `IdentityFile`   | Points at public key file — selects which key the agent uses   |
| `IdentitiesOnly` | Prevents agent from offering other keys                        |

`ggh op init` saves the public key to `~/.ssh/github_<name>` (no `.pub` extension, `0o600` permissions) and configures the SSH host block. `ggh op add` reuses this key — it only adds per-org identity (name/email) via `includeIf`, with no additional key or SSH host setup.

#### 1Password Agent Config (`agent.toml`)

`ggh op init` registers the key in 1Password's `agent.toml` allowlist. The file follows the XDG Base Directory spec: `$XDG_CONFIG_HOME/1Password/ssh/agent.toml` (defaults to `~/.config/1Password/ssh/agent.toml`). Each entry is a `[[ssh-keys]]` block:

```toml
[[ssh-keys]]
item = "GitHub SSH Jane"
vault = "Personal"
```

Use `ggh status` to see which keys are registered.

#### Clean Filters

| Filter                  | Files              | Effect                                                      |
| ----------------------- | ------------------ | ----------------------------------------------------------- |
| `remove_gitconfig_user` | `config`, `config-*` | Strips `[user]`, `[gpg "ssh"]`, and `[url "..."]` sections |

These sections contain machine-specific values (identity, signing keys, org URL rewrites). After cloning, run `ggh init` to populate — see [README.md](README.md#post-clone-setup).

### Requirements

- [delta](https://github.com/dandavison/delta) - Diff viewer with syntax highlighting
- `ggh` - GitHub SSH setup CLI (included in `~/.local/bin`)
- [1Password](https://1password.com/) desktop app with SSH agent enabled (for 1Password signing mode)
- `git-whichside` - Conflict helper showing ours vs theirs (included in `~/.local/bin`)
