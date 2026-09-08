function _keys_rows --description "Emit key/label/group/command-name/rank/command rows for every custom key binding"
    # These files bind keys to editing behaviour (auto-closing brackets, vi-mode paste and
    # word deletion), not to shortcuts anyone needs to look up. Everything else is listed,
    # so a newly installed plugin's keys show up here without anyone remembering to add them.
    set -f skip_sources autopair.fish 90-vi-mode.fish

    set -f group ''
    set -f seen

    for line in (bind --user --color=never 2>/dev/null)
        # `bind --user` tags each block with the file that created it. That file is the only
        # grouping signal fish offers, since bindings carry no description of their own.
        set -f defined (string match -r '^# Defined in (.+):$' -- $line)
        if set -q defined[2]
            set group (path basename $defined[2])
            continue
        end

        contains -- $group $skip_sources; and continue

        set -f parts (string match -r '^bind (?:-M \S+ )?(?:-m \S+ )?(\S+) (.+)$' -- $line)
        set -q parts[3]; or continue

        # The same key is bound once per vi mode; the list only needs it once.
        set -f key $parts[2]
        contains -- $key $seen; and continue
        set -a seen $key

        set -f cmd (string trim --chars="'\"" -- $parts[3])
        set -f name (string split -f1 ' ' -- $cmd)

        # Rank 0 sorts undescribed bindings to the top of the list, where they get noticed.
        # A registered key is grouped by the file that called keys_bind; an unregistered
        # one by the file `bind --user` attributes it to.
        if set -f text (_keys_describe $key)
            set -f label $text[2]
            set -f source $text[1]
            set -f rank 1
        else
            set -f label 'no description'
            set -f source $group
            set -f rank 0
        end

        printf '%s\t%s\t%s\t%s\t%s\t%s\n' $key $label (_keys_group $source) $name $rank $cmd
    end
end
