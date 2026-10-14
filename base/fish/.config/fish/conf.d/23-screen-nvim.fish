# Terminal contents in nvim (interactive only). Ghostty's ctrl+s scroll mode sends these
# keys: `v` the visible screen, `V` everything. Fish names no key past f12, so the
# triggers are chords nobody types.
if status is-interactive
    keys_bind ctrl-alt-shift-f11 '_screen_nvim screen' 'Open the visible screen in nvim' \
        'Sent by Ghostty: `ctrl+s` then `v`. Opens what is on screen in read-only nvim,' \
        'with yanks going to the system clipboard. `q` returns to the prompt.'
    keys_bind ctrl-alt-shift-f12 '_screen_nvim all' 'Open the whole scrollback in nvim' \
        'Sent by Ghostty: `ctrl+s` then `V`. Opens all history and the screen in' \
        'read-only nvim, with yanks going to the system clipboard. `q` returns to the prompt.'
    # Ghostty types the dump's path and Enter into this mode right after the key above.
    bind -M screen_nvim '' self-insert
    bind -M screen_nvim enter _screen_nvim_open
end
