function _hints_rows_aliases --description "hints rows for every alias"
    # fish has no alias namespace. `alias NAME BODY` defines a function NAME whose
    # description is the literal text "alias NAME BODY" (zoxide writes "alias z=__zoxide_z"
    # by hand), and that description is the only thing that tells an alias from a function.
    set -l bold (set_color --bold)
    set -l normal (set_color normal)

    for name in (functions --names)
        set -l desc (functions --details --verbose -- $name)[5]
        set -l body (string replace -r -- '^alias '(string escape --style=regex -- $name)'[ =]' '' $desc)
        or continue
        set -l target (string split -m1 ' ' -- $body)[1]

        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            $name $body alias alias 1 insert $name (_hints_help $target; or echo) $bold$body$normal
    end
end
