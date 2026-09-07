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

if status is-interactive
    mkdir -p \
        $XDG_CONFIG_HOME \
        $XDG_CACHE_HOME \
        $XDG_DATA_HOME \
        $XDG_STATE_HOME \
        $XDG_DATA_HOME/fish \
        $XDG_CACHE_HOME/repos
end

# PATH additions. -g keeps them in a global fish_user_paths that is rebuilt
# every startup; without it fish_add_path persists them as a universal
# variable, so removing a line here would never remove the directory.
fish_add_path -g $HOME/.local/bin
fish_add_path -g $HOME/.cargo/bin
fish_add_path -g $XDG_DATA_HOME/go/bin
# Mason's copies of shellcheck, shfmt etc. go last so the mise-managed ones win.
fish_add_path -g --append $XDG_DATA_HOME/nvim/mason/bin

# XDG DATA
set -gx CLAUDE_CONFIG_DIR $XDG_CONFIG_HOME/claude

# XDG CACHE
set -gx TEXMFVAR $XDG_CACHE_HOME/texlive/texmf-var

# Custom
set -gx GNUPGHOME $XDG_DATA_HOME/gnupg
# gpg does not create a GNUPGHOME it is pointed at, unlike ~/.gnupg
test -d $GNUPGHOME; or mkdir -p -m 700 $GNUPGHOME
set -gx REPO_HOME $XDG_CACHE_HOME/repos
set -gx STARSHIP_CONFIG $XDG_CONFIG_HOME/starship/starship.toml

# AWS CLI
set -gx AWS_CLI_AUTO_PROMPT on-partial

# Man pager
set -gx MANPAGER 'nvim +Man!'

# macOS on Apple Silicon: let tools that dlopen Homebrew libraries (Cairo, etc.)
# find /opt/homebrew/lib. The fallback path is only searched after a binary's own
# library paths; DYLD_LIBRARY_PATH would be searched first and inject Homebrew
# libs into every process. Setting the variable replaces dyld's default fallback
# list (/usr/local/lib:/usr/lib), so that is kept, which is also why Intel
# Homebrew (/usr/local/lib) needs nothing here.
if test "$OS_KIND" = macos; and test -d /opt/homebrew/lib
    set -q DYLD_FALLBACK_LIBRARY_PATH; or set -gx DYLD_FALLBACK_LIBRARY_PATH /usr/local/lib /usr/lib
    contains /opt/homebrew/lib $DYLD_FALLBACK_LIBRARY_PATH
    or set -gx DYLD_FALLBACK_LIBRARY_PATH /opt/homebrew/lib $DYLD_FALLBACK_LIBRARY_PATH
end
