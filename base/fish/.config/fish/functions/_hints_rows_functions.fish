function _hints_rows_functions --description "hints rows for the functions this config defines"
    # "This config" is whatever fish loaded from $__fish_config_dir: autoloaded files under
    # functions/ and functions defined inline in conf.d. That leaves out fish's own
    # functions, the plugins' and the hooks that tools install (mise, worktrunk, zoxide),
    # which their own docs cover. Underscore-prefixed names are private helpers by
    # convention, and fish_* is fish's namespace for hooks like fish_user_key_bindings,
    # which nobody calls by hand.
    set -l bold (set_color --bold)
    set -l dim (set_color brblack)
    set -l warn (set_color --bold yellow)
    set -l normal (set_color normal)

    for name in (functions --names)
        string match -qr -- '^(_|fish_)' $name; and continue
        set -l details (functions --details --verbose -- $name)
        string match -q -- "$__fish_config_dir/*" $details[1]; or continue
        string match -q -- 'alias *' $details[5]; and continue

        set -l file (string replace -- "$__fish_config_dir/" '' $details[1])
        set -l desc $details[5]
        set -l rank 1
        set -l body $bold$desc$normal
        if test "$desc" = n/a
            # Rank 0 sorts an undescribed function to the top of its group, where it is noticed.
            set desc 'no description'
            set body $warn$desc$normal
            set rank 0
        end
        set -l help (_hints_help $name; or echo)
        if test -z "$help"
            set -a body '' $dim$name' does not handle --help; add that and its help shows here.'$normal
        end

        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            $name $desc fn "function · $file" $rank insert $name $help (string join \x1e -- $body)
    end
end
