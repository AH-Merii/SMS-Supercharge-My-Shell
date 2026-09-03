# FZF configuration for fzf.fish plugin
# See: https://github.com/PatrickF1/fzf.fish

# fd options for file search
set -gx fzf_fd_opts --hidden --follow --exclude .git

# Preview commands (bat for files, eza tree for directories)
set -gx fzf_preview_file_cmd 'bat -n --color=always --style=numbers'
set -gx fzf_preview_dir_cmd 'eza --icons=always --tree --level=2'

# Use delta for git diff highlighting if available
if type -q delta
    set -gx fzf_diff_highlighter delta --paging=never --width=20
end

# Directory search options
set -gx fzf_directory_opts \
    --bind 'page-up:preview-up,page-down:preview-down,ctrl-d:preview-page-down,ctrl-u:preview-page-up,ctrl-/:change-preview-window(down|hidden|)'

# Detect clipboard command for history copy feature (store as list: cmd + args)
if type -q pbcopy
    set -g _clip_cmd pbcopy
else if type -q wl-copy
    set -g _clip_cmd wl-copy
else if type -q xclip
    set -g _clip_cmd xclip -selection clipboard
else
    set -g _clip_cmd cat
end

# History search options with copy-to-clipboard support
set -gx fzf_history_opts \
    --preview 'echo {}' \
    --preview-window up:3:hidden:wrap \
    --bind "ctrl-/:toggle-preview,ctrl-y:execute-silent(echo -n {2..} | $_clip_cmd)+abort" \
    --color header:italic \
    --header 'Press CTRL-Y to copy command into clipboard'
