eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
# editor
export EDITOR=nvim
export SUDOEDITOR=nvim
export VISUAL=nvim

# binaries
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.local/share/go/bin:$PATH

export PATH=$HOMEBREW_PREFIX/.local/bin:$PATH
export PATH=$HOMEBREW_PREFIX/.local/share/:$PATH

# Set XDG base dirs.
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share
export XDG_STATE_HOME=~/.local/state
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_PROJECTS_DIR=~/Projects

# Set zsh config directory
export ZDOTDIR=$HOME/.config/zsh

# Store zsh history
export HISTFILE=$XDG_DATA_HOME/zsh/zsh_history

# XDG DATA
export PYENV_ROOT="$XDG_DATA_HOME"/pyenv 

# XDG CACHE
export TEXMFVAR="$XDG_CACHE_HOME"/texlive/texmf-var

# Define powerlevel10k theme
export ZSH_THEME="powerlevel10k/powerlevel10k"

# Custom
export GNUPGHOME=$XDG_DATA_HOME/gnupg
export REPO_HOME=$XDG_CACHE_HOME/repos
export ANTIDOTE_HOME=$REPO_HOME

# Do the initialization when the script is sourced (i.e. Initialize instantly) (zsh-vi-mode plugin)
ZVM_INIT_MODE=sourcing

# mattmc3/zephyr/zfunctions plugin
ZFUNCDIR=${ZDOTDIR:-$HOME/.config/zsh}/functions

# AWS CLI Autocompletions
export AWS_CLI_AUTO_PROMPT="on-partial"

# fzf configuration
export FZF_CTRL_T_COMMAND="fd --hidden --follow --type f --exclude '.git'"
export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always --style=numbers {}'
  --bind 'page-up:preview-up,page-down:preview-down'
  --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
# CTRL-/ to toggle small preview window to see the full command
# CTRL-Y to copy the command into clipboard using pbcopy
export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"
