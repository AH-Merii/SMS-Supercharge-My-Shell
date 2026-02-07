#!/bin/bash
# Stop hook: soft one-shot reminder to sync git docs
# Checks if git config files were edited (tracked by PostToolUse hook).
# Blocks ONCE with a gentle reminder, then clears the flag.

INPUT=$(cat)

# If another stop hook is active, clear our flag and exit
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  # Clean up any session-scoped flag files
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
  if [ -n "$SESSION_ID" ]; then
    rm -f "/tmp/claude-git-docs-dirty-${SESSION_ID}"
  fi
  exit 0
fi

# Session-scoped flag file
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
if [ -z "$SESSION_ID" ]; then
  exit 0
fi

DIRTY_FLAG="/tmp/claude-git-docs-dirty-${SESSION_ID}"

if [ ! -f "$DIRTY_FLAG" ]; then
  exit 0
fi

# Atomic read-delete: move to temp, read, delete temp
TEMP_FLAG="${DIRTY_FLAG}.reading"
if ! mv "$DIRTY_FLAG" "$TEMP_FLAG" 2>/dev/null; then
  # File was already moved by another process
  exit 0
fi

EDITED_FILES=$(sort -u "$TEMP_FLAG")
rm -f "$TEMP_FLAG"

if [ -z "$EDITED_FILES" ]; then
  exit 0
fi

# Use jq to safely construct JSON with proper escaping
ESCAPED_FILES=$(echo "$EDITED_FILES" | jq -Rs '.')
jq -n --argjson files "$ESCAPED_FILES" '{
  decision: "block",
  reason: ("Git config files were edited during this session:\n" + $files + "\nConsider updating the docs to stay in sync:\n- CONFIG.md (git/.config/git/CONFIG.md): settings tables\n- README.md (git/.config/git/README.md): alias table, Post-Clone Setup, Utilities\n\nIf no doc changes are needed, just finish up.")
}'
