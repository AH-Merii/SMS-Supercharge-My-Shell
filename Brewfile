# Homebrew packages for macOS and WSL. Not used on Arch (see pkglist/).
# Only what mise cannot install; CLI tools live in base/mise/.config/mise/config.toml.
#
#   brew bundle --file=Brewfile        # or: mise run deps

brew "git"
brew "stow"
brew "mise"
brew "fish"
# The mise tasks need bash 4+ and macOS ships 3.2. bootstrap.sh installs this before the
# first task runs; listing it here keeps it current afterwards.
brew "bash"
brew "tmux"
brew "gnupg"
brew "luarocks"
brew "wget"

if OS.mac?
  cask "ghostty"
  cask "karabiner-elements"
  cask "1password"
  cask "1password-cli"
  cask "font-fira-code-nerd-font"
end
