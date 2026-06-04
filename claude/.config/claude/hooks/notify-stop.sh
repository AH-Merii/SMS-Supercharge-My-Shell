#!/bin/bash
# Async Stop hook: notify when Claude finishes responding
# Sources shared library for multi-channel notifications

INPUT=$(cat)

# Guard against infinite loops (stop_hook_active means Claude is continuing)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_ACTIVE" == "true" ]]; then
    exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# Source shared notification library
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=notify-lib.sh
source "$HOOK_DIR/notify-lib.sh"

notify "Done" "Ready for input" "low" "claude-$SESSION_ID" "$CWD" "$SESSION_ID"

exit 0
