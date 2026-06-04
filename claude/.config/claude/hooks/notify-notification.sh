#!/bin/bash
# Async Notification hook: notify when Claude needs user attention
# Sources shared library for multi-channel notifications

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# Extract notification fields with fallbacks
TITLE=$(echo "$INPUT" | jq -r '.title // "Needs attention"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Waiting for input"')
NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // "other"')

# Map notification_type to urgency level
case "$NOTIFICATION_TYPE" in
    permission_prompt)   URGENCY="high" ;;
    elicitation_dialog)  URGENCY="high" ;;
    idle_prompt)         URGENCY="medium" ;;
    auth_success)        URGENCY="low" ;;
    *)                   URGENCY="medium" ;;
esac

# Source shared notification library
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=notify-lib.sh
source "$HOOK_DIR/notify-lib.sh"

notify "$TITLE" "$MESSAGE" "$URGENCY" "claude-$SESSION_ID" "$CWD" "$SESSION_ID"

exit 0
