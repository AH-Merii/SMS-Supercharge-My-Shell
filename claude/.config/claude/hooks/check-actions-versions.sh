#!/bin/bash

# PostToolUse hook: remind Claude to verify GitHub Action versions when editing workflow files
# Reads JSON from stdin containing tool result information

INPUT=$(cat)

# Extract file path from JSON
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_response.filePath // empty')

# If no file path found, exit silently
if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ]; then
  exit 0
fi

# Only run on GitHub Actions workflow files
case "$FILE_PATH" in
  */.github/workflows/*.yml|*/.github/workflows/*.yaml|*/.github/actions/*.yml|*/.github/actions/*.yaml) ;;
  *) exit 0 ;;
esac

# Only fire when the edit actually contains a GitHub Action reference
EDIT_CONTENT=$(echo "$INPUT" | jq -r '(.tool_input.new_string // "") + (.tool_input.content // "")')
case "$EDIT_CONTENT" in
  *uses:*) ;;
  *) exit 0 ;;
esac

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "You edited a GitHub Actions workflow file with action references. For any NEW actions you are adding, verify you are using the latest major version (check with: gh api repos/OWNER/REPO/tags --jq '.[0].name'). Do NOT bump versions of actions that were already pinned — only verify newly added ones."
  }
}
EOF
exit 0
