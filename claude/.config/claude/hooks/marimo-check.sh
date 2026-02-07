#!/bin/bash

# Hook to check marimo notebooks after Write/Edit operations
# Reads JSON from stdin containing tool result information

# Read stdin (contains JSON with tool result)
INPUT=$(cat)

# Extract file path from JSON using jq
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_response.filePath // empty')

# If no file path found, exit silently
if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ]; then
  exit 0
fi

# File path from tool_response is already absolute, no need to modify it

# Only process Python files
case "$FILE_PATH" in
  *.py) ;;
  *) exit 0 ;;
esac

# Check if file exists and is a Python file
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Check if the file appears to be a marimo notebook
if grep -q "import marimo" "$FILE_PATH" 2>/dev/null && grep -q "@app.cell" "$FILE_PATH" 2>/dev/null; then
  echo "Running marimo check on $FILE_PATH..."

  # Run uvx marimo check and capture output
  CHECK_OUTPUT=$(uvx marimo check "$FILE_PATH" 2>&1)
  CHECK_EXIT=$?

  # Show output
  echo "$CHECK_OUTPUT"

  # Only block on errors (non-zero exit code), not warnings
  if [ $CHECK_EXIT -ne 0 ]; then
    echo "✗ Marimo check failed for $FILE_PATH" >&2
    echo "$CHECK_OUTPUT" >&2
    echo "" >&2
    echo "Please run 'uvx marimo check $FILE_PATH' to see details and fix the issues. Don't ask the user anything, just do a best effort fix." >&2
    exit 2 # Exit code 2 blocks and shows error to Claude
  else
    echo "✓ Marimo check passed"
    exit 0
  fi
fi

# Not a marimo notebook, exit successfully
exit 0
