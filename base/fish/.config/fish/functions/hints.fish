# Searchable cheatsheet of the shell's key bindings, abbreviations, aliases and functions.
#
# Each group is a source function, _hints_rows_GROUP, that emits one tab-separated row per
# entry and knows nothing about the picker; the picker knows nothing about a group beyond
# its name. A new group is one more source function plus a line in `groups`, an icon, a
# hotkey and a header entry below. Row columns (none may contain a tab):
#
#   1 name     what is typed or pressed: the key, abbreviation, alias or function name
#   2 label    one line shown beside the name
#   3 kind     short tag shown dim between the name and the label: key, abbr, alias, fn
#   4 heading  dim line under the name in the preview, e.g. "key binding · sesh"
#   5 rank     0 sorts first within the group; the sources use it for entries missing text
#   6 action   run: Enter runs the payload as a command (a key binding's command)
#              insert: Enter puts the payload on the command line
#   7 payload
#   8 help     a command word whose --help the preview runs, or empty (see _hints_help)
#   9 body     preview text under the heading, lines joined with \x1e (see keys_bind for
#              why not newlines); colour codes allowed, the preview shows them as they are
function hints --description "Searchable cheatsheet of the shell's key bindings, abbreviations, aliases and functions"
    set -f groups keys abbrs aliases functions
    argparse h/help -- $argv; or return 2
    if set -q _flag_help
        echo 'usage: hints [GROUP...]'
        echo
        echo "Open the cheatsheet on GROUP ($groups), or on everything. Inside the picker,"
        echo 'ctrl-a/k/b/l/f switch between all and each group, Enter inserts the highlighted'
        echo 'name at the cursor (or runs it, for a key binding), alt-enter inserts and runs it,'
        echo 'and ctrl-d / ctrl-u scroll the preview.'
        return 0
    end
    for g in $argv
        contains -- $g $groups; and continue
        echo "hints: unknown group '$g'; expected one of: $groups" >&2
        return 2
    end
    set -f start $argv
    test -n "$start"; or set start $groups

    # Every group is rendered up front, even when opening on one, so the hotkeys inside the
    # picker only filter: nothing that runs in there needs this shell's state (the keys
    # registry, the aliases conf.d defined). Rows sort by rank, then heading, then name.
    set -f rows
    for g in $groups
        for row in (_hints_rows_$g | sort -t \t -k5,5n -k4,4 -k1,1)
            set -a rows $g\t$row
        end
    end
    if test -z "$rows"
        echo 'hints: nothing to show' >&2
        return 1
    end

    # Pad the name and kind columns to their widest entry so the labels line up.
    set -f width 0
    set -f kind_width 0
    for row in $rows
        set -l f (string split \t -- $row)
        set -l len (string length -- $f[2])
        test $len -gt $width; and set width $len
        set len (string length -- $f[4])
        test $len -gt $kind_width; and set kind_width $len
    end

    # The visible text is three tab-separated fields, name, kind and label, so that fzf can
    # search the name and the label but not the kind (every abbreviation matches "b"
    # otherwise). Hidden fields ride along after them: the preview, the help word, the
    # action, its payload and the group. The preview must stay on the row's one line, so
    # its newlines are escaped for the printf %b in the preview command. --ansi makes fzf
    # strip colour codes from the whole line, hidden fields included, so the preview's ESC
    # bytes travel as the literal text \033 (after the backslash doubling, so they are not
    # doubled themselves) and printf %b turns them back; tabs would split the row, so they
    # travel as \t likewise. The colours are the theme's, by role: the name is what is typed,
    # like a command word; the heading is text to skim past, like an autosuggestion. The
    # "--help:" heading is built here too, since the preview's fish has no theme.
    set -f cyan (set_color $fish_color_command)
    set -f dim (set_color $fish_color_autosuggestion)
    set -f normal (set_color normal)
    set -f lines
    for row in $rows
        set -l f (string split \t -- $row)
        # f: the group, then the nine row columns, so each sits one to the right
        set -l label_color $normal
        test $f[6] -eq 0; and set label_color (set_color $fish_color_error)
        set -l help_heading
        test -n "$f[9]"; and set help_heading '' "$dim$f[9] --help:$normal"
        set -l preview (string join \x1e -- $cyan$f[2]$normal $dim$f[5]$normal '' $f[10] $help_heading |
            string replace -a \\ \\\\ | string replace -a \e '\\033' | string replace -a \t '\\t' |
            string replace -a \x1e '\\n')
        # A tab renders one column wide (--tabstop=1 below), so each field after the first
        # starts with a space to make the usual two-space gap.
        set -a lines (printf '%s%s%s\t %s%s%s\t %s%s%s\t%s\t%s\t%s\t%s\t%s' \
            $cyan (string pad --right --width $width -- $f[2]) $normal \
            $dim (string pad --right --width $kind_width -- $f[4]) $normal \
            $label_color $f[3] $normal \
            $preview $f[9] $f[7] $f[8] $f[1])
    end

    # The group hotkeys reload from a file of every line, filtered on the group column.
    set -f file (mktemp -t hints.XXXXXX); or return 1
    printf '%s\n' $lines >$file

    set -f icon_all ''
    set -f icon_keys ''
    set -f icon_abbrs '󰦩'
    set -f icon_aliases '󰌷'
    set -f icon_functions '󰊕'
    set -f prompt "$icon_all all  "
    if test (count $start) -eq 1
        set -f var icon_$start
        set prompt $$var" $start  "
    else if test "$start" != "$groups"
        set prompt "$icon_all $start  "
    end
    set -f header "^a $icon_all all  ^k $icon_keys keys  ^b $icon_abbrs abbrs  ^l $icon_aliases aliases  ^f $icon_functions functions
