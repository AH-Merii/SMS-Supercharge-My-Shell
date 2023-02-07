#!/bin/bash

NIX_PACKAGES_FILE="programs/nix-packages.txt"

# check and install any updates
echo "Updating packages"
sudo apt -y update
sudo apt -y upgrade

# check if nix is installed on the system
if ! (which nix); then 
  # install nix package manager
  echo "Installing Nix package manager"
  curl -L https://nixos.org/nix/install | sh
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

# simlink scripts file
ln -s scripts $ZDOTDIR/scripts

# install tools programming languages and editors
chmod +x install/tools.sh
./install/tools.sh

# install helix editor language server protocols 
chmod +x install/helix-lsp.sh
./install/helix-lsp.sh

# empty /tmp dir
sudo find /tmp/* -exec rm -rf {} + 
