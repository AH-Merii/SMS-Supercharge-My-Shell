#!/bin/bash

# Post-hook: auto-format markdown files with prettier after Write/Edit
# Reads JSON from stdin containing tool result information

INPUT=$(cat)

# Skip formatting for Edit tool — reformatting would break old_string matching
# on consecutive edits. Only format after Write.
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
if [ "$TOOL_NAME" = "Edit" ]; then
  exit 0
fi

# Extract file path from JSON
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_response.filePath // empty')

# If no file path found, exit silently
if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ]; then
  exit 0
fi

# Only run on markdown files
case "$FILE_PATH" in
  *.md|*.mdx|*.markdown) ;;
  *) exit 0 ;;
esac

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Check if bunx is available
if ! command -v bunx &>/dev/null; then
  echo "bunx is not installed. Ask the user if they want you to install bun (https://bun.sh) or if they will install it manually." >&2
  exit 2 # Show error to Claude (cannot block — tool already ran)
fi

# Format with prettier
OUTPUT=$(bunx prettier --write "$FILE_PATH" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "prettier format failed for $FILE_PATH" >&2
  echo "$OUTPUT" >&2
  exit 0 # Don't block on format failures
fi

echo "formatted $FILE_PATH with prettier"
exit 0
