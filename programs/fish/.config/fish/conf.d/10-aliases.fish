# Aliases for fish shell

# Modern CLI replacements (using abbreviations for command expansion)
abbr --add cat bat
abbr --add diff delta
abbr --add grep rg

# eza (modern ls)
if command -v eza >/dev/null
    alias ls "eza --icons=always --group-directories-first"
    alias ll "eza --icons=always --group-directories-first -l --git"
    alias la "eza --icons=always --group-directories-first -la --git"
end

# Shortcuts
abbr --add b prevd
alias explorer "xdg-open . >/dev/null 2>&1 & disown"

# Fish config access
alias sfrc "source ~/.config/fish/config.fish"
alias efrc "nvim ~/.config/fish/config.fish"
alias cfrc "cat ~/.config/fish/config.fish"

# lazygit
abbr --add lg lazygit

# tuicr (review TUI) on the working tree
abbr --add gd "tuicr -w"

# pandoc
abbr pandoc "pandoc --pdf-engine=typst"

# `CMD --help` expands to the help piped through bat's Command Help syntax, which colours
# headings, options and placeholders the way the hints preview does; most tools print help
# plain, and the rest print it plain once stdout is a pipe. The 2>&1 catches the tools that
# put help on stderr, and --strip-ansi drops the colour of any tool that colours regardless
# (CLICOLOR_FORCE, say), since bat keeps foreign escape codes by default and they break
# its highlighting. Command-line only: abbreviations do not expand inside scripts.
abbr --add --position anywhere -- --help '--help 2>&1 | bat -plcmd-help --strip-ansi=always'
