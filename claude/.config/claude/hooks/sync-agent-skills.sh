#!/bin/bash
# Setup hook: sync agent skills, detect new/stale skills in skill-eval.sh

AGENTS_SKILLS="$HOME/.agents/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"
SKILL_EVAL="$HOME/.config/claude/hooks/skill-eval.sh"

# A) Sync agent skill symlinks
if [ -d "$AGENTS_SKILLS" ]; then
  for skill_dir in "$AGENTS_SKILLS"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    target="$CLAUDE_SKILLS/$skill_name"
    [ -e "$target" ] && continue
    ln -s "$skill_dir" "$target" 2>/dev/null
  done
fi

[ -f "$SKILL_EVAL" ] || exit 0

# B) Detect new skills (in ~/.claude/skills/ but not in skill-eval.sh)
new_skills=()
if [ -d "$CLAUDE_SKILLS" ]; then
  for skill_dir in "$CLAUDE_SKILLS"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    # Must have a SKILL.md to count
    [ -f "$skill_dir/SKILL.md" ] || continue
    if ! grep -q "\"$skill_name\"" "$SKILL_EVAL"; then
      new_skills+=("$skill_name")
    fi
  done
fi

# C) Detect stale skills (in skill-eval.sh but no longer on disk)
stale_skills=()
while IFS= read -r registered; do
  if [ ! -d "$CLAUDE_SKILLS/$registered" ]; then
    stale_skills+=("$registered")
  fi
done < <(sed -n 's/.*suggestions+=("\([^"]*\)").*/\1/p' "$SKILL_EVAL")

# Build context message
messages=()
if [ ${#new_skills[@]} -gt 0 ]; then
  skills_list=$(printf ', %s' "${new_skills[@]}")
  messages+=("New skills not yet in skill-eval.sh: ${skills_list:2}. Read their SKILL.md from ~/.claude/skills/<name>/SKILL.md, propose keyword triggers, and ask the user if they want to add case blocks to skill-eval.sh (source: ~/SMS-Supercharge-My-Shell/claude/.config/claude/hooks/skill-eval.sh). Then re-stow.")
fi
if [ ${#stale_skills[@]} -gt 0 ]; then
  skills_list=$(printf ', %s' "${stale_skills[@]}")
  messages+=("Stale skills in skill-eval.sh whose directories no longer exist: ${skills_list:2}. Ask the user if they want to remove these case blocks from skill-eval.sh (source: ~/SMS-Supercharge-My-Shell/claude/.config/claude/hooks/skill-eval.sh). Then re-stow.")
fi

if [ ${#messages[@]} -gt 0 ]; then
  combined=$(printf '%s ' "${messages[@]}")
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Setup",
    "additionalContext": "$combined"
  }
}
EOF
fi

exit 0