enter inserts the name (runs a key binding) · alt-enter inserts and runs · ^d ^u scroll the preview"

    # Match _sesh_search: a tmux popup when there is one, a plain pane split otherwise.
    if set -q TMUX
        set -f fzf_cmd fzf-tmux -p 80%,70%
    else
        set -f fzf_cmd fzf --height=70%
    end

    # The preview and the reloads run in a config-less fish (see _hints_preview), which
    # autoloads nothing, so the preview function is sourced by path first. The row's text
    # is piped into that function rather than passed as an argument: when a --help fails,
    # fish's trace lands in the preview, and it would quote the whole text as the
    # function's argument.
    #
    # fzf keeps the input order while the query is empty, so the groups and ranks show as
    # sorted; once something is typed the best match wins, which --no-sort would prevent,
    # and a match nearer the start of the line, that is in the name, beats one in the label.
    set -f preview_fn (functions --details -- _hints_preview)
    set -f picked (
        string match -er -- '\t(?:'(string join '|' $start)')$' $lines | $fzf_cmd \
            --ansi --tabstop 1 --tiebreak begin,length \
            --delimiter \t --with-nth 1..3 --nth 1,3 \
            --with-shell 'fish --no-config -c' \
            --border-label ' hints ' \
            --prompt $prompt \
            --header $header \
            --bind "ctrl-a:change-prompt($icon_all all  )+reload(cat '$file')" \
            --bind "ctrl-k:change-prompt($icon_keys keys  )+reload(string match -er '\tkeys\$' <'$file')" \
            --bind "ctrl-b:change-prompt($icon_abbrs abbrs  )+reload(string match -er '\tabbrs\$' <'$file')" \
            --bind "ctrl-l:change-prompt($icon_aliases aliases  )+reload(string match -er '\taliases\$' <'$file')" \
            --bind "ctrl-f:change-prompt($icon_functions functions  )+reload(string match -er '\tfunctions\$' <'$file')" \
            --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up' \
            --expect alt-enter \
            --preview-window 'right:55%:wrap' \
            --preview "source '$preview_fn'; printf '%b\n' {4} | _hints_preview {5}"
    )
    set -f rc $status
    rm -f $file

    # --expect puts the key that accepted on the first line: empty for Enter.
    if test $rc -eq 0 && test -n "$picked[2]"
        set -f f (string split \t -- $picked[2])
        # f: 1 name 2 kind 3 label 4 preview 5 help word 6 action 7 payload 8 group
        switch $f[6]
            case run
                # A key binding runs as if its key had been pressed, on Enter and alt-enter
                # alike. Selecting this list itself would only reopen it, so that is a no-op.
                contains -- $f[7] hints keys; or eval $f[7]
            case insert
                # The name replaces the token under the cursor, as fzf.fish's pickers do with
                # paths: on an empty line it becomes the whole line, after a half-typed word
                # it completes it. Typed as a command rather than reached from its chord,
                # hints has no live line: fish puts the text on the next prompt instead, and
                # execute does nothing there, so alt-enter says so rather than fail quietly.
                # A command line being executed is what tells the two apart.
                commandline --current-token --replace -- $f[7]
                if test "$picked[1]" = alt-enter
                    if test -z "$(status current-commandline)"
                        commandline --function execute
                    else
                        echo "hints: alt-enter runs the line from the key binding only; $f[7] is on the prompt" >&2
                    end
                end
        end
    end

    # No-op unless hints was reached from its own binding, hence the suppressed error.
    commandline --function repaint 2>/dev/null
end
