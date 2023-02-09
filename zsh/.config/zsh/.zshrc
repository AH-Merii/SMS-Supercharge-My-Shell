[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"
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

# plugins
loop-apply plug "$ZDOTDIR/zsh-extensions.txt"

# keybinds
bindkey '^ ' autosuggest-accept

if command -v bat &> /dev/null; then
  alias cat="bat -pp --theme \"Visual Studio Dark+\"" 
  alias catt="bat --theme \"Visual Studio Dark+\"" 
fi

# initialize starship prompt
eval "$(starship init zsh)"
