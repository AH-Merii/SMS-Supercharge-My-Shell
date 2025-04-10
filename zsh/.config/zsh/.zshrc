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
[[ -r $ZDOTDIR/.zstyles ]] && . $ZDOTDIR/.zstyles

# use antidote for plugin management
[[ -d $ANTIDOTE_HOME/mattmc3/antidote ]] ||
  git clone --depth 1 --quiet https://github.com/mattmc3/antidote $ANTIDOTE_HOME/mattmc3/antidote

source $ANTIDOTE_HOME/mattmc3/antidote/antidote.zsh
antidote load

# load AWS CLI completions only if they are available
command -v aws_completer &>/dev/null && complete -o nospace -C "$(command -v aws_completer)" aws

# check if powerlevel10k configuration exists, if not, run powerlevel10k
[[ -f $ZDOTDIR/.p10k.zsh ]] && source $ZDOTDIR/.p10k.zsh || p10k configure

eval "$(enable-fzf-tab)"
command -v pyenv > /dev/null && eval "$(pyenv init -)"
command -v zoxide > /dev/null && eval "$(zoxide init zsh)"
command -v antidot > /dev/null && eval "$(antidot init)" && antidot clean

# Automatically starts Hyprland on boot if running directly from tty1 (first virtual console),
# not in an X11 environment, Hyprland is installed, and Hyprland is not already running.
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ] && command -v Hyprland > /dev/null && ! pgrep -x Hyprland > /dev/null; then
  Hyprland
fi
