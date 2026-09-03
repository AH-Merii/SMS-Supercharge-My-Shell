# herdr vs. tmux — coverage evaluation

**Date:** 2026-09-03
**Outcome:** herdr added as a coexisting stow package. tmux remains the default multiplexer.

[herdr](https://herdr.dev) is a Rust "agent multiplexer" — a terminal multiplexer that tracks
whether each pane's AI coding agent is `working`, `blocked`, `done` or `idle` and surfaces that
in a sidebar. It keeps tmux's inheritance (real PTYs, detach/reattach, SSH, a resident server).

It is **not** a feature-for-feature tmux replacement, and does not claim to be. Its own
comparison page frames the two as different categories — "multiplexer versus runtime" — and
there is no official tmux migration guide. This document records what actually carries over
from `tmux/.config/tmux/`, so the decision is cheap to revisit.

## Verdict

The current tmux setup runs **11 plugins** (10 via TPM plus catppuccin cloned by hand), plus
`sesh`, plus a hand-rolled vim-navigator snippet. Of those:

- **7 become redundant or trivially replaced** by herdr natives.
- **2 have no viable path** and were dropped.
- **3 are real work** — and none were load-bearing at evaluation time, so all three were deferred.

Net shape if fully migrated: 11 plugins → roughly 2 third-party plugins + 1 status script.

## Covered natively (dropped)

| tmux plugin | herdr native | Note |
|---|---|---|
| `tmux-plugins/tpm` | `herdr plugin install owner/repo` + `herdr-plugin.toml` | The whole TPM bootstrap `if-shell` block in `plugins.tmux.conf` disappears. No lockfile — pin with `--ref`. Marketplace is just GitHub repos tagged `herdr-plugin`. |
| `tmux-plugins/tmux-sensible` | mouse, clipboard, truecolor, focus-events default-on | Also obsoletes the undercurl / `xterm-keys` / `escape-time` / `extended-keys` block in `settings.tmux.conf`. |
| `catppuccin/tmux` | built-in — catppuccin (mocha) is herdr's default theme | Replaces the manual `git clone`. Supports `auto_switch` + `light_name`/`dark_name` if wanted. **Caveat:** bundled palettes are mocha, latte, tokyo-night, tokyo-night-day, dracula, terminal, vesper — **no frappe**, which `theme.tmux.conf` pins via `@catppuccin_flavor "frappe"`. Deliberately running the stock default for now; matching frappe would mean hand-writing `[theme.custom]` hex overrides. |
| `omerxx/tmux-floax` | `[[keys.command]] type = "popup"` | Direct port, ~6 lines. Also covers the `display-popup` man-page bindings (`prefix+m` / `prefix+M`). |
| `sesh` + `configure-sesh-tmux-bindings.sh` | `goto` (`prefix+g`, "session navigator") and `workspace_picker` (`prefix+w`) | Native covers the common case. The existing sesh picker is richer (6 fzf mode-switch bindings, preview pane); third-party `herdr-sesh-bro` / `herdr-sessionizer` / `herdr-navigator` add zoxide+fzf if that's missed. |
| copy-mode-vi bindings | Native, and vi-only | `prefix+[` enters; `/` `?` `n` `N` search; `v`/`Space` select, `y`/`Enter` copy, `q`/`Esc` exit; `w/b/e`, `W/B/E`, `{`/`}`, `ctrl+u/d`, `ctrl+b/f` move. The `v`/`y`/`C-v` binds in `keybinds.tmux.conf` **are already the default**. Mouse drag-select copies without entering copy mode. |
| `reset-tmux-keybindings-to-default.sh` | — | Obsolete by design: herdr's config is declarative TOML, not accumulated server state. |

## No viable path (dropped)

| tmux plugin | Why |
|---|---|
| `joshmedeski/tmux-nerd-font-window-name` | No equivalent. herdr's `state_icon` is agent-state driven, not foreground-process driven. |
| `fcsonline/tmux-thumbs` | herdr has Ctrl-click for OSC 8 hyperlinks and visible URLs, plus real copy-mode search — but no hint/label jumping. The tmux config set zero `@thumbs-*` options, so it was running on defaults anyway. Third-party `herdr-copy-search` adds regex/copycat + extrakto token extraction if it's ever missed. |

## Deferred — real work, not currently load-bearing

### 1. vim `C-hjkl` navigation

The most interesting gap. herdr's `focus_pane_*` actions are **prefix-bound and not
vim-aware**; the current tmux bindings are root-table `C-hjkl` (no prefix), which is the entire
point of the feature. `keybinds.tmux.conf` implements this by hand with an `is_vim` check
(`ps -o state= -o comm=` piped to `grep`), having deliberately dropped
`christoomey/vim-tmux-navigator` from TPM.

Three ecosystem solutions exist, and the split between them is essentially **cost per keystroke**:

| Project | Approach | Trade-off |
|---|---|---|
| [`vim-herdr-navigation`](https://github.com/paulbkim-dev/vim-herdr-navigation) | Literal tmux port. Per keypress: `herdr pane process-info` → `jq` → either `herdr pane send-keys` into vim or `herdr pane focus --direction`. Editor side maps to `wincmd` and calls back on edge, locating itself via `$HERDR_PANE_ID`. | Simplest, supports Vim **and** Neovim. Forks two processes per keypress. Needs `jq`. Normal-mode only. |
| [`herdr-nvim-nav`](https://github.com/aimdevlee/herdr-nvim-nav) | Neovim writes a PID marker to `$XDG_CACHE_HOME/herdr/nvim-panes/<pane-id>` on entry, removes on exit; stale PIDs reaped via `kill(pid, 0)`. The herdr action is **compiled C talking directly to the control socket**, not a CLI wrapper. | Fastest — herdr's fork/exec baseline is ~2.4ms, this completes in ~3ms total. Neovim-only, needs a C compiler at install. |
| [`herdr-splits.nvim`](https://github.com/lmilojevicc/herdr-splits.nvim) | `smart-splits.nvim` ported to herdr's CLI. Two-way cooperation. | Adds **resizing** as well as navigation, plus `at_edge = 'wrap'` and auto-unzoom. Needs Neovim ≥ 0.10. |

**Cost here:** all three still list `christoomey/vim-tmux-navigator` as a dependency for the
case where Neovim runs *under tmux*. In a coexist setup the nvim package ends up carrying both.
`nvim/.config/nvim/lazy-lock.json` currently pins vim-tmux-navigator at
`e41c431a0c7b7388ae7ba341f01a0d217eb3a432`. Known wart shared with the tmux setup: `C-l`/`C-k`
shadow readline functions in non-vim panes.

### 2. Status line (cpu / ram / ip / battery)

herdr has **no** native cpu, ram, battery or IP modules. `[ui] tab_bar_right` accepts only five
entry types: `zoom`, `hostname`, `datetime`, `text`, and `command`.

So `tmux-cpu` + `tmux-battery` + `dreknix/tmux-primary-ip` + the three files in
`tmux/.config/tmux/custom_modules/` all collapse into a **single** `type = "command"` entry
pointing at one shell script, with `interval_seconds = 3` matching `set -g status-interval 3`.

That is a real simplification, but the script is hand-written and the
`@cpu_low/medium/high_bg_color` threshold coloring becomes the script's job (emit ANSI itself).

The bigger loss is expressiveness: `theme.tmux.conf` uses a format-string DSL
(`#{E:@catppuccin_status_*}`, `#[fg=...,bg=...]`, `#{?window_zoomed_flag,...}`). herdr offers a
typed five-variant list. The left-status content — prefix indicator, `#{pane_current_command}`,
truncated path, zoom flag — has no direct home; `zoom` is a built-in type and the rest would
need to fold into the same script or be abandoned.

### 3. Claude Code notification hooks

`claude/.config/claude/hooks/notify-lib.sh` is tmux-specific in two places: `get_pane_label()`
calls `tmux display-message -t "$TMUX_PANE" -p '#S:#I (#W)'`, and `send_osc()` wraps OSC 777 in
a **tmux DCS envelope** (`\033Ptmux;\033\033]777;notify;...`). Both are inert under herdr. This
is the counterpart of `allow-passthrough on` / `monitor-bell on` in `settings.tmux.conf`.

Replacing them is arguably an **upgrade**: herdr has native `[ui.toast]` (delivery
`herdr` / `terminal` / `system` / `off`, positioning, delay) and `[ui.sound]` with per-agent
overrides (`[ui.sound.agents] claude = "on"`), driven by real agent state rather than a bell.

### 4. `tmux-resurrect` + `tmux-continuum`

Partly native. herdr's resident server keeps panes and agents alive across client **detach**,
and `[session] resume_agents_on_restore = true` restores the underlying agent conversation.
That is not the same as surviving a **reboot**.
[`herdr-resurrect`](https://github.com/ntindle/herdr-resurrect) fills the gap — continuum-style
versioned snapshots, debounced to at most one write per 20s. Deferred because detach-survival
was judged sufficient. Note `@resurrect-capture-pane-contents 'on'` has no documented herdr
equivalent.

## No equivalent found

- Full-window splits (`split-window -fh` / `-fv`, bound to `M-V` / `M-S`).
- `base-index 1` / `pane-base-index 1` / `renumber-windows on`.
- The no-wrap pane navigation idiom `if -F '#{pane_at_left}' '' 'select-pane -L'`. herdr's wrap
  behaviour at edges is undocumented; `herdr-nav-plus` advertising "wraps at both ends" implies
  the native default may not wrap.
- Per-binding `confirm-before` prompts (used on kill-session / kill-server). herdr has a global
  `ui.confirm_close = true` instead.

## Rejected: automated conversion

[`tmux2herdr`](https://github.com/sohilladhani/tmux2herdr) parses tmux 3.x into an AST and maps
it to herdr config. It was **not** used. Its own README reports ~38 untranslatable items from a
sample config and explicitly cannot handle `escape-time`, `base-index`, or `mode-keys vi` — all
three of which the current tmux config uses. Starting from `herdr --default-config` and layering
only genuine deviations produces a much smaller, cleaner file.

## Packaging notes

`herdr` is in homebrew/core (0.8.2 at time of writing, Apache-2.0), so it is a plain entry in
`BREW_PACKAGES` in `install/common.sh` — unlike `sesh`, which `plugins.tmux.conf` lazily
`brew install`s at tmux startup.

The `herdr` package **must** use `--no-folding` (the root `.stowrc` applies it to every
package). herdr writes
`herdr.log`, `herdr-client.log`, `herdr-server.log` and plugin state directly into
`~/.config/herdr/`. With default folding that directory becomes a symlink into this repo, and
herdr would write its logs into the git working tree.

## References

- [Configuration](https://herdr.dev/docs/configuration/) ·
  [Config reference](https://herdr.dev/docs/config-reference/) ·
  [Concepts](https://herdr.dev/docs/concepts/) ·
  [Plugins](https://herdr.dev/docs/plugins/) ·
  [Socket API](https://herdr.dev/docs/socket-api/)
- Object model: tmux session/window/pane → herdr **workspace**/**tab**/**pane**, with
  *sessions* being a separate concept (persistent namespaces with their own socket and state).
- Scripting: `herdr pane send_text` / `send_keys`, `herdr pane split`, `herdr workspace create`,
  `herdr agent wait --until done` replace `tmux send-keys` / `new-session -d` / `list-sessions`.
