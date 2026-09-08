function _keys_describe --description "Look a key up in the keys_bind registry: source file, label, then detail lines"
    for entry in $_keys_registry
        set -l field (string split -m3 \t -- $entry)
        test "$field[1]" = "$argv[1]"; or continue
        printf '%s\n' $field[2] $field[3]
        # Detail lines are stored \x1e-separated; see keys_bind for why not newlines.
        test -n "$field[4]"; and string split \x1e -- $field[4]
        return 0
    end
    return 1
end
