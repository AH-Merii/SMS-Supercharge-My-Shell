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
pkglist/     pacman / AUR / apt package lists
Brewfile     Homebrew packages for macOS and WSL
mise.toml    tasks (see below); mise-tasks/ holds the scripts
setup.sh     the one command: OS packages, clone, then `mise run setup`
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
curl -fsSL https://raw.githubusercontent.com/AH-Merii/SMS-Supercharge-My-Shell/main/setup.sh | sh   # fresh machine
./setup.sh                                                                                          # existing checkout
```

`setup.sh` installs git, stow, fish and mise with the OS package manager (Homebrew on
macOS and WSL), clones the repo to `~/SMS-Supercharge-My-Shell` if needed, and runs
`mise run setup`: OS packages, symlinks, tools, plugins. Files already sitting where a link
belongs are moved to `<name>.bak`, never overwritten.

Two things stay manual because they need you: `chsh -s "$(command -v fish)"` for the login
shell, and `ggh op init` (or `ggh init`) for git identity and commit signing. fish prints a
reminder until the latter is done.

## Tasks

| Task      | What it does                                                        |
| --------- | ------------------------------------------------------------------- |
| `setup`   | `deps`, `link`, `tools`, `plugins` in order                         |
| `deps`    | OS packages: pacman/paru on Arch, apt on Debian, `brew bundle` on macOS/WSL |
| `link`    | Stow the layers for this profile; conflicting files go to `.bak` (`STOW_FLAGS=-n` to dry-run) |
| `unlink`  | Remove those symlinks                                               |
| `check`   | Dry-run `link`                                                      |
| `tools`   | `mise install` everything in the global mise config                 |
| `plugins` | fisher + fish plugins, TPM + tmux plugins                           |
| `profile` | Print the detected profile                                          |

Run with `mise run <task>`; `mise tasks` lists them.

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

`$OS_KIND` (`linux`, `macos`, `wsl`) is set once in `conf.d/00-os.fish`; Homebrew, the
1Password SSH agent socket and the clipboard command branch on it.
