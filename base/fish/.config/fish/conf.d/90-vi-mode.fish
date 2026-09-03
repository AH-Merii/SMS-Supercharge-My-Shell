# Vi mode + keybindings (interactive only)
if status is-interactive
    function fish_user_key_bindings
        # In default (normal) mode: p/P paste from system clipboard
        bind -M default p fish_clipboard_paste
        bind -M default P 'commandline -C 0; fish_clipboard_paste'

        # In insert mode: Ctrl+V pastes (so 'p' still types normally)
        bind -M insert \cv fish_clipboard_paste
    end

    # As per fish version 4.3
    set --global fish_key_bindings fish_vi_key_bindings
end
