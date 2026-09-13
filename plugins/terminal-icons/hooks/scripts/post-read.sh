#!/usr/bin/env bash
# PostToolUse hook: Identify PUA Unicode characters after Read operations.
#
# When Claude reads a file containing PUA characters, this hook identifies
# them by name and codepoint so Claude knows what icons are present.
#
# Outputs JSON with additionalContext so Claude sees the icon info in context.

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"

# Extract file path from stdin JSON; non-JSON input is ignored rather than fatal
FILE_PATH=$(jq -r '.tool_input.file_path // empty' 2>/dev/null || true)

# Skip if no file path or file doesn't exist
if [[ -z "$FILE_PATH" ]] || [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# Never scan the plugin's own icon database (thousands of PUA characters)
DATA_DIR=$(readlink -f "$PLUGIN_ROOT/data" 2>/dev/null || true)
REAL_PATH=$(readlink -f "$FILE_PATH" 2>/dev/null || true)
if [[ -n "$DATA_DIR" && "$REAL_PATH" == "$DATA_DIR/"* ]]; then
    exit 0
fi

# Skip non-text files. Accept text/* and JSON; if file(1) is missing,
# fall back to treating anything without NUL bytes in its first 8 KiB as text.
if command -v file >/dev/null 2>&1; then
    MIME=$(file --brief --mime-type "$FILE_PATH" 2>/dev/null || true)
    case "$MIME" in
        text/*|application/json) ;;
        *) exit 0 ;;
    esac
elif ! head -c 8192 "$FILE_PATH" | tr -d '\000' | cmp -s - <(head -c 8192 "$FILE_PATH"); then
    exit 0
fi

# Run the identification script and capture output
ICON_INFO=$(python3 "$PLUGIN_ROOT/scripts/identify-icons.py" "$FILE_PATH" 2>/dev/null || true)

# If icons were found, output JSON for Claude
if [[ -n "$ICON_INFO" ]]; then
    # JSON for Claude (injected into context)
    # Imperative reminder to load the skill
    CONTEXT="PUA codepoints detected. Ensure icon-lookup skill is loaded.

$ICON_INFO"
    ESCAPED=$(printf '%s\n' "$CONTEXT" | jq -Rs .)
    cat <<JSON
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": $ESCAPED
  }
}
JSON
fi

exit 0
