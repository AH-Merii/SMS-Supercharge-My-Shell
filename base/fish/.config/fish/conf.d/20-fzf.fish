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

# Clipboard command for the history copy feature (stored as list: cmd + args)
switch $OS_KIND
    case macos
        set -g _clip_cmd pbcopy
    case wsl
        set -g _clip_cmd clip.exe
    case '*'
        if type -q wl-copy
            set -g _clip_cmd wl-copy
        else if type -q xclip
            set -g _clip_cmd xclip -selection clipboard
        end
end

# History search options with copy-to-clipboard support. Without a clipboard
# tool the binding is left out and the header says so, rather than a silent no-op.
set -l copy_bind
set -l header 'No clipboard tool found (install wl-copy or xclip); CTRL-Y copy is off'
if set -q _clip_cmd
    set copy_bind ",ctrl-y:execute-silent(echo -n {2..} | $_clip_cmd)+abort"
    set header 'Press CTRL-Y to copy command into clipboard'
end
set -gx fzf_history_opts \
    --preview 'echo {}' \
    --preview-window up:3:hidden:wrap \
    --bind "ctrl-/:toggle-preview$copy_bind" \
    --color header:italic \
    --header $header
