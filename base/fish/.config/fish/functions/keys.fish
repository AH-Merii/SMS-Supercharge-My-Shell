# Searchable cheatsheet of this shell's custom key bindings. How the list is built, in order:
#
#   1. `bind --user` lists every non-preset binding, tagged with the file that made it.
#   2. Bindings from files in skip_sources (_keys_rows) are dropped outright: editing
#      helpers like autopair and vi-mode paste, not shortcuts anyone looks up.
#   3. One row per key: the vi-mode duplicates (default + insert) collapse.
#   4. The key is looked up in the registry that keys_bind fills as it binds. A key bound
#      any other way still gets a row, labelled "no description" and sorted to the top, so
#      a binding that skipped keys_bind is noticed the next time the list opens.
#
# To add a shortcut:           keys_bind KEY COMMAND LABEL [DETAIL...] in conf.d, after
#                              03-fisher-path.fish so it lands on top of plugin defaults.
# To hide a file's bindings:   add the file's basename to skip_sources in _keys_rows.
function keys --description "Searchable list of this shell's custom key bindings"
    set -f rows (_keys_rows | sort -t \t -k5,5n -k3,3 -k1,1)
    if test -z "$rows"
        echo 'keys: no custom key bindings found' >&2
        return 1
    end

    # Pad the key column to the widest key so the labels line up.
    set -f width 0
    for row in $rows
        set -f len (string length -- (string split -f1 \t -- $row))
        test $len -gt $width; and set width $len
    end

    # Hidden fields ride along after the visible text: the preview, newlines escaped so
    # the line stays one line (fzf's preview unescapes with printf %b), and the bound
    # command for Enter. Rendering the preview here rather than in the preview command
    # keeps it in this shell, where the registry lives.
    #
    # --ansi makes fzf strip colour codes from the whole line, hidden fields included, so
    # the preview's ESC bytes travel as the literal text \033 (after the backslash
    # doubling, so they are not doubled themselves) and printf %b turns them back.
    set -f lines
    for row in $rows
        set -f field (string split \t -- $row)
        if test $field[5] -eq 0
            set -f label_color (set_color --bold yellow)
        else
            set -f label_color (set_color normal)
        end
        set -f preview (_keys_preview $field[1] $field[4] | string replace -a \\ \\\\ | string replace -a \e '\\033' | string join '\\n')
        set -a lines (printf '%s%s%s  %s%s%s  %s%s%s\t%s\t%s' \
            (set_color --bold cyan) (string pad --right --width $width -- $field[1]) (set_color normal) \
            $label_color $field[2] (set_color normal) \
            (set_color brblack) $field[3] (set_color normal) \
            $preview $field[6])
    end

    # Match _sesh_search: a tmux popup when there is one, a plain pane split otherwise.
    if set -q TMUX
        set -f fzf_cmd fzf-tmux -p 70%,60%
    else
        set -f fzf_cmd fzf --height=60%
    end

    set -f picked (
        printf '%s\n' $lines | $fzf_cmd \
            --ansi --no-sort \
            --delimiter \t --with-nth 1 \
            --border-label ' key bindings ' \
            --prompt '  ' \
            --header 'enter runs the binding' \
            --preview-window 'down:45%:wrap' \
            --preview "printf '%b\n' {2}"
    )

    # Enter runs the binding, as if its key had been pressed. Selecting this list itself
    # would just reopen it, so that one is a no-op.
    if test $status -eq 0 && test -n "$picked"
        set -f cmd (string split -f3 \t -- $picked)
        test "$cmd" != keys; and eval $cmd
    end

    # No-op unless keys was reached from its own binding, hence the suppressed error.
    commandline --function repaint 2>/dev/null
end
