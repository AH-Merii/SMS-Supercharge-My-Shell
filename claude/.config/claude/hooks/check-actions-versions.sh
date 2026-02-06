#!/bin/bash

# Post-hook: remind Claude to verify GitHub Action versions when editing workflow files
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

echo "You edited a GitHub Actions workflow file. For any NEW actions you are adding, verify you are using the latest major version (check with: gh api repos/OWNER/REPO/tags --jq '.[0].name'). Do NOT bump versions of actions that were already pinned — only verify newly added ones." >&2
exit 0
