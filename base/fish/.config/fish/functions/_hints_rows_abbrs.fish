function _hints_rows_abbrs --description "hints rows for every abbreviation"
    # `abbr --show` prints each abbreviation as the command that recreates it,
    #
    #   abbr -a [FLAGS...] -- NAME EXPANSION
    #
    # with EXPANSION quoted the way fish would write it, and absent when a --function
    # computes it. Flags (regex, position, cursor marker) are shown in the preview as written.
    set -l bold (set_color --bold)
    set -l dim (set_color brblack)
    set -l normal (set_color normal)

    for line in (abbr --show)
        set -l m (string match -r -- '^abbr -a (.*?)-- (\S+)(?: (.*))?$' $line)
        set -q m[3]; or continue
        set -l name $m[3]
        set -l flags (string trim -- $m[2])
        set -l expansion ''
        set -q m[4]; and set expansion (string unescape -- $m[4])

        set -l label $expansion
        test -n "$label"; or set label (string match -r -- '--function \S+' $flags)
        set -l body $bold$label$normal
        test -n "$flags"; and set -a body $dim$flags$normal
        set -l target (string split -m1 ' ' -- $expansion)[1]

        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            $name $label abbr abbreviation 1 insert $name (_hints_help $target; or echo) (string join \x1e -- $body)
    end
end
