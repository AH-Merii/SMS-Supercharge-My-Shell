#!/bin/bash
# UserPromptSubmit hook: evaluate prompt against available skills
# Returns additionalContext suggesting which skills to activate

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // empty')

if [ -z "$PROMPT" ]; then
  exit 0
fi

PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

suggestions=()

# Check each skill's activation keywords
case "$PROMPT_LOWER" in
  *stow*|*dotfile*|*"shell config"*|*symlink*)
    suggestions+=("stow-config") ;;
esac

case "$PROMPT_LOWER" in
  *"github action"*|*ci*|*workflow*|*release*|*"ci/cd"*)
    suggestions+=("ci-workflow") ;;
esac

case "$PROMPT_LOWER" in
  *fish*|*"fish shell"*|*"fish function"*|*conf.d*)
    suggestions+=("fish-shell") ;;
esac

case "$PROMPT_LOWER" in
  *commit*|*"pull request"*|*pr*|*"git workflow"*|*"conventional commit"*)
    suggestions+=("git-workflow") ;;
esac

case "$PROMPT_LOWER" in
  *bug*|*error*|*fail*|*debug*|*diagnos*|*investigat*|*"stack trace"*|*crash*)
    suggestions+=("debugging") ;;
esac

case "$PROMPT_LOWER" in
  *sandbox*|*"allowed domain"*|*"alloweddomain"*|*permission*|*"settings.json"*|*"claude config"*|*"claude code config"*|*"claude code setup"*|*"claude code setting"*|*hook*)
    suggestions+=("claude-config-research") ;;
esac

case "$PROMPT_LOWER" in
  *"find skill"*|*"find a skill"*|*"is there a skill"*|*"search skill"*|*"install skill"*|*"skill for"*|*"extend capabilit"*|*"bunx skills"*)
    suggestions+=("find-skills") ;;
esac

case "$PROMPT_LOWER" in
  *btca*|*"better context"*|*"source-first"*|*"ask resource"*|*"btca ask"*)
    suggestions+=("btca-cli") ;;
esac

if [ ${#suggestions[@]} -gt 0 ]; then
  skills_list=$(printf ', %s' "${suggestions[@]}")
  skills_list="${skills_list:2}"  # Remove leading ", "
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "Relevant skills detected: ${skills_list}. Check if these skills should be activated before proceeding."
  }
}
EOF
fi

exit 0
