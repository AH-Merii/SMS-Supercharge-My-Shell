
# allow pushd without explicit command
setopt autopushd
# allow cd without explicit command
setopt autocd

autoload -U compinit 
compinit

# use antidote for plugin management
[[ -d $ANTIDOTE_HOME/mattmc3/antidote ]] ||
  git clone --depth 1 --quiet https://github.com/mattmc3/antidote $ANTIDOTE_HOME/mattmc3/antidote

source $ANTIDOTE_HOME/mattmc3/antidote/antidote.zsh
antidote load

# https://github.com/doron-cohen/antidot
# Use antidot to export new xdg locations for cleaned programs
eval "$(antidot init)"

zstyle ':completion:*' menu select

# history substring search options
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
