# Sesh session picker keybinding (interactive only)
# Ctrl+Alt+T — follows fzf.fish Alt+Ctrl convention (\e\c prefix)
if status is-interactive && type -q sesh
    for mode in default insert
        bind --mode $mode \e\ct _sesh_search
    end
end
