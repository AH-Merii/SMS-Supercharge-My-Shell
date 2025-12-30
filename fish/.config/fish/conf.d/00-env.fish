# Environment variables

# Editor
set -gx EDITOR nvim
set -gx SUDOEDITOR nvim
set -gx VISUAL nvim

# XDG Base Directories
set -gx XDG_CONFIG_HOME ~/.config
set -gx XDG_CACHE_HOME ~/.cache
set -gx XDG_DATA_HOME ~/.local/share
set -gx XDG_STATE_HOME ~/.local/state
set -gx XDG_PROJECTS_DIR ~/Projects

# Create XDG directories
mkdir -p $XDG_CONFIG_HOME $XDG_CACHE_HOME $XDG_DATA_HOME $XDG_STATE_HOME
mkdir -p $XDG_DATA_HOME/fish $XDG_CACHE_HOME/repos

# PATH additions
fish_add_path $HOME/.local/bin
fish_add_path $XDG_DATA_HOME/go/bin
fish_add_path $XDG_DATA_HOME/nvim/mason/bin

# XDG DATA
set -gx PYENV_ROOT $XDG_DATA_HOME/pyenv
set -gx CLAUDE_CONFIG_DIR $XDG_CONFIG_HOME/claude

# XDG CACHE
set -gx TEXMFVAR $XDG_CACHE_HOME/texlive/texmf-var

# Custom
set -gx GNUPGHOME $XDG_DATA_HOME/gnupg
set -gx REPO_HOME $XDG_CACHE_HOME/repos

# AWS CLI
set -gx AWS_CLI_AUTO_PROMPT on-partial

# Man pager
set -gx MANPAGER 'nvim +Man!'
