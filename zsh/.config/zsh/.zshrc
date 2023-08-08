# source zap
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

# source helper functions
source $ZDOTDIR/scripts/helper-funcs.sh

# history
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE="$ZDOTDIR/.zsh_history"

# allow pushd without explicit command
setopt autopushd
# allow cd without explicit command
setopt autocd

# source
plug "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/scripts/lfcd.sh"

# plugins
loop-apply plug "$ZDOTDIR/zsh-extensions.txt"

# keybinds
bindkey '^ ' autosuggest-accept
r-delregion() {
  if ((REGION_ACTIVE)) then
     zle kill-region
  else
    local widget_name=$1
    shift
    zle $widget_name -- $@
  fi
}
r-deselect() {
  ((REGION_ACTIVE = 0))
  local widget_name=$1
  shift
  zle $widget_name -- $@
}
r-select() {
  ((REGION_ACTIVE)) || zle set-mark-command
  local widget_name=$1
  shift
  zle $widget_name -- $@
}
for key     kcap   seq        mode   widget (
    sleft   kLFT   $'\e[1;2D' select   backward-char
    sright  kRIT   $'\e[1;2C' select   forward-char
    sup     kri    $'\e[1;2A' select   up-line-or-history
    sdown   kind   $'\e[1;2B' select   down-line-or-history
    send    kEND   $'\E[1;2F' select   end-of-line
    send2   x      $'\E[4;2~' select   end-of-line
    shome   kHOM   $'\E[1;2H' select   beginning-of-line
    shome2  x      $'\E[1;2~' select   beginning-of-line
    left    kcub1  $'\EOD'    deselect backward-char
    right   kcuf1  $'\EOC'    deselect forward-char
    end     kend   $'\EOF'    deselect end-of-line
    end2    x      $'\E4~'    deselect end-of-line
    home    khome  $'\EOH'    deselect beginning-of-line
    home2   x      $'\E1~'    deselect beginning-of-line
    csleft  x      $'\E[1;6D' select   backward-word
    csright x      $'\E[1;6C' select   forward-word
    csend   x      $'\E[1;6F' select   end-of-line
    cshome  x      $'\E[1;6H' select   beginning-of-line
    cleft   x      $'\E[1;5D' deselect backward-word
    cright  x      $'\E[1;5C' deselect forward-word
    del     kdch1   $'\E[3~'  delregion delete-char
    bs      x       $'^?'     delregion backward-delete-char
  ) {
  eval "key-$key() {
    r-$mode $widget \$@
  }"
  zle -N key-$key
  bindkey ${terminfo[$kcap]-$seq} key-$key
}
# Fix zsh-autosuggestions https://stackoverflow.com/a/30899296
export ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(
  key-right
)
# ctrl+x,c,v https://unix.stackexchange.com/a/634916/424080
function zle-clipboard-cut {
  if ((REGION_ACTIVE)); then
    zle copy-region-as-kill
    print -rn -- $CUTBUFFER | clip.exe
    zle kill-region
  fi
}
zle -N zle-clipboard-cut
function zle-clipboard-copy {
  if ((REGION_ACTIVE)); then
    zle copy-region-as-kill
    print -rn -- $CUTBUFFER | clip.exe
  else
    zle send-break
  fi
}
zle -N zle-clipboard-copy
function zle-clipboard-paste {
  if ((REGION_ACTIVE)); then
    zle kill-region
  fi
  LBUFFER+="$(cat clip.exe)"
}
zle -N zle-clipboard-paste
function zle-pre-cmd {
  stty intr "^@"
}
precmd_functions=("zle-pre-cmd" ${precmd_functions[@]})
function zle-pre-exec {
  stty intr "^C"
}
preexec_functions=("zle-pre-exec" ${preexec_functions[@]})
for key     kcap    seq           widget              arg (
    cx      _       $'^X'         zle-clipboard-cut   _
    cc      _       $'^C'         zle-clipboard-copy  _
    cv      _       $'^V'         zle-clipboard-paste _
) {
  if [ "${arg}" = "_" ]; then
    eval "key-$key() {
      zle $widget
    }"
  else
    eval "key-$key() {
      zle-$widget $arg \$@
    }"
  fi
  zle -N key-$key
  bindkey ${terminfo[$kcap]-$seq} key-$key
}
# ctrl+a https://stackoverflow.com/a/68987551/13658418
function widget::select-all() {
  local buflen=$(echo -n "$BUFFER" | wc -m | bc)
  CURSOR=$buflen  
  zle set-mark-command
  while [[ $CURSOR > 0 ]]; do
    zle beginning-of-line
  done
}
zle -N widget::select-all
bindkey '^a' widget::select-all
# ctrl+z
bindkey "^Z" undo

if command -v bat &> /dev/null; then
  alias cat="bat -pp --theme \"Visual Studio Dark+\"" 
  alias catt="bat --theme \"Visual Studio Dark+\"" 
fi

# Configure pyenv and pyenv-virtualenv
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# initialize starship prompt
eval "$(starship init zsh)"
