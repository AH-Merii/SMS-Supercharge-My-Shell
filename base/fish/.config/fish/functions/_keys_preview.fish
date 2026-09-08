function _keys_preview --description "Render the cheatsheet preview text for a key"
    # _keys_preview KEY COMMAND
    #
    # Detail lines carry light markup so the conf.d files stay readable: `text` in
    # backticks is a key or command and renders cyan, like the key column; a line ending
    # in a colon is a section heading and renders dim.
    set -l bold (set_color --bold)
    set -l warn (set_color --bold yellow)
    set -l normal (set_color normal)

    if set -l text (_keys_describe $argv[1])
        printf '%s%s%s\n\n' $bold $text[2] $normal
        _keys_style $text[3..]
        return
    end

    printf '%sno description%s\n\n' $warn $normal
    # Single quotes: fish leaves \` alone inside double quotes, so the backslashes would show.
    _keys_style \
        '`'$argv[1]'` is bound to `'$argv[2]'`, but not through `keys_bind`, so there is' \
        'nothing to say about it. Bind it with `keys_bind KEY COMMAND LABEL [DETAIL...]`' \
        'to give it one, or add its source file to skip_sources in `_hints_rows_keys` to hide it.'

    # The function's own --description is a decent starting point for writing one.
    set -l own (functions --details --verbose $argv[2] 2>/dev/null)[5]
    if test -n "$own" -a "$own" != n/a
        _keys_style '' 'It describes itself as:' $own
    end
end
