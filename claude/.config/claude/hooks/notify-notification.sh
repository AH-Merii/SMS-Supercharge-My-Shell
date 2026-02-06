#!/bin/bash
# Async Notification hook: notify when Claude needs input
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Terminal bell
printf '\a'

# macOS notification
if command -v terminal-notifier &>/dev/null; then
  terminal-notifier \
    -title "Claude Code" \
    -subtitle "Needs Input" \
    -message "Waiting for permission or response" \
    -sound "Ping" \
    -group "claude-$SESSION_ID"
fi

exit 0
