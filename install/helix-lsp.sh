#!/bin/bash

# source helper functions
echo "Sourcing helper functions"
source $ZDOTDIR/scripts/helper-funcs.sh

BINARY_HOME=$HOME/.local/bin
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

echo "Installing Language Servers for Helix Editor:"

# Work in a throwaway temporary directory so as not to pollute the file system.
temporaryDirectory="/tmp/helix-editor-language-server-installer"
echo "creating temporary directory"
mkdir -p $temporaryDirectory
pushd $temporaryDirectory

# Bash
echo "  • Bash (bash-language-server)"
npm i -g bash-language-server

# HTML, JSON, JSON schema
echo "  • HTML, JSON, and JSON schema (vscode-langservers-extracted)"
npm i -g vscode-langservers-extracted

# JavaScript (via TypeScript)
echo "  • JavaScript (typescript, typescript-language-server)"
npm install -g typescript typescript-language-server

# Python
echo "  • Python (pylsp)"
sudo apt install python3-pylsp

# Terraform HCL
echo "  • Terraform (terraform-ls)"
sudo apt install gpg
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install terraform-ls

# Latex
echo "  • Latex (texlab)"
cargo install texlab

# Markdown
echo "  • Markdown (marksman)"
repo="artempyanykh/marksman"
release_url=$(curl -L "https://api.github.com/repos/$repo/releases/latest" | \
    jq -r ".assets[].browser_download_url" | \
    grep -Pi "linux")
curl -Lo "marksman" $release_url \
&& chmod +x marksman \
&& mv marksman "$HOME/.local/bin"

# TOML
echo "  • TOML (taplo)"
cargo install taplo-cli --locked --features lsp

# Go
echo "  • Go (gopls)"
go install golang.org/x/tools/gopls@latest

# Docker
echo "  • Docker (dockerfile-language-server-nodejs)"
npm install -g dockerfile-language-server-nodejs

# Rust
echo "  • Rust (rust-analyzer)"
rustup component add rust-analyzer

# Clean up.
popd
rm -rf "${temporaryDirectory}"

echo "Done."
