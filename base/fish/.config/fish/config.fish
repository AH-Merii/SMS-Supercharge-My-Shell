# Main fish configuration

# Disable default greeting
set -g fish_greeting

# Ghostty integration (if available). Ghostty auto-loads this through
# XDG_DATA_DIRS in the shell it starts, but the script removes its own dir from
# XDG_DATA_DIRS again, so shells started underneath (tmux, a nested fish) only
# get it from here. Sourcing it twice is harmless; it does its setup once, on
# the first prompt.
if set -q GHOSTTY_RESOURCES_DIR
    source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
end

# Enable Starship prompt
if type -q starship
    starship init fish | source
end
if type -q direnv
    direnv hook fish | source
end
