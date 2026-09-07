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

Nothing machine-specific is tracked. The stowed `config` ends with an include of
`~/.config/git/config.local`, which is a plain untracked file that `ggh` writes:

| File                            | Tracked | Holds                                                        |
| ------------------------------- | ------- | ------------------------------------------------------------ |
| `~/.config/git/config`          | yes     | aliases, pager, signing policy — everything shared           |
| `~/.config/git/config.local`    | no      | `[user]`, `[gpg "ssh"]`, `[url]` rewrites, org `includeIf`s  |
| `~/.config/git/config-<org>`    | no      | per-org `[user]` override, pulled in by an `includeIf`       |
| `~/.config/git/allowed_signers` | no      | public keys for local signature verification                 |

`config.local` and `config-*` sit next to the stow symlinks as real files. They have no path inside the repo, so no git command can commit, overwrite or push them; the repo `.gitignore` also refuses them in case they are ever copied into the package directory. Git silently skips the include while the file is missing, so a fresh clone works and the fish shell prints a reminder to run `ggh`.

After cloning, run `ggh` once per machine:

```bash
# Standard SSH setup
ggh init --name "Your Name" --email "you@example.com"

# Or with 1Password
ggh op init --name "Your Name" --email "you@example.com"
```

### Adding an organization

No org is configured by default. To commit to an org's repos under a different identity (and, if needed, a different key):

```bash
# Standard SSH org
ggh add --org MyOrg --name "Your Name" --email "you@work.com"

# 1Password org
ggh op add --org MyOrg --name "Your Name" --email "you@work.com"
```

This writes, all outside the repo:

- an SSH host alias `github-myorg` in `~/.ssh/config` pinned to the org key
- `url.git@github-myorg:MyOrg/.insteadOf = git@github.com:MyOrg/` in `config.local`, so plain `git clone git@github.com:MyOrg/repo.git` URLs route to that key
- two `includeIf` blocks in `config.local` (one for the host alias, one for `github.com:MyOrg/**`) pointing at `~/.config/git/config-myorg`
- `~/.config/git/config-myorg` with the org `[user]` section and signing key

Run `ggh status` to see what is configured. Repeat `ggh add` for each org.

### Re-running ggh

Every step is idempotent, so `ggh` can be re-run on a machine that is already set up, or on a second machine against the same GitHub account. Whenever something already exists it says so and asks before touching it:

| Step                     | Already exists                                   | Choices                                      |
| ------------------------ | ------------------------------------------------ | -------------------------------------------- |
| SSH key on disk          | key file present                                 | Overwrite / Use existing                     |
| SSH key in 1Password     | item with the same name in the vault             | Overwrite / Keep                             |
| GitHub login             | `gh` logged in with the scopes ggh needs         | Re-authenticate / Keep (missing scopes are added with `gh auth refresh`, no prompt) |
| SSH key on GitHub        | same key already uploaded                        | skipped silently                             |
|                          | different key under the same title               | Replace / Add alongside / Skip               |
| git config values        | value differs                                    | Update / Keep (shows a diff)                 |

Replacing a GitHub key is account-wide: any other machine still using it loses access, and a replaced *signing* key makes every commit it signed show as Unverified on GitHub. That is why the GitHub prompt has an "Add alongside" choice, and why standard-SSH key titles carry the hostname (`Jane Doe (laptop)`), so two machines never clash on the title in the first place. 1Password keys share one item and one title across machines, so on a second machine the upload step finds the same key and skips.

Two global flags control the prompts:

- `-k` / `--keep-existing` answers every prompt with the non-destructive choice (Keep, Use existing, Add alongside). Useful for unattended runs.
- `-n` / `--dry-run` prints what would happen, including which prompts would appear, and writes nothing.

The last step of every command is a live check: `ssh -T` against GitHub, then a throwaway commit signed in a temp repo and verified against `allowed_signers`. For org commands the temp repo gets a remote under that org, so the same `includeIf` rules decide which identity signs. Run it on its own any time:

```bash
ggh verify              # primary identity
ggh verify --org MyOrg  # org identity via its host alias
```

`ggh status` also lists the keys on the GitHub account and marks which ones exist on this machine.

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
| `ggh`           | GitHub SSH setup CLI — keys, signing, org configs, `status` and `verify`      |
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

`ggh add` and `ggh op add` write `url.<base>.insteadOf` rules to `config.local` so that standard `github.com` clone URLs transparently route to the correct SSH host alias:

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

Signing is configured by `ggh init` or `ggh op init`, which write these keys to the untracked `config.local`. The `user.signingkey` points to a public key file on disk (e.g., `~/.ssh/github_jane`). Git reads the key from the file, so re-exporting the `.pub` file after key rotation is enough — no config change needed.

#### 1Password SSH Key Routing

Standard SSH keys use `IdentityFile` pointing at the private key. 1Password keys have no private key on disk, but SSH accepts public key files as key selectors — it tells the agent "sign with the key matching this public key." Combined with `IdentitiesOnly yes`, this pins each Host to exactly one key.

| Directive        | Purpose                                                        |
| ---------------- | -------------------------------------------------------------- |
| `IdentityFile`   | Points at public key file — selects which key the agent uses   |
| `IdentitiesOnly` | Prevents agent from offering other keys                        |

`ggh op init` saves the public key to `~/.ssh/github_<name>` (no `.pub` extension, `0o600` permissions) and configures the SSH host block. `ggh op add` does the same for a separate org key (`~/.ssh/github_<org>`, item `GitHub <org>` by default) behind the `github-<org>` host alias, and adds the per-org identity via `includeIf`.

#### 1Password Agent Config (`agent.toml`)

`ggh op init` registers the key in 1Password's `agent.toml` allowlist. The file follows the XDG Base Directory spec: `$XDG_CONFIG_HOME/1Password/ssh/agent.toml` (defaults to `~/.config/1Password/ssh/agent.toml`). Each entry is a `[[ssh-keys]]` block:

```toml
[[ssh-keys]]
item = "GitHub SSH Jane"
vault = "Personal"
```

Use `ggh status` to see which keys are registered.

#### Why identity is not a clean filter

An earlier layout kept `[user]` inside the tracked `config` and relied on a clean filter to strip it on commit. That hid the edits from git entirely, so `git status` stayed clean and any checkout, pull, stash or reset silently overwrote the identity with the placeholder — and the filter only matched three section headers, so anything else written to the file would have been committed. Keeping identity in a file with no path inside the repo removes both failure modes structurally. See [Post-Clone Setup](#post-clone-setup).

### Requirements

- [delta](https://github.com/dandavison/delta) - Diff viewer with syntax highlighting
- `ggh` - GitHub SSH setup CLI (included in `~/.local/bin`)
- [1Password](https://1password.com/) desktop app with SSH agent enabled (for 1Password signing mode)
- `git-whichside` - Conflict helper showing ours vs theirs (included in `~/.local/bin`)
