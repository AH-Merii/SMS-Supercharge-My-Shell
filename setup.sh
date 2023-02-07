#!/bin/bash

# NOTE: the order of operations in the script matters, changing the order of the commands below may break the script 

# file containing nix packages to install
NIX_PACKAGES_FILE="$(pwd)/programs/nix-packages.txt"

# check and install any updates
echo "Updating packages"
sudo apt -y update
sudo apt -y upgrade

# check if nix is installed on the system
if ! (which nix); then 
  echo -e "\033[31mError: An error occurred\033[0m" >&2
  echo -e "\033[31mnix is not installed on the system\033[0m" >&2
  echo -e "\033[36mrun ./install/nix.sh to install nix package manager\033[0m"
  echo -e "\033[36mrestart your terminal after installing nix\033[0m"
  echo -e "\033[36mre-run this script after you have restarted your terminal\033[0m" 
  exit 1
fi

echo "Updating Nix packages"
nix-channel --update

# check if file containing list of packages exists
if [ -s $NIX_PACKAGES_FILE ]; then
  echo "Downloading Nix packages from $NIX_PACKAGES_FILE"
  echo "Installing the following packages:"
  cat $NIX_PACKAGES_FILE
  # the command below adds "nixpkgs." to the start of each packages and removes all comments and newlines
  nix-env -iA $(sed 's/^/nixpkgs./' $NIX_PACKAGES_FILE | grep -o '^[^#]*' | tr '\n' ' ')
else # exit if package file does not exist
  echo $NIX_PACKAGES_FILE is empty or does not exist
  exit 1
fi

# change default shell to zsh
which zsh && chsh -s $(which zsh) || echo zsh not found

# create symlinks to dotfiles using stow
stow */

# simlink and source scripts file
ln -s scripts "$ZDOTDIR/scripts"
source "$ZDOTDIR/scripts"

# export environment variables from .zshenv
source "~/.zshenv"

# install tools programming languages and editors
chmod +x install/tools.sh
./install/tools.sh

# install helix editor language server protocols 
chmod +x install/helix-lsp.sh
./install/helix-lsp.sh

# source .zshrc
source "~/.zshrc"

# empty /tmp dir
sudo find /tmp/* -exec rm -rf {} + 
