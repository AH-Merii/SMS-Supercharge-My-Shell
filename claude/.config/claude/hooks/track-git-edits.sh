#!/bin/bash
# PostToolUse hook: silently track edits to git/ config files
# Sets a dirty flag for the Stop hook to pick up — no context injection.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_response.filePath // empty')

[ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ] && exit 0

# Track config and script edits, but NOT doc edits (avoid self-triggering)
case "$FILE_PATH" in
  */git/.config/git/README.md | */git/.config/git/CONFIG.md)
    exit 0
    ;;
  */git/.config/git/* | */git/.local/bin/*)
    echo "$FILE_PATH" >>/tmp/claude-git-docs-dirty
    ;;
esac

exit 0
