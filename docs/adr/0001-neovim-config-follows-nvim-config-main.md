# The Neovim config is the nvim-config submodule, following its main

The Neovim config moved out of this repo into
[AH-Merii/nvim-config](https://github.com/AH-Merii/nvim-config), which targets Neovim
nightly only. SMS checks it out as the `nvim-config/` submodule with `branch = main` and
`ignore = all`, and `mise run link` runs `git submodule update --init --remote` before
stowing, so a machine takes nvim-config's latest main whenever it links, with no commit
here. The `nvim` stow package is one relative link, `.config/nvim -> ../../../nvim-config/nvim`:
with `--no-folding`, stowing the repo itself would link each of its files one by one. The
global mise config pins `neovim = "nightly"`, and `mise run tools` reinstalls it on every
run, because mise never fetches a newer build of a version it already has.

## Considered options

- **A scheduled workflow that bumps the recorded commit.** Each config change would land
  here as a commit, but main takes changes only through pull requests (ruleset
  `deny-push-to-main`), and this repo does not let `GITHUB_TOKEN` open them.
- **`~/.config/nvim` linked straight to a development clone of nvim-config.** No submodule,
  but every machine would need that clone at that path, and unpushed work would reach the
  everyday `nvim`.

## Consequences

- An SMS commit no longer says which config a machine runs; `git -C nvim-config log -1`
  does.
- lazy.nvim writes `lazy-lock.json` inside the submodule. When that edit blocks an update,
  `link` moves it to `lazy-lock.json.bak` and checks out nvim-config's.
