function keys_bind --description "Bind a key in default and insert modes and register its description for keys"
    # keys_bind KEY COMMAND LABEL [DETAIL...]
    #
    # One call both binds and describes, so a shortcut cannot be renamed, moved or removed
    # without its text following. Anything bound some other way still appears in `keys`,
    # marked "no description", which is how a binding that skipped this gets noticed.
    # DETAIL lines may use `text` for a key or command and end in a colon for a heading;
    # _keys_style renders that markup in the preview.
    if test (count $argv) -lt 3
        echo 'usage: keys_bind KEY COMMAND LABEL [DETAIL...]' >&2
        return 2
    end
    set -l key $argv[1]

    for mode in default insert
        bind --mode $mode $key $argv[2]
    end

    # Attribute the binding to the file that called keys_bind. `bind --user` would report
    # this file, which says nothing about where the shortcut belongs. Reading the trace
    # inside a command substitution adds a frame for this file, so skip past it.
    set -l source interactive
    for frame in (status stack-trace | string match -r 'called on line \d+ of file (.+)$' | string match -rv 'of file')
        # ^ the two-step match yields the capture groups alone
        test (path basename $frame) = keys_bind.fish; and continue
        set source (path basename $frame)
        break
    end

    # Re-sourcing config must not leave two entries for one key: drop any existing one.
    set -l esc (string escape --style=regex -- $key)
    if set -q _keys_registry
        set -g _keys_registry (string match -v -r "^$esc\t" -- $_keys_registry)
    end
    # Detail lines are joined with a record separator, not a newline: every command
    # substitution splits on newlines, so an entry containing one would fall apart the
    # next time the registry passes through `set -g _keys_registry (...)`.
    set -ga _keys_registry (string join \t -- $key $source $argv[3] (string join \x1e -- $argv[4..]))
end
