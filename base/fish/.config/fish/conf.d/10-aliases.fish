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
if test "$OS_KIND" = macos
    alias explorer "open ."
else
    alias explorer "xdg-open . >/dev/null 2>&1 & disown"
end

# Fish config access. conf.d only loads at startup, so re-sourcing config.fish
# would miss most of the config; start a fresh shell instead.
alias sfrc "exec fish"
alias efrc "nvim ~/.config/fish/config.fish"
alias cfrc "cat ~/.config/fish/config.fish"

# lazygit
abbr --add lg lazygit

# tuicr (review TUI) on the working tree
abbr --add gd "tuicr -w"

# pandoc
abbr pandoc "pandoc --pdf-engine=typst"
