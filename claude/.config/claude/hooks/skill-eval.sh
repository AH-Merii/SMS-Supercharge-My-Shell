#!/bin/bash
# UserPromptSubmit hook: evaluate prompt against available skills
# Returns additionalContext suggesting which skills to activate

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$PROMPT" ]; then
  exit 0
fi

PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Some skills only make sense while you're actually editing Claude Code config
# (the dotfiles repo, or the live config/symlink dirs). Gate them so generic
# words like "agent"/"hook"/"permission"/"mcp" don't suggest them everywhere.
in_claude_config_dir() {
  case "$CWD" in
    "$HOME/SMS-Supercharge-My-Shell"*|"$HOME/.config/claude"*|"$HOME/.claude"*) return 0 ;;
    *) return 1 ;;
  esac
}

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

# Config-only skills: suggested solely when working inside a Claude-config dir.
if in_claude_config_dir; then
  case "$PROMPT_LOWER" in
    *sandbox*|*"allowed domain"*|*permission*|*"settings.json"*|*"claude config"*|*"claude code config"*|*"claude code setup"*|*"claude code setting"*|*hook*|*agent*|*"best practice"*|*"research claude"*|*"claude doc"*|*"claude.md"*|*mcp*)
      suggestions+=("claude-config-research") ;;
  esac

  case "$PROMPT_LOWER" in
    *"hook script"*|*"write hook"*|*"create hook"*|*"debug hook"*|*"audit hook"*|*"pretooluse"*|*"posttooluse"*|*"hook development"*|*"optimize hook"*|*"fix hook"*|*"hook fail"*|*"hook template"*|*"new hook"*)
      suggestions+=("hook-development") ;;
  esac
fi

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
