#!/bin/bash

# PreToolUse hook: enforce uv for Python/pip commands
# Blocks raw python/pip invocations, suggests uv run / uv pip / uvx instead.
# Returns structured JSON with permissionDecision: "deny" when blocking.

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Split command on shell operators into sub-commands, then check each one.
# We use sed to put each sub-command on its own line.
deny=false

while IFS= read -r subcmd; do
  # Trim leading whitespace
  trimmed="${subcmd#"${subcmd%%[![:space:]]*}"}"

  # Skip empty lines
  [ -z "$trimmed" ] && continue

  # Extract the first word (the command)
  first_word="${trimmed%% *}"

  # Allow informational lookups where python is just an argument
  case "$first_word" in
    which|type) continue ;;
  esac

  # Handle "command -v python" specifically
  if [[ "$trimmed" =~ ^command[[:space:]]+-v[[:space:]] ]]; then
    continue
  fi

  # Check for raw python/python3/pip/pip3 as the command
  case "$first_word" in
    python|python3|pip|pip3)
      # Check if this sub-command is preceded by "uv run" or "uv pip" or "uvx"
      # by looking at the original command for "uv run python", "uv pip ...", etc.
      # We check the trimmed sub-command for "uv " prefix (it won't have it since
      # we split on operators, so uv and python would be in the same sub-command)
      # Actually after splitting, "uv run python ..." stays together as one sub-command.
      # So if first_word is python/pip, it truly is a raw invocation.
      deny=true
      break
      ;;
    uv|uvx)
      # Already using uv/uvx — allow
      continue
      ;;
  esac
done <<< "$(echo "$COMMAND" | sed 's/&&/\n/g; s/||/\n/g; s/|/\n/g; s/;/\n/g')"

if [ "$deny" = true ]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Use 'uv run python ...' instead of raw 'python'. Use 'uv pip ...' instead of raw 'pip'. This ensures proper environment and dependency management."
  }
}
EOF
  exit 0
fi

# Soft nudge when uv/uvx is used directly for python (allowed, just a reminder)
uses_uv=false
while IFS= read -r subcmd; do
  trimmed="${subcmd#"${subcmd%%[![:space:]]*}"}"
  [ -z "$trimmed" ] && continue
  first_word="${trimmed%% *}"
  if [ "$first_word" = "uv" ] || [ "$first_word" = "uvx" ]; then
    uses_uv=true
    break
  fi
done <<< "$(echo "$COMMAND" | sed 's/&&/\n/g; s/||/\n/g; s/|/\n/g; s/;/\n/g')"

if [ "$uses_uv" = true ]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "uv/uvx detected -- good. Remember: use 'uv run python' for scripts, 'uv pip' for package management, 'uvx' for one-off tool execution."
  }
}
EOF
  exit 0
fi

exit 0
