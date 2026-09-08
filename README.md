# SMS Supercharge-My-Shell

Dotfiles for fish, neovim, tmux, git and a niri desktop. Configs are linked into `~` with
[GNU Stow](https://www.gnu.org/software/stow/); tools are installed with
[mise](https://mise.jdx.dev). Runs on Arch (CachyOS), macOS, WSL2 and headless Linux servers.

## Layout

```
base/        stow packages every machine gets: fish git nvim tmux starship lazygit ghostty
             herdr claude ccstatusline mise
desktop/     Linux desktop only: niri noctalia (v5, ~/.local/state/noctalia/settings.toml)
macos/       macOS only: karabiner
plugins/     Claude Code local plugin marketplace (referenced by path, not stowed)
system/      root-owned files, mirroring /: greetd config, its PAM stack, the greeter's
             greeter.toml. Installed by `mise run greeter`, not stowed
pkglist/     pacman / AUR / apt package lists
Brewfile     Homebrew packages for macOS and WSL
mise.toml    tasks (see below); mise-tasks/ holds the scripts
lib/         ui.sh (colours, Y/n prompt) and plan.sh (what a task would do), sourced by
             the tasks; bootstrap.sh inlines its own copy since it runs before the clone
bootstrap.sh     the one command: OS packages, clone, then `mise run setup`
.stowrc      --target=$HOME --no-folding --dir=base
```

Each package mirrors `~`: `base/fish/.config/fish/...` links to `~/.config/fish/...`.
Package READMEs: [claude](base/claude/README.md), [ccstatusline](base/ccstatusline/README.md),
[git](base/git/README.md), [nvim](base/nvim/README.md), [karabiner](macos/karabiner/README.md).

## Profiles

A profile is the set of layers a machine links. It is detected automatically and can be
forced with `DOTFILES_PROFILE=`.

| Profile   | Layers           | Detected when                          |
| --------- | ---------------- | -------------------------------------- |
| `base`    | base             | Linux without niri (servers), WSL      |
| `desktop` | base + desktop   | Linux with niri installed              |
| `macos`   | base + macos     | macOS                                  |

## Install

One command, on a fresh machine or an existing checkout, and safe to re-run:

```bash
curl -fsSL https://raw.githubusercontent.com/AH-Merii/SMS-Supercharge-My-Shell/main/bootstrap.sh | sh   # fresh machine
./bootstrap.sh                                                                                          # existing checkout
```

`bootstrap.sh` installs git, stow, fish and mise with the OS package manager (Homebrew on
macOS and WSL), clones the repo to `~/SMS-Supercharge-My-Shell` if needed, and runs
`mise run setup`: OS packages, symlinks, tools, plugins and, on the Arch desktop, the login
screen. Files already sitting where a link belongs are moved to `<name>.bak`, never
overwritten.

Nothing installs before you have seen it. Both steps print what they are about to do —
packages split into what is already installed and what is not, the stow layers and any
files that would be backed up, the missing mise tools — and ask `Proceed? [Y/n]`, default
yes. `setup` asks once for all its steps; answering yes there also skips pacman's and
apt's own prompts, since the plan already named every package. paru is the exception: its
PKGBUILD review survives, because the plan never showed you a PKGBUILD.

```bash
./bootstrap.sh -y                     # accept everything, including paru's review
SMS_YES=1 mise run setup              # same, for the setup half only
curl -fsSL <url> | sh -s -- -y        # unattended, piped
mise run deps                         # any single task previews and asks too
NO_COLOR=1 mise run setup             # plain text
```

Two things stay manual because they need you: `chsh -s "$(command -v fish)"` for the login
shell, and `ggh op init` (or `ggh init`) for git identity and commit signing. fish prints a
reminder until the latter is done.

## Tasks

| Task      | What it does                                                        |
| --------- | ------------------------------------------------------------------- |
| `setup`   | `deps`, `link`, `tools`, `plugins`, `greeter` in order              |
| `deps`    | OS packages: pacman/paru on Arch, apt on Debian, `brew bundle` on macOS/WSL |
| `link`    | Stow the layers for this profile; conflicting files go to `.bak` (`STOW_FLAGS=-n` to dry-run) |
| `unlink`  | Remove those symlinks                                               |
| `check`   | Dry-run `link`                                                      |
| `tools`   | `mise install` everything in the global mise config                 |
| `plugins` | fisher + fish plugins, TPM + tmux plugins                           |
| `greeter` | Arch desktop: greetd + noctalia-greeter as the login screen, synced to the Noctalia theme; a no-op elsewhere |
| `profile` | Print the detected profile                                          |

Run with `mise run <task>`; `mise tasks` lists them. Every task except `check` and
`profile` previews what it would do and asks first; `SMS_YES=1` skips the asking. The
preview code lives in `lib/plan.sh` and is shared, so a task's own preview and the
combined one `setup` prints cannot disagree.

## Where a dependency goes

1. **mise** (`base/mise/.config/mise/config.toml`) for anything `mise registry <tool>` or a
   `github:`/`npm:`/`cargo:` backend can install: runtimes (node, bun, go, rust, uv) and CLI
   tools (neovim, starship, ripgrep, fzf, ...). Same versions on every OS, no root needed.
   `mise use -g <tool>` edits the stowed file, so commit the result.
2. **`pkglist/`** on Arch and Debian, **`Brewfile`** on macOS and WSL, for what mise cannot
   build: fish, stow, tmux, gnupg, luarocks, GUI apps and fonts. Desktop-only packages go in
   `pkglist/arch-desktop.txt`; AUR packages in `pkglist/aur.txt`.

Homebrew is not installed on Arch: `brew shellenv` would put its own python, perl and git in
front of pacman's.

## Stow

`.stowrc` sets the target to `~`, defaults the package dir to `base/`, and turns off folding
so directories in `~` stay real directories and runtime files (fish history, tmux plugins,
Noctalia's generated files) never land in the repo.

```bash
stow fish                 # link one base package
stow -d desktop niri      # link a package from another layer
stow -D fish              # unlink
stow -n fish              # dry-run
```

Stow refuses to overwrite a real file. `mise run link` moves such files to `<name>.bak`
first; when calling `stow` by hand, move them aside yourself. Do not use `--adopt`, it copies
the old file into the repo.

## Machine notes

- **Arch desktop (CachyOS niri + Noctalia).** GPU drivers come from the installer (`chwd`);
  enable persistence with `sudo systemctl enable nvidia-persistenced` if wanted.
  Noctalia v5 keeps its settings in `~/.local/state/noctalia/settings.toml`, which the
  settings UI writes to; that file is a symlink into `desktop/noctalia`, so GUI changes show
  up in `git status` and you commit the ones you mean to keep (`noctalia config validate`
  checks it). Monitor names, wallpaper paths and battery device paths in it are
  machine-specific. niri includes `noctalia.kdl`, which Noctalia generates from the theme
  templates; `mise run link` creates an empty placeholder for the first login.
  The login screen is [greetd](https://sr.ht/~kennylevinsen/greetd/) running
  [noctalia-greeter](https://github.com/noctalia-dev/noctalia-greeter) (Wayland, no Xorg)
  instead of the installer's sddm. `mise run greeter` installs the files from `system/`,
  flips the enabled display manager (effective at the next boot; sddm stays installed as
  the way back), and runs `noctalia msg greeter-sync` so the wallpaper, palette and monitor
  layout match the desktop (restarting Noctalia once if it started before the greeter was
  installed, as it has on a fresh machine). `settings.toml` keeps that sync automatic and turns on
  Noctalia's polkit agent, which is what puts the sync's password prompt on screen.
  `/etc/pam.d/greetd` carries `pam_gnome_keyring`, so the login password still unlocks the
  keyring.
- **macOS.** Homebrew installs the casks in the `Brewfile` (ghostty, karabiner-elements,
  1password, fonts). Add `$(command -v fish)` to `/etc/shells` before `chsh`.
- **WSL2.** apt covers the base packages, Homebrew supplies mise and a current fish. The
  clipboard goes through `clip.exe` in fish and tmux automatically.
- **Servers.** `base` profile only; nothing desktop-related is linked or installed.

## Shell

fish with [starship](https://starship.rs), [fisher](https://github.com/jorgebucaran/fisher)
plugins from `fish_plugins`, and these replacements:

| Command | Replacement                                    |
| ------- | ---------------------------------------------- |
| `cat`   | [bat](https://github.com/sharkdp/bat)          |
| `grep`  | [ripgrep](https://github.com/BurntSushi/ripgrep) |
| `ls`    | [eza](https://github.com/eza-community/eza)    |
| `diff`  | [delta](https://github.com/dandavison/delta)   |

`hints` (or `Ctrl+?`) opens a searchable cheatsheet of the shell's key bindings, abbreviations,
aliases and functions, all at once or one group per hotkey inside the picker; `hints GROUP`
and `keys` open on one group. Enter puts the highlighted name on the command line (a key
binding runs instead) and Alt+Enter runs it. The preview shows what an entry does and, where
that is safe to fetch on every cursor move, the `--help` of what it runs: always for external
commands and builtins, for a function only when its source handles the flag, coloured by bat's
command-help syntax. Nothing is documented by hand except the key bindings: abbreviations carry
their expansion and aliases their body, coloured so the command words stand out from their
arguments, and functions their description; the functions group is whatever this config defines,
autoloaded or inline in `conf.d`, minus `_` helpers and `fish_*` hooks. Bindings are read live
from `bind --user`, so the list cannot go stale; their descriptions come from
`keys_bind KEY COMMAND LABEL [DETAIL...]`, which binds and describes in one call so a shortcut
cannot move without its text. Anything bound some other way still shows, marked "no
description" and sorted first, so it gets noticed. Files whose bindings are editing behaviour
rather than shortcuts (autopair, vi-mode paste) are excluded by name in `_hints_rows_keys`.
fzf.fish's own defaults are disabled in `conf.d/20-fzf.fish` and re-bound there through
`keys_bind` so they are described too, as are `Ctrl+T` and `Alt+C` from fzf's own shell
integration (`fzf --fish`), which is loaded there without its key binds. Each group is a
`_hints_rows_GROUP` function emitting the same row format, so a new group is one more of those.

`$OS_KIND` (`linux`, `macos`, `wsl`) is set once in `conf.d/00-os.fish`; Homebrew, the
1Password SSH agent socket and the clipboard command branch on it. `conf.d/01-env.fish` moves
gpg to `~/.local/share/gnupg` and creates it, since gpg only auto-creates `~/.gnupg`.
