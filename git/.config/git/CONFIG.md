# Git Configuration Reference

Settings in `config` grouped by impact.

## Performance

| Setting                  | Value  | Description                              |
| ------------------------ | ------ | ---------------------------------------- |
| `core.fsmonitor`         | `true` | OS file system monitor for faster status |
| `core.untrackedCache`    | `true` | Cache untracked files                    |
| `fetch.all`              | `true` | Fetch from all remotes                   |
| `fetch.writeCommitGraph` | `true` | Speeds up log/blame/merge-base           |

## Workflow

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

## Diff & Display

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

## Fetch & Cleanup

| Setting           | Value  | Description                         |
| ----------------- | ------ | ----------------------------------- |
| `fetch.prune`     | `true` | Auto-remove deleted remote branches |
| `fetch.pruneTags` | `true` | Also prune deleted tags             |

## Merge & Conflict

| Setting               | Value    | Description                     |
| --------------------- | -------- | ------------------------------- |
| `merge.conflictStyle` | `zdiff3` | Shows base version in conflicts |
| `merge.ff`            | `false`  | Always create merge commits     |

## Integrity

| Setting                | Value  | Description                              |
| ---------------------- | ------ | ---------------------------------------- |
| `transfer.fsckObjects` | `true` | Validates object integrity on fetch/push |

## Delta Pager

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

### Responsive Side-by-Side

Side-by-side is defined as a named feature (`[delta "side-by-side"]`) and toggled via `core.pager`. The pager command checks terminal width at invocation — side-by-side activates when the terminal is >= 160 columns wide.

### Interactive Diff

`interactive.diffFilter = delta --color-only` enables delta syntax highlighting during `git add -p`.

## URL Shortcuts

| Shortcut       | Expands To                 |
| -------------- | -------------------------- |
| `gh:user/repo` | `git@github.com:user/repo` |
| `gl:user/repo` | `git@gitlab.com:user/repo` |

Example:

```bash
git clone gh:AH-Merii/dotfiles
# Equivalent to: git clone git@github.com:AH-Merii/dotfiles
```

## Help

| Setting            | Value    | Description                         |
| ------------------ | -------- | ----------------------------------- |
| `help.autocorrect` | `prompt` | Prompt before auto-correcting typos |

## Misc

| Setting                        | Value                                          | Description              |
| ------------------------------ | ---------------------------------------------- | ------------------------ |
| `core.editor`                  | `nvim`                                         | Default editor           |
| `safe.directory`               | `*`                                            | Trust all directories    |
| `versionsort.prereleaseSuffix` | `-pre`, `.pre`, `-beta`, `.beta`, `-rc`, `.rc` | Pre-release tag ordering |

## Commit Signing (SSH via 1Password)

| Setting                      | Value                           | Description                                          |
| ---------------------------- | ------------------------------- | ---------------------------------------------------- |
| `gpg.format`                 | `ssh`                           | Use SSH keys instead of GPG                          |
| `gpg.ssh.defaultKeyCommand`  | `ssh-add -L`                    | Auto-detect signing key from SSH agent               |
| `gpg.ssh.program`            | `op-ssh-sign`                   | Cross-platform 1Password wrapper (in `~/.local/bin`) |

The `op-ssh-sign` wrapper detects the platform and dispatches to the correct 1Password binary (macOS: `/Applications/1Password.app/.../op-ssh-sign`, Linux: `/opt/1Password/op-ssh-sign`).

### Clean Filters

| Filter                   | File              | Effect                                     |
| ------------------------ | ----------------- | ------------------------------------------ |
| `remove_gitconfig_user`  | `config`          | Strips `[user]` section (email, name)      |

The `config` file must have `[user]` populated locally after cloning — see [README.md](README.md#post-clone-setup).

## Requirements

- [delta](https://github.com/dandavison/delta) - Diff viewer with syntax highlighting
- [1Password](https://1password.com/) desktop app with SSH agent enabled (for commit signing)
- `git-whichside` - Conflict helper showing ours vs theirs (included in `~/.local/bin`)
