# allow pushd without explicit command
setopt autopushd
# allow cd without explicit command
setopt autocd
# Disable `no match error for glob patterns that don't match files`
setopt nonomatch
# Disable extended globbing if it causes compatibility issues
setopt extendedglob

# Add completions directory to zsh completions directories
fpath=($ZDOTDIR/completions $fpath)

# Some completions only support bash completions
autoload -U +X bashcompinit && bashcompinit

# zstyles
[[ -r $ZDOTDIR/.zstyles ]] && . "$ZDOTDIR"/.zstyles

# use antidote for plugin management
[[ -d $ANTIDOTE_HOME/mattmc3/antidote ]] ||
  git clone --depth 1 --quiet https://github.com/mattmc3/antidote "$ANTIDOTE_HOME"/mattmc3/antidote

source "$ANTIDOTE_HOME"/mattmc3/antidote/antidote.zsh
antidote load

# check if powerlevel10k configuration exists, if not, run powerlevel10k
[[ -f $ZDOTDIR/.p10k.zsh ]] && source "$ZDOTDIR"/.p10k.zsh || p10k configure

#eval "$(enable-fzf-tab)"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
  source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
fi
