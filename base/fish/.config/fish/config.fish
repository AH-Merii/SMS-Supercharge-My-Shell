# Main fish configuration

# Disable default greeting
set -g fish_greeting

# Ghostty integration (if available)
if set -q GHOSTTY_RESOURCES_DIR
    source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
end

# Prompt and directory hooks are for interactive sessions only. Each `init | source`
# spawns a process, and `fish -c` pays for all of them otherwise: fzf runs every preview
# through one, on every cursor move.
if status is-interactive
    if type -q starship
        starship init fish | source
    end
    if type -q direnv
        direnv hook fish | source
    end
end
