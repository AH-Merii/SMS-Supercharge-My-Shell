# Vi mode + keybindings (interactive only)
if status is-interactive
    function fish_user_key_bindings
        # In default (normal) mode: p/P paste from system clipboard
        bind -M default p fish_clipboard_paste
        bind -M default P 'commandline -C 0; fish_clipboard_paste'

        # In insert mode: Ctrl+V pastes (so 'p' still types normally)
        bind -M insert \cv fish_clipboard_paste

        # Ctrl+Backspace / Ctrl+Delete kill a word, like every GUI text field.
        # Ghostty rewrites Ctrl+Backspace to Alt+Backspace (see its config), so
        # bind that rather than ctrl-backspace: fish folds ctrl-backspace onto
        # ctrl-h, which the autopair plugin already owns in insert mode.
        # Ctrl+Delete needs no rewrite -- Delete is a CSI key, so it arrives as
        # CSI 3;5~ on its own; fish just ships no default binding for it.
        for mode in default insert
            bind -M $mode alt-backspace backward-kill-word
            bind -M $mode ctrl-delete kill-word
        end
    end

    # As per fish version 4.3
    set --global fish_key_bindings fish_vi_key_bindings
end
