function _screen_nvim --description "Take the path of the screen dump Ghostty sends next"
    # _screen_nvim screen|all
    #
    # Ghostty's ctrl+s key table (base/ghostty/.config/ghostty/config) sends this binding's
    # key, then the path of a dump of the whole terminal and Enter, all in one burst. A
    # nested `read` can miss keys that arrived with the trigger, so let the path type into
    # an empty command line in the screen_nvim bind mode, where Enter runs _screen_nvim_open.
    set -g _screen_nvim_kind $argv[1]
    set -g _screen_nvim_mode $fish_bind_mode
    set -g _screen_nvim_cursor (commandline --cursor)
    set -g _screen_nvim_line (commandline | string collect)
    commandline ''
    # The path is drawn on the alternate screen, which nvim uses too, so the scrollback
    # keeps nothing of it.
    printf '\e[?1049h'
    set fish_bind_mode screen_nvim
end

function _screen_nvim_open --description "Open the screen dump typed by Ghostty in read-only nvim"
    set -l dump (commandline | string collect)
    # Insert mode first: outside it, fish keeps the cursor off the end of the line.
    set fish_bind_mode $_screen_nvim_mode
    commandline -- $_screen_nvim_line
    commandline --cursor $_screen_nvim_cursor

    # Ghostty has no action that dumps only the visible rows, so `screen` keeps the last
    # $LINES lines: what is on screen when it is not scrolled up.
    if test -f "$dump"
        set -l file $dump
        if test "$_screen_nvim_kind" = screen
            set file (path dirname $dump)/visible.txt
            tail -n $LINES $dump >$file
        end
        nvim -R -c 'set clipboard=unnamedplus' -c 'nnoremap q <cmd>qa!<cr>' + $file
        rm -f $dump $file
        rmdir (path dirname $dump) 2>/dev/null
    end
    set -e _screen_nvim_kind _screen_nvim_mode _screen_nvim_cursor _screen_nvim_line
    printf '\e[?1049l'
    commandline -f repaint
end
