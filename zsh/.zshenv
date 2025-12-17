# Homebrew initialization (macOS + Linux)
if [[ "$OSTYPE" == darwin* ]]; then
  # macOS: Apple Silicon or Intel
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  # Linux
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# editor
export EDITOR=nvim
export SUDOEDITOR=nvim
export VISUAL=nvim

# Set XDG base dirs.
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share
export XDG_STATE_HOME=~/.local/state
# XDG_RUNTIME_DIR: Linux uses /run/user, macOS uses TMPDIR (already set by system)
[[ "$OSTYPE" != darwin* ]] && export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_PROJECTS_DIR=~/Projects

# Create XDG directories if they don't exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"
mkdir -p "$XDG_DATA_HOME/zsh" "$XDG_CACHE_HOME/repos"

# binaries
export PATH=$HOME/.local/bin:$PATH
export PATH=$XDG_DATA_HOME/go/bin:$PATH
export PATH=$XDG_DATA_HOME/nvim/mason/bin:$PATH

# Set zsh config directory
export ZDOTDIR=$XDG_CONFIG_HOME/zsh

# Store zsh history
export HISTFILE=$XDG_DATA_HOME/zsh/zsh_history

# XDG DATA
export PYENV_ROOT="$XDG_DATA_HOME"/pyenv
export CLAUDE_CONFIG_DIR="$XDG_CONFIG_HOME"/claude

# XDG CACHE
export TEXMFVAR="$XDG_CACHE_HOME"/texlive/texmf-var

# Custom
export GNUPGHOME=$XDG_DATA_HOME/gnupg
export REPO_HOME=$XDG_CACHE_HOME/repos
export ANTIDOTE_HOME=$REPO_HOME

# Do the initialization when the script is sourced (i.e. Initialize instantly) (zsh-vi-mode plugin)
export ZVM_INIT_MODE=sourcing

# mattmc3/zephyr/zfunctions plugin
export ZFUNCDIR=${ZDOTDIR:-$HOME/.config/zsh}/functions

# AWS CLI Autocompletions
export AWS_CLI_AUTO_PROMPT="on-partial"

# fzf configuration
export FZF_CTRL_T_COMMAND="fd --hidden --follow --type f --exclude '.git'"
export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always --style=numbers {}'
  --bind 'page-up:preview-up,page-down:preview-down'
  --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# Detect clipboard command for cross-platform compatibility
if command -v pbcopy >/dev/null 2>&1; then
  _clip_cmd="pbcopy"
elif command -v wl-copy >/dev/null 2>&1; then
  _clip_cmd="wl-copy"
elif command -v xclip >/dev/null 2>&1; then
  _clip_cmd="xclip -selection clipboard"
else
  _clip_cmd="cat"  # fallback: just print to stdout
fi

# CTRL-/ to toggle small preview window to see the full command
# CTRL-Y to copy the command into clipboard
export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | $_clip_cmd)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

export MANPAGER='nvim +Man!'
