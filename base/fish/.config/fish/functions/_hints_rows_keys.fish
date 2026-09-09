function _hints_rows_keys --description "hints rows for every custom key binding"
    # How the list is built, in order:
    #
    #   1. `bind --user` lists every non-preset binding, tagged with the file that made it.
    #   2. Bindings from files in skip_sources are dropped outright: editing helpers like
    #      autopair and vi-mode paste, not shortcuts anyone looks up.
    #   3. One row per key: the vi-mode duplicates (default + insert) collapse.
    #   4. The key is looked up in the registry that keys_bind fills as it binds. A key bound
    #      any other way still gets a row, labelled "no description" and ranked 0 so it sorts
    #      to the top of the group, where a binding that skipped keys_bind gets noticed.
    #
    # To add a shortcut:           keys_bind KEY COMMAND LABEL [DETAIL...] in conf.d, after
    #                              03-fisher-path.fish so it lands on top of plugin defaults.
    # To hide a file's bindings:   add the file's basename to skip_sources below.
    set -l skip_sources autopair.fish 90-vi-mode.fish

    set -l bold (set_color --bold)
    set -l warn (set_color $fish_color_error)
    set -l normal (set_color normal)

    set -l group ''
    set -l seen
    for line in (bind --user --color=never 2>/dev/null)
        # `bind --user` tags each block with the file that created it. That file is the only
        # grouping signal fish offers, since bindings carry no description of their own.
        set -l defined (string match -r '^# Defined in (.+):$' -- $line)
        if set -q defined[2]
            set group (path basename $defined[2])
            continue
        end
        contains -- $group $skip_sources; and continue

        set -l parts (string match -r '^bind (?:-M \S+ )?(?:-m \S+ )?(\S+) (.+)$' -- $line)
        set -q parts[3]; or continue

        # The same key is bound once per vi mode; the list only needs it once.
        set -l key $parts[2]
        contains -- $key $seen; and continue
        set -a seen $key
        set -l cmd (string trim --chars="'\"" -- $parts[3])

        # A registered key is grouped by the file that called keys_bind; an unregistered one
        # by the file `bind --user` attributes it to. The preview body is the label, then the
        # detail lines, which carry light markup so the conf.d files stay readable: `text` in
        # backticks is a key or command and renders cyan, like the key column; a line ending
        # in a colon is a section heading and renders dim (see _keys_style).
        set -l label 'no description'
        set -l source $group
        set -l rank 0
        set -l body
        if set -l text (_keys_describe $key)
            set label $text[2]
            set source $text[1]
            set rank 1
            set body $bold$label$normal '' (_keys_style $text[3..])
        else
            # Single quotes: fish leaves \` alone inside double quotes, so the backslashes would show.
            set body $warn$label$normal '' (_keys_style \
                '`'$key'` is bound to `'$cmd'`, but not through `keys_bind`, so there is' \
                'nothing to say about it. Bind it with `keys_bind KEY COMMAND LABEL [DETAIL...]`' \
                'to give it one, or add its source file to skip_sources in `_hints_rows_keys` to hide it.')

            # The function's own --description is a decent starting point for writing one.
            set -l own (functions --details --verbose -- $cmd 2>/dev/null)[5]
            if test -n "$own" -a "$own" != n/a
                set -a body '' (_keys_style 'It describes itself as:') $own
            end
        end

        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            $key $label key "key binding · "(_keys_group $source) $rank run $cmd '' (string join \x1e -- $body)
    end
end
