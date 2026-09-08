function _keys_group --description "Readable group name for the file a binding came from"
    switch $argv[1]
        case fzf_configure_bindings.fish
            echo fzf.fish
        case '*'
            # conf.d files are ordering-prefixed: 21-sesh.fish reads better as "sesh".
            string replace -r '^\d+-' '' -- $argv[1] | string replace -r '\.fish$' ''
    end
end
