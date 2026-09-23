# Worktrunk shell integration (lets `wt switch` change the shell's directory).
# Interactive only: see config.fish for why.
if status is-interactive && command -v wt >/dev/null
    wt config shell init fish | source
end
