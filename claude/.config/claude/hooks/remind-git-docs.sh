#!/bin/bash
# Stop hook: soft one-shot reminder to sync git docs
# Checks if git config files were edited (tracked by PostToolUse hook).
# Blocks ONCE with a gentle reminder, then clears the flag.

DIRTY_FLAG="/tmp/claude-git-docs-dirty"

if [ ! -f "$DIRTY_FLAG" ]; then
  exit 0
fi

# Read which files were edited, then clear the flag immediately
EDITED_FILES=$(sort -u "$DIRTY_FLAG")
rm -f "$DIRTY_FLAG"

cat <<EOF
{
  "decision": "block",
  "reason": "Git config files were edited during this session:\n${EDITED_FILES}\n\nConsider updating the docs to stay in sync:\n- CONFIG.md (git/.config/git/CONFIG.md): settings tables\n- README.md (git/.config/git/README.md): alias table, Post-Clone Setup, Utilities\n\nIf no doc changes are needed, just finish up."
}
EOF
