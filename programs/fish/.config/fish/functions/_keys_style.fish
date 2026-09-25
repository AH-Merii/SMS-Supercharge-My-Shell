function _keys_style --description "Colour the cheatsheet's detail markup: `key` as a command word, 'Heading:' dim"
    # Colours come from the theme (conf.d/07-theme.fish): a key is what is typed, like a
    # command word, and a heading is text to skim past, like an autosuggestion.
    set -l key (set_color $fish_color_command)
    set -l dim (set_color $fish_color_autosuggestion)
    set -l normal (set_color normal)

    for line in $argv
        if string match -qr ':$' -- $line
            printf '%s%s%s\n' $dim $line $normal
        else
            string replace -ra '`([^`]+)`' "$key\$1$normal" -- $line
        end
    end
end
