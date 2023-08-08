#!bin/sh

alias_check() {
  # in case a command with parameters is given as the command
  command=$(echo $2 | sed -E 's/^([[:alnum:]_-]+?)(.*)/\1/')
  # TODO: handle commands with && || or | by trimming and looping over them 
  which $command >/dev/null && alias $1="$2" || echo "$command does not exist"
}

# modern shell replacement
alias_check ls   exa   
alias_check cat  bat   
alias_check find fd    
alias_check diff delta 
alias_check curl xh    
alias_check dig  dog   
alias_check ps   procs 
alias_check ping gping 
alias_check top  btm
alias_check du   dust  
alias_check df   duf   
alias_check grep rg

#shortcuts
alias_check b    popd

# lazygit
alias_check lg   lazygit

# lf
alias_check lf   lf-ueberzug
alias_check lfh  "lf --command 'set hidden!'"

# fzf
# adds preview file to fzf
alias_check xp "fzf --exact --preview='bat --color=always --style=numbers {}' --bind page-up:preview-up,ctrl-u:preview-page-up,page-down:preview-down,ctrl-d:preview-page-down"
alias_check fp "fzf --preview='bat --color=always --style=numbers {}' --bind page-up:preview-up,ctrl-u:preview-page-up,page-down:preview-down,ctrl-d:preview-page-down"
which fzf >/dev/null && alias xph="fd --hidden --exclude '.git' | xp" # exact preview hidden
which fzf >/dev/null && alias fph="fd --hidden --exclude '.git' | fp" # file preview hidden
