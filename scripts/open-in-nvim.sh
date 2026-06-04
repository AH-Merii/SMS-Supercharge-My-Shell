#!/bin/bash
# Open files in Neovim inside Ghostty — used by Platypus .app for macOS "Open With"

GHOSTTY="/Applications/Ghostty.app/Contents/MacOS/ghostty"
LOGIN_SHELL="${SHELL:-/opt/homebrew/bin/fish}"

# Build escaped file arguments for fish
nvim_args=""
for f in "$@"; do
    abs="$(realpath "$f" 2>/dev/null || echo "$f")"
    # Single-quote each path for fish, escaping embedded single quotes
    nvim_args="${nvim_args} '${abs//\'/\\\'}'"
done

# Launch Ghostty directly (new window, not a pane in existing instance)
# Uses login shell (-l) so nvim inherits full environment (PATH, Mason, LSP, etc.)
exec "$GHOSTTY" \
    --title=nvim \
    -e "${LOGIN_SHELL}" -l -c "exec nvim${nvim_args}"
