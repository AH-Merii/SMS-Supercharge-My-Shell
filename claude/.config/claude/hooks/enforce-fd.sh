#!/bin/bash

# PreToolUse hook: enforce Glob tool or fd instead of raw find
# Blocks raw find invocations, suggests the built-in Glob tool or fd instead.
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

  # Allow informational lookups where find is just an argument
  case "$first_word" in
    which|type) continue ;;
  esac

  # Handle "command -v find" specifically
  if [[ "$trimmed" =~ ^command[[:space:]]+-v[[:space:]] ]]; then
    continue
  fi

  # Check for raw find as the command
  case "$first_word" in
    find)
      deny=true
      break
      ;;
    fd)
      # Already using fd — allow
      continue
      ;;
  esac
done <<< "$(echo "$COMMAND" | sed 's/&&/\n/g; s/||/\n/g; s/|/\n/g; s/;/\n/g')"

if [ "$deny" = true ]; then
  if command -v fd &>/dev/null; then
    reason="Use the built-in Glob tool instead of raw 'find'. If you need bash-level file finding, use 'fd'."
  else
    reason="Use the built-in Glob tool instead of raw 'find'. For bash-level file finding, install fd: 'brew install fd', then use 'fd'."
  fi
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "$reason"
  }
}
EOF
  exit 0
fi

# Soft nudge when fd is used directly (allowed but suboptimal)
uses_fd=false
while IFS= read -r subcmd; do
  trimmed="${subcmd#"${subcmd%%[![:space:]]*}"}"
  [ -z "$trimmed" ] && continue
  first_word="${trimmed%% *}"
  if [ "$first_word" = "fd" ]; then
    uses_fd=true
    break
  fi
done <<< "$(echo "$COMMAND" | sed 's/&&/\n/g; s/||/\n/g; s/|/\n/g; s/;/\n/g')"

if [ "$uses_fd" = true ]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "Note: Prefer the built-in Glob tool for file searches. fd is allowed but uses context less efficiently than the Glob tool."
  }
}
EOF
  exit 0
fi

exit 0
