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
    alias tree "eza --icons=always --tree"
end

# Shortcuts
abbr --add b prevd

# Fish config access
alias sfrc "source ~/.config/fish/config.fish"
alias efrc "nvim ~/.config/fish/config.fish"
alias cfrc "cat ~/.config/fish/config.fish"

# lazygit
abbr --add lg lazygit

# fzf preview helpers
if command -v fzf >/dev/null
    alias xp "fzf --exact --preview='bat --color=always --style=numbers {}' --bind page-up:preview-up,ctrl-u:preview-page-up,page-down:preview-down,ctrl-d:preview-page-down"
    alias fp "fzf --preview='bat --color=always --style=numbers {}' --bind page-up:preview-up,ctrl-u:preview-page-up,page-down:preview-down,ctrl-d:preview-page-down"
    # Hidden file search + preview
    alias xph "fd --hidden --exclude '.git' | xp"
    alias fph "fd --hidden --exclude '.git' | fp"
end

# pandoc
alias pandoc "pandoc --pdf-engine=typst"
