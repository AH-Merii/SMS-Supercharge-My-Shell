#!bin/sh

alias_check() {
  # in case a command with parameters is given as the command
  command=$(echo $2 | sed -E 's/^([[:alnum:]_-]+?)(.*)/\1/')
  # TODO: handle commands with && || or | by trimming and looping over them 
  which $command >/dev/null && alias $1="$2" || echo "$command does not exist"
}

# modern shell replacement
alias_check cat  bat   
alias_check diff delta 
alias_check grep rg

# shortcuts
alias_check b  popd
alias_check hx helix
alias_check conda micromamba

# zsh easy access
alias_check szrc "source $ZDOTDIR/.zshrc"
alias_check ezrc "helix $ZDOTDIR/.zshrc"
alias_check czrc "cat $ZDOTDIR/.zshrc"
alias_check szenv "source $HOME/.zshenv"
alias_check ezenv "helix $HOME/.zshenv"
alias_check czenv "cat $HOME/.zshenv"

# open all relevent supercharge-my-shell files
alias_check esms "helix $HOME/.zshenv $ZDOTDIR/{.zshrc,.zsh_plugins.txt,conf.d/aliases.zsh}"

# lazygit
alias_check lg lazygit

# bottom
alias_check btm "btm --enable_gpu_memory"

# fzf
# adds preview file to fzf
alias_check xp "fzf --exact --preview='bat --color=always --style=numbers {}' --bind page-up:preview-up,ctrl-u:preview-page-up,page-down:preview-down,ctrl-d:preview-page-down"
alias_check fp "fzf --preview='bat --color=always --style=numbers {}' --bind page-up:preview-up,ctrl-u:preview-page-up,page-down:preview-down,ctrl-d:preview-page-down"
which fzf >/dev/null && alias xph="fd --hidden --exclude '.git' | xp" # exact preview hidden
which fzf >/dev/null && alias fph="fd --hidden --exclude '.git' | fp" # file preview hidden
