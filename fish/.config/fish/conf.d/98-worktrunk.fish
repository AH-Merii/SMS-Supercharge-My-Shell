# Worktrunk shell integration (lets `wt switch` change the shell's directory)
if command -v wt >/dev/null
    wt config shell init fish | source
end
