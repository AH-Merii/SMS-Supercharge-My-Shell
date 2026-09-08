function _keys_style --description "Colour the cheatsheet's detail markup: `key` cyan, 'Heading:' dim"
    set -l key (set_color --bold cyan)
    set -l dim (set_color brblack)
    set -l normal (set_color normal)

    for line in $argv
        if string match -qr ':$' -- $line
            printf '%s%s%s\n' $dim $line $normal
        else
            string replace -ra '`([^`]+)`' "$key\$1$normal" -- $line
        end
    end
end
