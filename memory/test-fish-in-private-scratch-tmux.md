---
name: test-fish-in-private-scratch-tmux
description: "Drive interactive fish features (pickers, bindings) in a scratch tmux server running `fish --private`, never plain `fish`, so test commands stay out of the user's history"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 74167f33-3b60-4623-8e09-a5b433d2aae2
  modified: 2026-09-08T18:33:33.744Z
---

When testing interactive fish features (fzf pickers, key bindings, `commandline`), drive
them in a scratch tmux server (`tmux -L scratch new -d ... 'fish --private'`) and capture
the pane. Always start the shell as `fish --private` (or `set -gx fish_history ''`).

**Why:** On 2026-09-08 the hints picker was tested in scratch tmux sessions running plain
`fish`, and all 31 test commands (probe functions, `explorerclear`, ...) landed in the
user's real `~/.local/share/fish/fish_history`; they had to be removed by hand. One test
also fuzzy-picked the `explorer` alias and opened a file manager on the desktop.

**How to apply:** `fish --private` for every scratch session. Use `set -e TMUX` inside it
when a picker uses `fzf-tmux -p`, since popups need an attached client and cannot be
captured; `fzf-tmux -d` split mode is capturable and goes through the same argument file.
Prefer harmless entries (or a throwaway abbr) when a test will run what it picks. In vi
mode, test bindings with `bind -M insert`. See [[dotfiles-layers-and-mise]] for why new
function files also need a `stow -d base -R fish` before fish can see them.
