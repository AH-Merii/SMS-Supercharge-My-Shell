#!/bin/sh
[ -f "$XDG_DATA_HOME/zap/zap.zsh" ] && source "$XDG_DATA_HOME/zap/zap.zsh"


# history
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE="$ZDOTDIR/.zsh_history"

# allow pushd without explicit command
setopt autopushd

# source
plug "$ZDOTDIR/aliases.zsh"
plug "$ZDOTDIR/scripts/helper-funcs.sh"

# plugins
loop_apply plug "programs/zsh-extensions.txt"

# keybinds
bindkey '^ ' autosuggest-accept

if command -v bat &> /dev/null; then
  alias cat="bat -pp --theme \"Visual Studio Dark+\"" 
  alias catt="bat --theme \"Visual Studio Dark+\"" 
fi
