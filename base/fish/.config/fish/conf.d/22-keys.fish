# Key binding cheatsheet (interactive only). `keys` is the command; this is its chord.
#
# ctrl-? is what fish names the chord when the terminal reports it under the Kitty
# keyboard protocol; ctrl-shift-/ is a different name to fish and did not fire. If it
# stops working, `fish_key_reader` prints the name fish sees for any key press.
if status is-interactive
    keys_bind ctrl-? keys 'Show this list' \
        'Bindings are read live from `bind --user`, so anything a plugin adds appears' \
        'on its own. A key bound without `keys_bind` is shown as "no description" and' \
        'sorted to the top. `Enter` runs the highlighted binding.'
end
