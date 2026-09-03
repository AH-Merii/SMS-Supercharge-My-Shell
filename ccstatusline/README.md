# ccstatusline

Claude Code status line, managed via [GNU Stow](https://www.gnu.org/software/stow/) from `~/SMS-Supercharge-My-Shell/ccstatusline/`.

Apply changes: `cd ~/SMS-Supercharge-My-Shell && stow -vt ~ ccstatusline`

## What it looks like

```
󰉋 ~/SMS-Supercharge-My-Shell   spring-cleaning  *?  +1  -1  ▓▓▓▓░░░░░░ 42%  󰷑 Opus  high   12m  5h 23.5%  7d 41.2%
```

## Directory Structure

```
ccstatusline/
└── .config/ccstatusline/            # -> ~/.config/ccstatusline/
    ├── settings.json                # Widget layout, colors, global options
    └── context-bar.sh               # Threshold-colored context-usage bar
```

## Setup

1. **Install the binary.** Handled by `install/` (`NPM_GLOBAL_PACKAGES` in `install/common.sh`), or by hand:

   ```bash
   npm install -g ccstatusline@2.2.28
   ```

   The version is pinned deliberately. `npx -y ccstatusline@latest` re-resolves the package on every repaint, which upstream measures at ~430ms; a pinned global binary avoids it. Note that `npm -g` installs under mise's node prefix, so this needs re-running after a node major bump.

2. **Stow this package**, so `~/.config/ccstatusline/settings.json` points back here.

3. **Point Claude Code at it.** Already set in `claude/.config/claude/settings.json`:

   ```json
   "statusLine": { "type": "command", "command": "ccstatusline", "padding": 0 }
   ```

   That file only takes effect once the `claude` package is stowed too.

## Widgets

Left to right, all on one line. Colors mirror `starship/.config/starship/starship.toml` so both prompts read as one system.

| Widget (`type`) | Shows | Color |
|---|---|---|
| `current-working-dir` | Fish-style abbreviated path, `󰉋` icon | bold cyan (starship `[directory]`) |
| `git-branch` | Branch name, `` icon, truncated at 24 chars | bold white (starship `[git_branch]`) |
| `git-status` | `+` staged, `*` unstaged, `?` untracked, `!` conflicts | yellow |
| `git-insertions` | Working-tree lines added | green (starship `added_style`) |
| `git-deletions` | Working-tree lines removed | red (starship `deleted_style`) |
| `custom-command` | Context bar — see below | script-owned |
| `model` | Model short name, `󰷑` icon | cyan |
| `thinking-effort` | Reasoning effort level | magenta |
| `session-clock` | Session wall-clock duration, `` icon | yellow |
| `session-usage` | 5-hour rate-limit window, `5h` label | bright blue |
| `weekly-usage` | 7-day rate-limit window, `7d` label | bright blue |

Session **cost** is deliberately omitted — the account is on a subscription plan, so the rate-limit windows are the number that matters.

Icons come from the widgets' own `character` field where they support one (`current-working-dir`, `git-branch`) and from `custom-symbol` / `custom-text` widgets with `merge: true` elsewhere — merging suppresses the separator so the glyph rides along with the value instead of becoming its own segment.

`git-insertions` / `git-deletions` are **working-tree** diff counts, not the session's `cost.total_lines_added`.

## context-bar.sh

ccstatusline's built-in `context-bar` widget renders in one static color. This script replaces it to get thresholds:

```
▓▓▓▓░░░░░░ 42%     green   <70%
▓▓▓▓▓▓▓░░░ 75%     yellow  70-89%
▓▓▓▓▓▓▓▓▓░ 95%     red     >=90%
```

**Contract:** ccstatusline pipes Claude Code's status-line JSON payload to the script's stdin and keeps its ANSI codes because the widget sets `preserveColors: true`. The script reads `.context_window.used_percentage`, falling back to computing it from `current_usage` (input + cache creation + cache read) over `context_window_size`. Both are null before the first API call and just after `/compact`, in which case it prints nothing and exits 0 rather than showing a bogus empty bar.

Test it standalone:

```bash
for p in 42 75 95; do
  jq -nc --argjson p $p '{context_window:{used_percentage:$p,context_window_size:200000}}' \
    | ./.config/ccstatusline/context-bar.sh
done
```

## Editing

`ccstatusline` with no arguments opens a TUI configurator that writes to `~/.config/ccstatusline/settings.json`. It resolves symlinks before writing, so edits made through the TUI land in this repo rather than replacing the symlink — commit them afterwards.

To preview a config without touching `~`, pass `--config` and pipe it a payload:

```bash
ccstatusline --config .config/ccstatusline/settings.json < sample-payload.json
```
