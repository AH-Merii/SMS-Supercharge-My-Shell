# fish's colours by role, named by terminal palette slot rather than hex, so the scheme
# itself lives in the terminal (ghostty/themes/OneDark) and changing it there changes the
# shell, the pickers and the previews together. Set for every fish, not just interactive
# ones: fish applies its own default theme only at an interactive start, and the syntax
# highlighting fzf shows in the history and hints previews runs in a `fish -c`, which
# would otherwise have no colours at all. hints and the pickers' headers colour by role
# through these variables (fish_color_command for a key or command word,
# fish_color_autosuggestion for text to ignore), so they follow whatever is set here.
#
# The slots' roles: brblack is the comment grey, black is a surface grey a step above the
# background (the selection colour), yellow stands in for orange since fish addresses
# only the sixteen named slots.
set -g fish_color_normal --reset
set -g fish_color_command blue
set -g fish_color_keyword magenta
set -g fish_color_option cyan
set -g fish_color_param normal
set -g fish_color_quote green
set -g fish_color_escape yellow
set -g fish_color_redirection yellow --bold
set -g fish_color_end magenta
set -g fish_color_operator magenta
set -g fish_color_comment brblack --italics
set -g fish_color_autosuggestion brblack
set -g fish_color_error red
set -g fish_color_status red
set -g fish_color_cancel --reverse
set -g fish_color_valid_path --underline
set -g fish_color_search_match --background=black --bold
set -g fish_color_selection white --background=black --bold
set -g fish_color_history_current white --bold
set -g fish_color_cwd cyan
set -g fish_color_cwd_root red
set -g fish_color_user green
set -g fish_color_host green
set -g fish_color_host_remote yellow
set -g fish_pager_color_completion white
set -g fish_pager_color_description yellow --italics
set -g fish_pager_color_prefix blue --bold --underline
set -g fish_pager_color_progress black --background=blue --bold
set -g fish_pager_color_selected_background --background=black
