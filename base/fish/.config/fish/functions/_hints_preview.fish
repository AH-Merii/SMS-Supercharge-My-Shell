function _hints_preview --description "Preview command for hints: print the row's text from stdin, then run WORD --help in a config-less fish"
    # printf '%b\n' BODY | _hints_preview WORD
    #
    # fzf runs this under `fish --no-config -c` (hints sets --with-shell), which starts in a
    # few milliseconds and cannot touch the live shell. It also loads nothing from the
    # config, since fish's share config is what sets fish_function_path; that is restored
    # here so the config's autoloaded functions resolve (fish's own are embedded in the
    # binary and always do). Nothing from conf.d is loaded, so there is no theme either:
    # every colour in the row's text, the highlighted command lines included, was put there
    # by the shell that built the rows. The text arrives on stdin rather than as an
    # argument, so that a failing --help does not quote it in fish's trace.
    cat

    test -n "$argv[1]"; or return 0

    # The help is coloured by bat's Command Help syntax, the way bat colours its own help on
    # a terminal: headings, options and placeholders each get a colour, and every tool gets
    # the same treatment. Left to themselves, tools colour their help only for a terminal,
    # which fzf's pipe is not, and even there most manage bold and underline at best (eza,
    # tuicr, delta). bat must see plain text, since escape sequences in its input break
    # the highlighting (its --strip-ansi defaults to never), so the tool is not asked for
    # colour. The preview window does the wrapping. Without bat the help shows plain.
    set -l colour cat
    command -q bat; and set colour bat --language cmd-help --color=always --style=plain --paging=never --wrap=never
    set -g fish_function_path $__fish_config_dir/functions $__fish_data_dir/functions
    $argv[1] --help </dev/null 2>&1 | head -n 400 | $colour
end
