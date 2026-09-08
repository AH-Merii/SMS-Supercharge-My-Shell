function _hints_preview --description "Preview command for hints: run WORD --help in a config-less fish"
    # _hints_preview WORD
    #
    # fzf runs this under `fish --no-config -c` (hints sets --with-shell), which starts in a
    # few milliseconds and cannot touch the live shell. It also loads nothing from the
    # config, since fish's share config is what sets fish_function_path; that is restored
    # here so the config's autoloaded functions resolve (fish's own are embedded in the
    # binary and always do). Nothing from conf.d is loaded, which is why _hints_help offers
    # autoloaded functions only. The row's own text is printed by the preview command before
    # this runs, so that a failing --help does not quote it in fish's trace.
    test -n "$argv[1]"; or return 0

    set -g fish_function_path $__fish_config_dir/functions $__fish_data_dir/functions
    printf '\n%s%s --help:%s\n' (set_color brblack) $argv[1] (set_color normal)
    $argv[1] --help </dev/null 2>&1 | head -n 400
end
