if status is-interactive
    if not set -q TMUX
        type -q fastfetch; and fastfetch
    end
end
