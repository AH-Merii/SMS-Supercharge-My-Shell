# Sesh session picker keybinding (interactive only)
# Ctrl+Alt+T — follows fzf.fish Alt+Ctrl convention
if status is-interactive && type -q sesh
    keys_bind ctrl-alt-t _sesh_search 'Launch sesh session manager' \
        'Pick a tmux session, a sesh config or a zoxide directory and connect to' \
        'it. sesh creates the session first if it does not exist yet.' \
        '' \
        'Inside the picker:' \
        '  `ctrl-a`  everything            `ctrl-t`  tmux sessions' \
        '  `ctrl-g`  sesh configs          `ctrl-x`  zoxide directories' \
        '  `ctrl-f`  directories under ~   `ctrl-d`  kill the highlighted session'
end
