# Vi mode + keybindings (interactive only)
if status is-interactive
    function fish_user_key_bindings
        # In default (normal) mode: p/P paste from system clipboard
        bind -M default p fish_clipboard_paste
        bind -M default P 'commandline -C 0; fish_clipboard_paste'

        # In insert mode: Ctrl+V pastes (so 'p' still types normally)
        bind -M insert \cv fish_clipboard_paste

        # Ctrl+Backspace kills the previous word, like every GUI text field.
        # Ghostty rewrites Ctrl+Backspace to Alt+Backspace (see its config), so
        # bind that rather than ctrl-backspace: fish folds ctrl-backspace onto
        # ctrl-h, which the autopair plugin already owns in insert mode.
        bind -M default alt-backspace backward-kill-word
        bind -M insert alt-backspace backward-kill-word
    end

    # As per fish version 4.3
    set --global fish_key_bindings fish_vi_key_bindings
end
