export EDITOR=$HOME/.cargo/bin/hx
export SUDOEDITOR=$HOME/.cargo/bin/hx
export VISUAL=$HOME/.cargo/bin/hx
export PATH=$HOME/.local/bin:$PATH
export MANWIDTH=999
export PATH=$HOME/.cargo/bin:$PATH
export PATH=$HOME/.local/share/go/bin:$PATH
export GOPATH=$HOME/.local/share/go
export PATH=$PATH:$GOPATH/bin
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_CACHE_HOME=$HOME/.cache
export ZDOTDIR=$HOME/.config/zsh
export ZSH_ALIAS_DIR=$ZDOTDIR/aliases.zsh
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
