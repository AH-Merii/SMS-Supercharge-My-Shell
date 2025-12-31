# Main fish configuration

# Disable default greeting, show fastfetch instead
set -g fish_greeting

# Ghostty integration (if available)
if set -q GHOSTTY_RESOURCES_DIR
    source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
end

# Enable Starship prompt
starship init fish | source
