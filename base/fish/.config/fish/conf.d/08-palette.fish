# Slots 16 and up of the ghostty theme (orange, the diff backgrounds, the background
# again), for a terminal that is not ghostty: Windows Terminal on WSL, or whatever is at
# the far end of an ssh session. A colour scheme covers sixteen slots, so there those
# slots are xterm's black and blues: black numbers in bat, blue diffs in delta. OSC 4 sets
# any of the 256 entries at runtime, so they are read out of the theme file and sent once
# per interactive shell. Not from inside tmux (the shell that started it already did this,
# and tmux keeps a palette of its own per pane), and only to the xterm family, which
# ignores an OSC it does not know; ghostty has the slots already.
status is-interactive; or return
set -q TMUX; and return
test "$TERM_PROGRAM" = ghostty; or test "$TERM" = xterm-ghostty; and return
string match -q 'xterm*' -- $TERM; or return

set -l theme ~/.config/ghostty/themes/OneDark
test -r $theme; or return
for entry in (string replace -rf '^palette = (\d+)=#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})\s*$' '$1;rgb:$2/$3/$4' <$theme)
    test (string split -m1 ';' $entry)[1] -ge 16; and printf '\e]4;%s\e\\' $entry
end
