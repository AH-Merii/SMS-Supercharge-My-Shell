---
name: git-identity-never-write-config-local
description: "Never write the user's git identity or signing key into ~/.config/git/config.local, and never run ggh; hand the command back instead"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 729541b5-93a7-433a-8023-12f62068b0c2
  modified: 2026-09-09
---

The stowed git config includes an untracked `~/.config/git/config.local` that holds the
user's name, email and SSH signing key, populated per machine by `ggh init` or
`ggh op init`. Commits are signed through 1Password (`gpg.ssh.program = /opt/1Password/op-ssh-sign`),
which raises a desktop prompt the user approves; a one-approval-per-session flow via `op`
is tracked as a GitHub issue in the repo.

**Why:** the identity and key choice are the user's; an agent writing them would guess at
a machine-specific secret path, and running ggh would trigger 1Password prompts the user
did not ask for.

**How to apply:** commit normally and let the prompt appear; if a commit hangs on it, tell
the user to approve rather than retrying with `--no-gpg-sign`. Never run `ggh init` or
`ggh op init`, and never write `config.local`; print the command for the user instead.
