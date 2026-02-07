#!/bin/bash
# Stop hook: merge auto-approved WebFetch rules into stow-managed settings.json
# Runs async after each session. Deduplicates and cleans up settings.local.json.

set -euo pipefail

LOCAL="$HOME/.claude/settings.local.json"
STOW_SRC="$HOME/SMS-Supercharge-My-Shell/claude/.config/claude/settings.json"
LOCK_DIR="${STOW_SRC}.lock"

# Exit early if no local settings file
[[ -f "$LOCAL" ]] || exit 0

# Require jq
command -v jq >/dev/null 2>&1 || exit 0

# Extract WebFetch rules from settings.local.json
NEW_RULES=$(jq '[.permissions.allow[]? | select(startswith("WebFetch(domain:")) | select(length > 0)]' "$LOCAL" 2>/dev/null)

# Exit if no WebFetch rules to merge
if [ -z "$NEW_RULES" ] || [ "$NEW_RULES" = "[]" ] || [ "$NEW_RULES" = "null" ]; then
  exit 0
fi

# Acquire lock (mkdir is atomic)
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

# Merge: append only genuinely new entries, preserving existing order
jq --argjson new "$NEW_RULES" '.permissions.allow += ($new - .permissions.allow)' "$STOW_SRC" > "${STOW_SRC}.tmp" \
  && mv "${STOW_SRC}.tmp" "$STOW_SRC"

# Remove merged WebFetch rules from settings.local.json
REMAINING=$(jq 'del(.permissions.allow[]? | select(startswith("WebFetch(domain:")))' "$LOCAL" 2>/dev/null)

# If settings.local.json has an empty allow array, remove it
if echo "$REMAINING" | jq -e '.permissions.allow | length == 0' >/dev/null 2>&1; then
  REMAINING=$(echo "$REMAINING" | jq 'del(.permissions.allow) | del(.permissions | select(length == 0))')
fi

# Write back or delete if empty
if echo "$REMAINING" | jq -e '. == {} or . == null' >/dev/null 2>&1; then
  rm -f "$LOCAL"
else
  echo "$REMAINING" | jq . > "$LOCAL"
fi

exit 0
