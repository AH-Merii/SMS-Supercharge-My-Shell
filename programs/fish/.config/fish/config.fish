# Main fish configuration

# Disable default greeting
set -g fish_greeting

# Ghostty integration (if available)
if set -q GHOSTTY_RESOURCES_DIR
    source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
end

# Interactive only: `fish -c` would pay for the spawn on every fzf preview otherwise.
if status is-interactive
    if type -q direnv
        direnv hook fish | source
    end
end
