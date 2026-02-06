#!/bin/bash

# PreToolUse hook: enforce stow conventions for SMS-Supercharge-My-Shell
# Only activates when the command references SMS-Supercharge-My-Shell.
# Denies -t/--target and -v/--verbose flags (stow should be run from the SMS repo root
# where .stowrc handles targeting; verbose is unnecessary noise).
# Provides principle-based guidance on --no-folding and --adopt when stow is detected.

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only enforce rules when the command is SMS-related
if ! echo "$COMMAND" | grep -qi 'SMS-Supercharge-My-Shell\|SMS'; then
  exit 0
fi

# Split command on shell operators into sub-commands, then check each one.
deny=false
deny_reason=""
uses_stow=false

while IFS= read -r subcmd; do
  # Trim leading whitespace
  trimmed="${subcmd#"${subcmd%%[![:space:]]*}"}"

  # Skip empty lines
  [ -z "$trimmed" ] && continue

  # Extract the first word (the command)
  first_word="${trimmed%% *}"

  case "$first_word" in
    stow)
      uses_stow=true

      # Check for -t/--target flags
      if echo "$trimmed" | grep -qE '(^|[[:space:]])-t([[:space:]]|$)|(^|[[:space:]])--target([[:space:]=]|$)'; then
        deny=true
        deny_reason="Don't use -t/--target or -v/--verbose flags. Run stow from ~/SMS-Supercharge-My-Shell: cd ~/SMS-Supercharge-My-Shell && stow <package>."
        break
      fi

      # Check for -v/--verbose flags
      if echo "$trimmed" | grep -qE '(^|[[:space:]])-v([[:space:]]|$)|(^|[[:space:]])--verbose([[:space:]]|$)'; then
        deny=true
        deny_reason="Don't use -t/--target or -v/--verbose flags. Run stow from ~/SMS-Supercharge-My-Shell: cd ~/SMS-Supercharge-My-Shell && stow <package>."
        break
      fi

      # Check for combined short flags containing t or v (e.g. -vt, -Svt)
      if echo "$trimmed" | grep -qE '(^|[[:space:]])-[a-zA-Z]*[tv][a-zA-Z]*([[:space:]]|$)'; then
        deny=true
        deny_reason="Don't use -t/--target or -v/--verbose flags. Run stow from ~/SMS-Supercharge-My-Shell: cd ~/SMS-Supercharge-My-Shell && stow <package>."
        break
      fi
      ;;
  esac
done <<< "$(echo "$COMMAND" | sed 's/&&/\n/g; s/||/\n/g; s/|/\n/g; s/;/\n/g')"

if [ "$deny" = true ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "$deny_reason"
  }
}
EOF
  exit 0
fi

if [ "$uses_stow" = true ]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "Stow conventions: Use --no-folding when the target directory contains files NOT managed by stow (e.g. history files, caches, plugin state). Examples: zsh (.zsh_history), fish (fish_variables, completions cache), tmux (plugin dirs, resurrect data). Folding is safe when stow owns the entire target directory (e.g. claude, git). DANGER: --adopt overwrites SOURCE files in the SMS repo with whatever exists at the target -- always confirm with the user first."
  }
}
EOF
  exit 0
fi

exit 0
