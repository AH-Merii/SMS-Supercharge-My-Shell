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

# pandoc
abbr pandoc "pandoc --pdf-engine=typst"
