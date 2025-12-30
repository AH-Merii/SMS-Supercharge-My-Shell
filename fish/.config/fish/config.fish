# Main fish configuration

# Bootstrap Fisher plugin manager (like antidote for zsh)
if not functions -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher update
end

# Vi mode with system clipboard rebinding
fish_vi_key_bindings

function fish_user_key_bindings
    # Rebind p/P to always use system clipboard (like zsh-vi-mode config)
    bind -M default p fish_clipboard_paste
    bind -M default P 'commandline -C 0; fish_clipboard_paste'
end

# Disable default greeting, show fastfetch instead
set -g fish_greeting
if status is-interactive
    fastfetch
end

# Ghostty integration (if available)
if set -q GHOSTTY_RESOURCES_DIR
    source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
end
