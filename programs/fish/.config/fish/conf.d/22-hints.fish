# Cheatsheet chord (interactive only). `hints` is the command; this is its chord.
#
# ctrl-? is what fish names the chord when the terminal reports it under the Kitty
# keyboard protocol; ctrl-shift-/ is a different name to fish and did not fire. If it
# stops working, `fish_key_reader` prints the name fish sees for any key press.
if status is-interactive
    keys_bind ctrl-? hints 'Show this cheatsheet' \
        'Key bindings, abbreviations, aliases and functions in one searchable list;' \
        '`ctrl-a` `ctrl-k` `ctrl-b` `ctrl-l` `ctrl-f` switch between all and each group.' \
        'Bindings are read live from `bind --user`; one bound without `keys_bind` shows' \
        'as "no description" and sorts to the top. `Enter` inserts the highlighted name' \
        'at the cursor, or runs it if it is a key binding; `alt-enter` inserts and runs.'
end
