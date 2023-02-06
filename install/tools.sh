#!/bin/bash

# source scripts containing helper functions
source "scripts/helper-funcs"

# default location for tools
TOOLS_HOME="${XDG_DATA}/tools"
mkdir -p "${TOOLS_HOME}"
pushd "${TOOLS_HOME}"

# install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# install helix editor
echo "Installing helix editor"
clone-repo git@github.com:helix-editor/helix.git
pushd helix
cargo install --locked --path helix-term
ln -s $PWD/runtime ~/.config/helix/runtime
popd

# install zap plugin manager
zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh)
