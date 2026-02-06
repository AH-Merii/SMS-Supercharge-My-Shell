#!/bin/bash
# Stop hook: merge auto-approved WebFetch rules into stow-managed settings.json
# Runs async after each session. Deduplicates and cleans up settings.local.json.

set -euo pipefail

LOCAL="$HOME/.claude/settings.local.json"
STOW_SRC="$HOME/SMS-Supercharge-My-Shell/claude/.config/claude/settings.json"

# Exit early if no local settings file
[[ -f "$LOCAL" ]] || exit 0

# Require jq
command -v jq >/dev/null 2>&1 || exit 0

# Extract WebFetch rules from settings.local.json
LOCAL_WEBFETCH=$(jq -r '.permissions.allow[]? // empty | select(startswith("WebFetch(domain:"))' "$LOCAL" 2>/dev/null)

# Exit if no WebFetch rules to merge
[[ -z "$LOCAL_WEBFETCH" ]] && exit 0

# Read existing allow rules from stow source
EXISTING=$(jq -r '.permissions.allow[]' "$STOW_SRC" 2>/dev/null)

# Build merged + deduplicated list
MERGED=$(printf '%s\n%s' "$EXISTING" "$LOCAL_WEBFETCH" | sort -u)

# Convert back to JSON array and update stow source
MERGED_JSON=$(echo "$MERGED" | jq -R . | jq -s .)
jq --argjson new_allow "$MERGED_JSON" '.permissions.allow = $new_allow' "$STOW_SRC" > "${STOW_SRC}.tmp" \
  && mv "${STOW_SRC}.tmp" "$STOW_SRC"

# Remove merged WebFetch rules from settings.local.json
REMAINING=$(jq 'del(.permissions.allow[] | select(startswith("WebFetch(domain:")))' "$LOCAL" 2>/dev/null)

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
