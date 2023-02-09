#!/bin/bash

# NOTE: the order of operations in the script matters, changing the order of the commands below may break the script 

# file containing nix packages to install
NIX_PACKAGES_FILE="$(pwd)/programs/nix-packages.txt"

# check and install any updates
echo "Updating packages"
sudo apt -y update
sudo apt -y upgrade
sudo apt install build-essential zsh

# check if nix is installed on the system
if ! (which nix); then 
  # install nix package manager using helper script
  ./install/nix.sh
  source $HOME/.nix-profile/etc/profile.d/nix.sh
fi

echo "Updating Nix packages"
nix-channel --update

# check if file containing list of packages exists
if [ -s $NIX_PACKAGES_FILE ]; then
  # allow the installation of proprietary packages
  export NIXPKGS_ALLOW_UNFREE=1
  export NIXPKGS_ALLOW_BROKEN=1
  echo "Downloading Nix packages from $NIX_PACKAGES_FILE"
  echo "Installing the following packages:"
  cat $NIX_PACKAGES_FILE
  # the command below adds "nixpkgs." to the start of each packages and removes all comments and newlines
  cat $NIX_PACKAGES_FILE | grep -o '^[^#]*' > /tmp/nix-packages.txt
  nix-env -iA $(sed 's/^/nixpkgs./' "/tmp/nix-packages.txt" | tr '\n' ' ') 
else # exit if package file does not exist
  echo $NIX_PACKAGES_FILE is empty or does not exist
  exit 1
fi

# change default shell to zsh
which zsh && chsh -s $(which zsh) || echo zsh not found

# add stowignore .git folder
[ ! -f .git/.stow-local-ignore ] && cp scripts/.stow-local-ignore .git/

# create symlinks to dotfiles using stow
stow */ -t ~ && echo -e "\033[32mSTOW COMPLETE\033[0m"

# export environment variables from .zshenv
[ -f ~/.zshenv ] && source ~/.zshenv && echo -e "\033[32m.zshenv SOURCED\033[0m" 

# source helper-funcs.sh
source $ZDOTDIR/scripts/helper-funcs.sh && echo -e "\033[32mSOURCED HELPER FUNCS\033[0m"

# install tools programming languages and editors
./install/tools.sh && echo -e "\033[32m TOOLS INSTALLED\033[0m"

# install helix editor language server protocols 
./install/helix-lsp.sh && echo -e "\033[32m HELIX TEXT EDITOR INSTALLED\033[0m"

# create a hard link for zsh-extensions
ln programs/zsh-extensions.txt $ZDOTDIR

# source .zshrc
/usr/bin/env zsh 

# empty /tmp dir
sudo find /tmp/* -exec rm -rf {} + && echo -e "\033[36m SETUP COMPLETE, ENJOY YOUR NEW SUPERCHARGED DEVELOPER ENVIRONMENT!\033[0m" 
