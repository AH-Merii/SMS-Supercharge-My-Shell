#!/bin/sh

# check and install any updates
echo"Updating packages"
sudo apt -y update
sudo apt -y upgrade

# install packages
echo "Installing the following packages:"
cat packages.txt
xargs -a packages.txt | (yes | sudo apt install)

# install tools and programming languages
bash install/tools.sh

# install helix editor language server protocols 
bash install/helix-lsp.sh

# empty /tmp dir
sudo find /tmp/* -exec rm -rf {} + 
