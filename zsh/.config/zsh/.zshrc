
# allow pushd without explicit command
setopt autopushd
# allow cd without explicit command
setopt autocd

# zstyles
[[ -r $ZDOTDIR/.zstyles ]] && . $ZDOTDIR/.zstyles

# use antidote for plugin management
[[ -d $ANTIDOTE_HOME/mattmc3/antidote ]] ||
  git clone --depth 1 --quiet https://github.com/mattmc3/antidote $ANTIDOTE_HOME/mattmc3/antidote

source $ANTIDOTE_HOME/mattmc3/antidote/antidote.zsh
antidote load

# check if powerlevel10k configuration exists, if not, run powerlevel10k
[[ -f $ZDOTDIR/.p10k.zsh ]] && source $ZDOTDIR/.p10k.zsh || p10k configure

eval "$(enable-fzf-tab)"
eval "$(pyenv init -)"
