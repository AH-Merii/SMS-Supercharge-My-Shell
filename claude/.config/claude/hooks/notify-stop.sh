#!/bin/bash
# Async Stop hook: notify when Claude finishes responding
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Terminal bell (passes through tmux to Ghostty)
printf '\a'

# macOS notification
if command -v terminal-notifier &>/dev/null; then
  terminal-notifier \
    -title "Claude Code" \
    -message "Done -- ready for input" \
    -sound "Glass" \
    -group "claude-$SESSION_ID"
fi

exit 0
