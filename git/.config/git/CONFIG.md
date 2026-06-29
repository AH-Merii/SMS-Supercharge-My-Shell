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

## Org URL Rewrites

`ggh add` and `ggh op add` configure `url.<base>.insteadOf` rules so that standard `github.com` clone URLs transparently route to the correct SSH host alias:

```ini
[url "git@github-acme:Acme/"]
    insteadOf = git@github.com:Acme/
```

This means `git clone git@github.com:Acme/repo.git` works directly — git rewrites the URL at connect time so SSH picks the org-specific key via the host alias. No need to remember custom hostnames when cloning.

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

## Commit Signing (SSH)

| Setting                      | Value                           | Description                                        |
| ---------------------------- | ------------------------------- | -------------------------------------------------- |
| `gpg.format`                 | `ssh`                           | Use SSH keys instead of GPG                        |
| `user.signingkey`            | `<path>`                        | File path to public key, set by `ggh`              |
| `gpg.ssh.program`            | (platform-specific)             | Direct path to op-ssh-sign binary (1Password only) |
| `gpg.ssh.allowedSignersFile` | `~/.config/git/allowed_signers` | Local signature verification                       |

Signing is configured by `ggh init` or `ggh op init`. The `user.signingkey` points to a public key file on disk (e.g., `~/.ssh/github_jane`). Git reads the key from the file, so re-exporting the `.pub` file after key rotation is enough — no config change needed.

### 1Password SSH Key Routing

Standard SSH keys use `IdentityFile` pointing at the private key. 1Password keys have no private key on disk, but SSH accepts public key files as key selectors — it tells the agent "sign with the key matching this public key." Combined with `IdentitiesOnly yes`, this pins each Host to exactly one key.

| Directive        | Purpose                                                        |
| ---------------- | -------------------------------------------------------------- |
| `IdentityFile`   | Points at public key file — selects which key the agent uses   |
| `IdentitiesOnly` | Prevents agent from offering other keys                        |

`ggh op init` saves the public key to `~/.ssh/github_<name>` (no `.pub` extension, `0o600` permissions) and configures the SSH host block. `ggh op add` reuses this key — it only adds per-org identity (name/email) via `includeIf`, with no additional key or SSH host setup.

### 1Password Agent Config (`agent.toml`)

`ggh op init` registers the key in 1Password's `agent.toml` allowlist. The file follows the XDG Base Directory spec: `$XDG_CONFIG_HOME/1Password/ssh/agent.toml` (defaults to `~/.config/1Password/ssh/agent.toml`). Each entry is a `[[ssh-keys]]` block:

```toml
[[ssh-keys]]
item = "GitHub SSH Jane"
vault = "Personal"
```

Use `ggh status` to see which keys are registered.

### Clean Filters

| Filter                  | Files              | Effect                                                      |
| ----------------------- | ------------------ | ----------------------------------------------------------- |
| `remove_gitconfig_user` | `config`, `config-*` | Strips `[user]`, `[gpg "ssh"]`, and `[url "..."]` sections |

These sections contain machine-specific values (identity, signing keys, org URL rewrites). After cloning, run `ggh init` to populate — see [README.md](README.md#post-clone-setup).

## Requirements

- [delta](https://github.com/dandavison/delta) - Diff viewer with syntax highlighting
- `ggh` - GitHub SSH setup CLI (included in `~/.local/bin`)
- [1Password](https://1password.com/) desktop app with SSH agent enabled (for 1Password signing mode)
- `git-whichside` - Conflict helper showing ours vs theirs (included in `~/.local/bin`)
