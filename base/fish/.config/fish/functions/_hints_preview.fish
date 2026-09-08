function _hints_preview --description "Preview command for hints: print the row's text from stdin, then run WORD --help in a config-less fish"
    # printf '%b\n' BODY | _hints_preview WORD
    #
    # fzf runs this under `fish --no-config -c` (hints sets --with-shell), which starts in a
    # few milliseconds and cannot touch the live shell. It also loads nothing from the
    # config, since fish's share config is what sets fish_function_path; that is restored
    # here so the config's autoloaded functions resolve (fish's own are embedded in the
    # binary and always do). Nothing from conf.d is loaded, which is why _hints_help offers
    # autoloaded functions only. The row's own text arrives on stdin rather than as an
    # argument, so that a failing --help does not quote it in fish's trace.

    # A line starting with \x1f is a command line (an abbreviation's expansion, an alias's
    # body), coloured so its command words stand out from their arguments: fish_indent
    # does the parsing, so every command in a pipeline or list is found, not just the
    # first word. It colours from the fish_color_* globals, which is why this happens here
    # and not where the rows are built: in this throwaway shell they can be set outright,
    # and they are all set, so a theme saved as universal variables cannot leak in. Cyan
    # is what hints uses for what is typed or pressed (the name column, `text` in a key
    # binding's details), so the command words get it and everything else stays plain.
    set -g fish_color_command --bold cyan
    set -g fish_color_keyword --bold cyan
    for part in normal param option redirection operator end quote escape comment
        set -g fish_color_$part normal
    end
    while read -l line
        if string match -q -- \x1f'*' $line
            string sub --start 2 -- $line | fish_indent --ansi
        else
            printf '%s\n' $line
        end
    end

    test -n "$argv[1]"; or return 0

    # A tool colours its help only when stdout is a terminal, and here it is fzf's pipe, so
    # ask for the colour outright: CLICOLOR_FORCE and FORCE_COLOR are the two conventions
    # for that, and the preview window renders what comes back. Exported for this function
    # only, so the --help command is the one thing that sees them. bat and delta stay
    # plain, since their help only gets colour on the way through their own pager.
    set -lx CLICOLOR_FORCE 1
    set -lx FORCE_COLOR 1
    set -g fish_function_path $__fish_config_dir/functions $__fish_data_dir/functions
    printf '\n%s%s --help:%s\n' (set_color brblack) $argv[1] (set_color normal)
    $argv[1] --help </dev/null 2>&1 | head -n 400
end
