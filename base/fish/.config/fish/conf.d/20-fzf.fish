# FZF configuration for fzf.fish plugin
# See: https://github.com/PatrickF1/fzf.fish

# fd options for file search
set -gx fzf_fd_opts --hidden --follow --exclude .git

# Preview commands (bat for files, eza tree for directories). Both run inside fzf's
# preview, where stdout is a pipe, so colour has to be asked for; on auto both print plain.
set -gx fzf_preview_file_cmd 'bat -n --color=always --style=numbers'
set -gx fzf_preview_dir_cmd 'eza --icons=always --color=always --tree --level=2'

# Use delta for git diff highlighting if available
if type -q delta
    set -gx fzf_diff_highlighter delta --paging=never --width=20
end

# Colours for every fzf, by palette slot so they follow the terminal's theme
# (ghostty/themes/OneDark); fzf's own defaults are fixed 256-colour indexes that match
# nothing. Through FZF_DEFAULT_OPTS so zoxide's `zi` and the tmux session popup get them
# too; the plugin then skips its own layout defaults, so those come first, verbatim.
# Matches are yellow, a colour the highlighted rows rarely use; the current line sits on
# the surface grey. Options a picker passes itself win over these.
set -gx FZF_DEFAULT_OPTS "--cycle --layout=reverse --border --height=90% --preview-window=wrap --marker='*'" \
    "--bind 'page-up:preview-up,page-down:preview-down,ctrl-d:preview-page-down,ctrl-u:preview-page-up,ctrl-/:change-preview-window(down|hidden|)'" \
    "--color=16,hl:yellow,hl+:yellow:bold,bg+:black,pointer:blue,marker:green,prompt:blue,spinner:magenta,info:bright-black,header:bright-black,border:bright-black,separator:bright-black,scrollbar:bright-black,label:white,gutter:-1"

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
        else
            set -g _clip_cmd cat
        end
end

# History search options. The plugin's own preview strips the timestamp and highlights the
# command with fish_indent, which colours from the theme (conf.d/07-theme.fish) in the
# non-interactive fish fzf runs it in; the list rows stay plain, so the preview is where
# a long command is read, and it starts open. ctrl-y copies the command alone: the row is
# "MM-DD HH:MM:SS │ command", so the same strip the plugin uses comes off first, and the
# `string collect` keeps a multi-line command whole. The header colours keys as the
# cheatsheet does, through _keys_style (fzf renders colour in the header without --ansi).
set -gx fzf_history_opts \
    --preview-window up:3:wrap \
    --bind "ctrl-/:toggle-preview,ctrl-y:execute-silent(printf %s (string replace -r '^.*? │ ' '' -- {} | string collect) | $_clip_cmd)+abort" \
    --header (_keys_style '`enter` insert · `tab` multiselect · `ctrl-/` preview · `ctrl-y` copy')

# Key bindings. The plugin installed its defaults when 03-fisher-path.fish sourced its
# conf.d; disable them (an empty value per option) and bind here through keys_bind so the
# keys and their descriptions live in one place. The shortcuts are the plugin's own.
# Every picker is --multi: Tab marks several, Enter takes them all.
if status is-interactive && functions -q fzf_configure_bindings
    fzf_configure_bindings --directory= --git_log= --git_status= --history= --processes= --variables=

    keys_bind ctrl-r _fzf_search_history 'Search shell history' \
        'Fuzzy-search your command history. `Enter` puts the chosen command on the' \
        'command line without running it. `Tab` selects and deselects; with a selection,' \
        'Enter inserts the selected commands. The preview shows the highlighted command' \
        'in full.' \
        '' \
        'Inside the picker:' \
        '  `ctrl-/`  toggle the preview' \
        '  `ctrl-y`  copy the command to the clipboard and close'

    keys_bind ctrl-alt-f _fzf_search_directory 'Find a file or directory' \
        'Fuzzy-find files and directories below the current one, hidden files' \
        'included and .git excluded, and insert the chosen paths at the cursor.' \
        '`Tab` selects several. Files preview with bat, directories as an eza tree.' \
        '' \
        'Inside the picker:' \
        '  `ctrl-/`           cycle the preview: bottom, hidden, right' \
        '  `ctrl-d` `ctrl-u`  page the preview down / up'

    keys_bind ctrl-alt-l _fzf_search_git_log 'Search git log' \
        'Fuzzy-search the git log, previewing each commit as a diff, and insert' \
        'the chosen hash at the cursor. `Tab` selects several.'

    keys_bind ctrl-alt-s _fzf_search_git_status 'Search changed files' \
        'Fuzzy-search the changed files in the working tree, previewing the diff,' \
        'and insert the chosen paths at the cursor. `Tab` selects several.'

    keys_bind ctrl-alt-p _fzf_search_processes 'Search running processes' \
        'Fuzzy-search running processes and insert the chosen PID at the cursor,' \
        'ready for kill or anything else that takes a pid. `Tab` selects several.'

    # The plugin's own command string: variables are captured before the picker runs.
    keys_bind ctrl-v $_fzf_search_vars_command 'Search shell variables' \
        'Fuzzy-search shell variables, previewing their current values, and' \
        'insert the chosen name at the cursor. `Tab` selects several.'
end

# fzf's own shell integration, for the two widgets fzf.fish has no equivalent of: ctrl-t
# (files, like ctrl-alt-f but rooted at the token under the cursor) and alt-c (cd). Only
# its key-bindings section is sourced; the completion section would also rebind shift-tab.
# Empty FZF_*_COMMAND values stop it binding any keys itself (it would take ctrl-r too);
# the widgets fall back to fzf's built-in walker either way, so nothing else changes.
if status is-interactive && type -q fzf
    set -g FZF_CTRL_R_COMMAND ''
    set -g FZF_CTRL_T_COMMAND ''
    set -g FZF_ALT_C_COMMAND ''
    fzf --fish | sed -n '/^### key-bindings.fish ###$/,/^### end: key-bindings.fish ###$/p' | source

    keys_bind ctrl-t fzf-file-widget 'Insert a file or directory path' \
        'Walk files and directories below the current one, hidden included, and' \
        'insert the chosen paths at the cursor. `Tab` selects several. If the token' \
        'under the cursor is a directory the walk starts there; otherwise it becomes' \
        'the initial query. `ctrl-alt-f` does the same job with previews.'

    keys_bind alt-c fzf-cd-widget 'Change directory' \
        'Walk directories below the current one, hidden included, and cd into the' \
        'chosen one. If the token under the cursor is a directory the walk starts' \
        'there; otherwise it becomes the initial query.'
end
