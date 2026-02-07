#!/bin/bash
# UserPromptSubmit hook: evaluate prompt against available skills
# Returns additionalContext suggesting which skills to activate

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

if [ -z "$PROMPT" ]; then
  exit 0
fi

PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

suggestions=()

# Check each skill's activation keywords
case "$PROMPT_LOWER" in
  *stow*|*dotfile*|*"shell config"*|*"stow package"*|*"stow source"*|*restow*)
    suggestions+=("stow-config") ;;
esac

case "$PROMPT_LOWER" in
  *"github action"*|*"gh action"*|*"gh actions"*|*"ci/cd"*|*"ci pipeline"*|*"ci workflow"*|*"github workflow"*|*".github/workflows"*|*"release automation"*)
    suggestions+=("ci-workflow") ;;
esac

case "$PROMPT_LOWER" in
  *"fish shell"*|*"fish function"*|*"fish config"*|*"fish plugin"*|*"fish script"*|*".fish"*|*fishfile*)
    suggestions+=("fish-shell") ;;
esac

case "$PROMPT_LOWER" in
  *commit*|*"pull request"*|*"git workflow"*|*"conventional commit"*|*"open pr"*|*"create pr"*|*"review pr"*|*"pr review"*)
    suggestions+=("git-workflow") ;;
esac

case "$PROMPT_LOWER" in
  *bug*|*error*|*fail*|*debug*|*diagnos*|*investigat*|*"stack trace"*|*crash*)
    suggestions+=("debugging") ;;
esac

case "$PROMPT_LOWER" in
  *sandbox*|*"allowed domain"*|*permission*|*"settings.json"*|*"claude config"*|*"claude code config"*|*"claude code setup"*|*"claude code setting"*|*hook*|*agent*|*"best practice"*|*"research claude"*|*"claude doc"*|*"claude.md"*|*mcp*)
    suggestions+=("claude-config-research") ;;
esac

case "$PROMPT_LOWER" in
  *"hook script"*|*"write hook"*|*"create hook"*|*"debug hook"*|*"audit hook"*|*"pretooluse"*|*"posttooluse"*|*"hook development"*|*"optimize hook"*|*"fix hook"*|*"hook fail"*|*"hook template"*|*"new hook"*)
    suggestions+=("hook-development") ;;
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
