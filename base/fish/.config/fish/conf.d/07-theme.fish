# The One Dark palette (github.com/atom/atom/tree/master/packages/one-dark-syntax) as fish's
# colour variables, in the format `fish_config theme dump` prints, so it is also a valid
# theme file. Set for every fish, not just interactive ones: fish applies its own default
# theme only at an interactive start, and the syntax highlighting fzf shows in the history
# and hints previews runs in a `fish -c`, which would otherwise have no colours at all.
# hints and the pickers' headers colour by role through these variables (fish_color_command
# for a key or command word, fish_color_autosuggestion for text to ignore), so they follow
# whatever is set here. Try another built-in theme in the current session with
# `fish_config theme choose NAME` and replace these lines with `fish_config theme dump`.
set -g fish_color_normal --reset
set -g fish_color_command 61afef
set -g fish_color_keyword c678dd
set -g fish_color_option 56b6c2
set -g fish_color_param abb2bf
set -g fish_color_quote 98c379
set -g fish_color_escape d19a66
set -g fish_color_redirection e5c07b --bold
set -g fish_color_end c678dd
set -g fish_color_operator c678dd
set -g fish_color_comment 5c6370 --italics
set -g fish_color_autosuggestion 5c6370
set -g fish_color_error e06c75
set -g fish_color_status e06c75
set -g fish_color_cancel --reverse
set -g fish_color_valid_path --underline
set -g fish_color_search_match --background=3e4452 --bold
set -g fish_color_selection abb2bf --background=3e4452 --bold
set -g fish_color_history_current abb2bf --bold
set -g fish_color_cwd 56b6c2
set -g fish_color_cwd_root e06c75
set -g fish_color_user 98c379
set -g fish_color_host 98c379
set -g fish_color_host_remote e5c07b
set -g fish_pager_color_completion abb2bf
set -g fish_pager_color_description d19a66 --italics
set -g fish_pager_color_prefix 61afef --bold --underline
set -g fish_pager_color_progress 282c34 --background=61afef --bold
set -g fish_pager_color_selected_background --background=3e4452
