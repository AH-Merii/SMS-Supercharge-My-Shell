#!/bin/bash
# Async Notification hook: notify when Claude needs input
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Extract notification fields with fallbacks
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Waiting for permission or response"')

# Terminal bell
printf '\a'

# macOS notification
if command -v terminal-notifier &>/dev/null; then
  terminal-notifier \
    -title "Claude Code" \
    -subtitle "$TITLE" \
    -message "$MESSAGE" \
    -sound "Ping" \
    -group "claude-$SESSION_ID"
fi

exit 0
