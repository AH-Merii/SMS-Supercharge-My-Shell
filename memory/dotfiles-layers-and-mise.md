---
name: dotfiles-layers-and-mise
description: "Repo is organised as base/desktop/macos stow layers; mise installs CLI tools, brew only on mac/WSL, no brew on Arch; fish is the only shell."
metadata: 
  node_type: memory
  type: project
  originSessionId: c9a27804-44d7-4da0-b775-66cc5e280ce7
  modified: 2026-09-03T19:37:30.640Z
---

Decided 2026-09-03 (PR #23, branch `restructure`): stow packages live in `base/` (all
machines), `desktop/` (niri + noctalia), `macos/` (karabiner). `.stowrc` sets
`--target=$HOME --no-folding --dir=base`. Profiles are detected by `mise-tasks/profile`
(`DOTFILES_PROFILE` overrides). CLI tools and runtimes come from the global mise config
(`base/mise/.config/mise/config.toml`); `Brewfile` is for macOS/WSL only; `pkglist/` for
Arch/Debian. Homebrew is deliberately not installed on Arch. zsh, hypr, kitty, alacritty,
the azure fish tooling and the `install/` scripts are gone. Noctalia is v5 only (native `noctalia`
binary, not the v4 Quickshell `noctalia-shell`); v5 config is TOML at
`~/.local/state/noctalia/settings.toml` (written by its settings UI), symlinked from
`desktop/noctalia`. `~/.config/noctalia/` is now a stow target too, holding a versioned custom palette JSON. Terminal is ghostty everywhere; on WSL, `mise-tasks/winterm` + `lib/winterm.sh` render that same ghostty theme into Windows Terminal's settings.json (not a stow package).

**Why:** the user wanted one shell, one dependency story across Arch/mac/WSL/servers, and
the live desktop config versioned; brew on Arch shadows pacman's python/perl/git.

**How to apply:** put new tools in the mise config if the registry has them, else in
Brewfile/pkglist. The single entry point is `./bootstrap.sh` (curl-able too; the user wants that name); `mise run link`
moves conflicting files to `.bak` itself. Never give `pacman -Rns` for desktop packages:
it cascaded away niri once. Noctalia's ghostty/starship templates rewrite repo-owned files,
so only its `niri` template stays enabled. Commits
are short conventional one-liners with no assistant attribution. See
[[claude-config-not-stowed]].
