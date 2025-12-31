# Keep Fisher + plugins in XDG data dir

set -gx fisher_path $XDG_DATA_HOME/fisher

# Make Fish see plugin functions & completions (must happen unconditionally
# so fisher install can find newly-installed functions when sourcing conf.d)
set -g fish_function_path $fisher_path/functions $fish_function_path
set -g fish_complete_path $fisher_path/completions $fish_complete_path

if not status is-interactive
    return
end

# Source plugin conf.d explicitly (Fish only auto-sources ~/.config/fish/conf.d)
set -l confs $fisher_path/conf.d/*.fish
for f in $confs
    test -r $f; and source $f
end

# Print instructions every interactive shell if fisher isn't installed
if not functions -q fisher
    set -l border_color d97706
    echo
    set_color $border_color
    echo "╭────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮"
    echo -n "│  "
    set_color red --bold
    echo -n "⚠ Fisher not found"
    set_color $border_color
    echo "                                                                                            │"
    echo "├────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤"
    echo -n "│  "
    set_color yellow --bold
    echo -n "Install:"
    set_color normal
    set_color cyan
    echo -n "  curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source"
    set_color normal
    set_color $border_color
    echo "  │"
    echo -n "│  "
    set_color yellow --bold
    echo -n "Then:"
    set_color normal
    set_color cyan
    echo -n "     fisher update"
    set_color normal
    set_color $border_color
    echo "                                                                                       │"

    echo "╰────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯"
    set_color normal
    echo
end
