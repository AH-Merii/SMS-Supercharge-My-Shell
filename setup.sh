#!/bin/bash

NIX_PACKAGES_FILE="programs/nix-packages.txddt"

# check and install any updates
echo "Updating packages"
sudo apt -y update
sudo apt -y upgrade

# install nix package 
echo "Installing Nix package manager"
curl -L https://nixos.org/nix/install | sh

echo "Updating Nix packages"
Nix-channel --update

# check if file containing list of packages exists
if [ -s $NIX_PACKAGES_FILE ]; then
  echo "Downloading Nix packages from $NIX_PACKAGES_FILE"
  echo "Installing the following packages:"
  cat $NIX_PACKAGES_FILE
  Nix-env -iA $(grep -o '^[^#]*' $NIX_PACKAGES_FILE | tr '\n' ' ')
else # exit if package file does not exist
  echo $NIX_PACKAGES_FILE is empty or does not exist
  exit 1
fi

# change default shell to zsh
[[ -s /usr/bin/zsh ]] && chsh -s /usr/bin/zsh || echo zsh not found

# install tools programming languages and editors
chmod +x install/tools.sh
./install/tools.sh

# install helix editor language server protocols 
chmod +x install/helix-lsp.sh
./install/helix-lsp.sh

# empty /tmp dir
sudo find /tmp/* -exec rm -rf {} + 
