#!/usr/bin/env zsh

alias_check() {
  # Extract only the first word of $2 (the actual command)
  cmd=$2
  cmd=${cmd%% *}

  # Check if the command exists
  if command -v "$cmd" >/dev/null 2>&1; then
    # Define alias safely (quote the right-hand side)
    alias "$1=$2"
  else
    echo "$cmd does not exist"
  fi
}

# modern shell replacements
alias_check cat  bat
alias_check diff delta
alias_check grep rg

# eza (modern ls replacement)
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons=always --group-directories-first"
  alias ll="eza --icons=always --group-directories-first -l --git"
  alias la="eza --icons=always --group-directories-first -la --git"
  alias tree="eza --icons=always --tree"
fi

# shortcuts
alias_check b popd

# zsh easy access
alias_check szrc  "source $ZDOTDIR/.zshrc"
alias_check ezrc  "nvim $ZDOTDIR/.zshrc"
alias_check czrc  "cat $ZDOTDIR/.zshrc"

alias_check szenv "source $HOME/.zshenv"
alias_check ezenv "nvim $HOME/.zshenv"
alias_check czenv "cat $HOME/.zshenv"

# open all relevant supercharge-my-shell files
alias_check esms  "nvim $HOME/.zshenv $ZDOTDIR/{.zshrc,.zsh_plugins.txt,conf.d/aliases.zsh}"

# lazygit
alias_check lg lazygit

# fzf (preview helpers)
alias_check xp  "fzf --exact --preview='bat --color=always --style=numbers {}' --bind page-up:preview-up,ctrl-u:preview-page-up,page-down:preview-down,ctrl-d:preview-page-down"
alias_check fp  "fzf --preview='bat --color=always --style=numbers {}' --bind page-up:preview-up,ctrl-u:preview-page-up,page-down:preview-down,ctrl-d:preview-page-down"

# hidden file search + preview
if command -v fzf >/dev/null 2>&1; then
  alias xph="fd --hidden --exclude '.git' | xp"   # exact preview hidden
  alias fph="fd --hidden --exclude '.git' | fp"   # file preview hidden
fi

# pandoc with typst pdf engine
alias pandoc="pandoc --pdf-engine=typst"

