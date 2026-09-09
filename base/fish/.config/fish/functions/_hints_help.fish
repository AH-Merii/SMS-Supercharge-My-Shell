function _hints_help --description "Print WORD if the hints preview may run \`WORD --help\` unattended, else return 1"
    # _hints_help WORD
    #
    # The preview fires on every cursor move, so it may only run --help where that is known
    # to be harmless. Builtins always answer it, and external commands do by convention. A
    # function does whatever its body says, and one that ignores its arguments would run for
    # real, so a function is accepted only when its code (comments aside) handles the flag,
    # and only when it autoloads from the config's functions directory or is one of fish's
    # own: the places the preview's config-less shell can find it (see _hints_preview).
    set -l word $argv[1]
    test -n "$word"; or return 1

    if functions -q -- $word
        # fish 4 embeds its own functions in the binary and reports those as embedded:...;
        # older versions autoload them from the data directory.
        set -l file (functions --details -- $word)
        string match -q -- "$__fish_config_dir/functions/*" $file
        or string match -q -- "$__fish_data_dir/functions/*" $file
        or string match -q -- 'embedded:functions/*' $file
        or return 1
        functions -- $word | string match -rv '^\s*#' | string match -qr -- '--help|\bh/help\b'; or return 1
    # The -- keeps a word that is itself a flag, like the --help abbreviation, from being
    # read as one: `builtin -q --help` prints builtin's own help.
    else if not builtin -q -- $word; and not command -q -- $word
        return 1
    end
    echo $word
end
