function _sesh_search --description "Search and connect to tmux sessions via sesh and fzf."
    # Use fzf-tmux popup when inside tmux, plain fzf otherwise
    if set -q TMUX
        set -f fzf_cmd fzf-tmux -p 80%,70%
    else
        set -f fzf_cmd fzf --height=70%
    end

    set -f result (
        sesh list --icons | $fzf_cmd \
            --no-sort --ansi \
            --border-label " sesh " \
            --prompt "⚡  " \
            --header " ^a  All  ^t  Tmux  ^g 󰣖 Configs  ^x 󰫫 Zoxide  ^f  Dirs  ^d 󱓈 Kill Session" \
            --bind "tab:down,btab:up" \
            --bind "ctrl-a:change-prompt(  )+reload(sesh list --icons)" \
            --bind "ctrl-t:change-prompt(  )+reload(sesh list -t --icons)" \
            --bind "ctrl-g:change-prompt(󰣖  )+reload(sesh list -c --icons)" \
            --bind "ctrl-x:change-prompt(󰫫  )+reload(sesh list -z --icons)" \
            --bind "ctrl-f:change-prompt(  )+reload(fd -H -d 2 -t d -E .Trash . ~)" \
            --bind "ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡ )+reload(sesh list --icons)" \
            --preview-window "right:55%" \
            --preview "sesh preview {}"
    )

    if test $status -eq 0 && test -n "$result"
        sesh connect "$result"
    end

    commandline --function repaint
end
