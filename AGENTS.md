# SMS Supercharge-My-Shell

Dotfiles for fish, neovim, tmux, git and a niri desktop, one directory per program under
`programs/`. `CONTEXT.md` holds the vocabulary and `docs/adr/` the decisions; `README.md` is
the setup walkthrough and the guide to adding, removing and moving programs.

## Building the Nix configurations

Every `nix` command here takes `--impure`, because the username and home directory are read
from the environment. Where the clone is not at `~/SMS-Supercharge-My-Shell` — a worktree, a
container, CI — `SMS_CHECKOUT` has to say where it is, or every configuration refuses to
build rather than pointing the live links at a path that is not there:

```
SMS_CHECKOUT=$PWD nix flake check --impure
```

`flake.nix` lists the rest of the commands. The front door is the mise tasks, which set
`SMS_CHECKOUT` to the checkout they run from: `mise run check --tier shell` builds one
configuration and touches nothing, `activate` previews and activates it, `update` pulls first,
`setup` runs the activation and the distro's steps on one question, and `pacman` installs the
derived list. `bootstrap.sh` takes a Fresh machine to `setup` from nothing.

## Agent skills

### Issue tracker

Issues live in GitHub Issues for `AH-Merii/SMS-Supercharge-My-Shell`, worked through the
`gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage labels, unchanged: `needs-triage`, `needs-info`,
`ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` at the repo root and ADRs under `docs/adr/`. See
`docs/agents/domain.md`.
