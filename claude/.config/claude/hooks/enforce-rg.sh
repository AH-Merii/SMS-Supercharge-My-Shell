#!/bin/bash

# PreToolUse hook: enforce built-in Grep tool / rg over raw grep commands
# Blocks raw grep/egrep/fgrep invocations, suggests the built-in Grep tool or rg.
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

  # Allow informational lookups where grep is just an argument
  case "$first_word" in
    which|type) continue ;;
  esac

  # Handle "command -v grep" specifically
  if [[ "$trimmed" =~ ^command[[:space:]]+-v[[:space:]] ]]; then
    continue
  fi

  # Check for raw grep/egrep/fgrep as the command
  case "$first_word" in
    grep|egrep|fgrep)
      deny=true
      break
      ;;
    rg)
      # Already using rg — allow
      continue
      ;;
  esac
done <<< "$(echo "$COMMAND" | sed 's/&&/\n/g; s/||/\n/g; s/|/\n/g; s/;/\n/g')"

if [ "$deny" = true ]; then
  if command -v rg &>/dev/null; then
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Use the built-in Grep tool instead of raw 'grep'. If you need bash-level search, use 'rg' (ripgrep)."
  }
}
EOF
  else
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Use the built-in Grep tool instead of raw 'grep'. For bash-level search, install ripgrep: 'brew install ripgrep', then use 'rg'."
  }
}
EOF
  fi
  exit 0
fi

# Soft nudge when rg is used directly (allowed but suboptimal)
uses_rg=false
while IFS= read -r subcmd; do
  trimmed="${subcmd#"${subcmd%%[![:space:]]*}"}"
  [ -z "$trimmed" ] && continue
  first_word="${trimmed%% *}"
  if [ "$first_word" = "rg" ]; then
    uses_rg=true
    break
  fi
done <<< "$(echo "$COMMAND" | sed 's/&&/\n/g; s/||/\n/g; s/|/\n/g; s/;/\n/g')"

if [ "$uses_rg" = true ]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "Note: Prefer the built-in Grep tool for searches. rg is allowed but uses context less efficiently than the Grep tool."
  }
}
EOF
  exit 0
fi

exit 0
