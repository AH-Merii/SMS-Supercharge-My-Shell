# Zoxide initialization. Interactive only: see config.fish for why.
if status is-interactive && command -v zoxide >/dev/null
    zoxide init fish | source
end
