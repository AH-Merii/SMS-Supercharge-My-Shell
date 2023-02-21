#!/bin/bash

# source helper functions
source $ZDOTDIR/scripts/helper-funcs.sh

sudo apt update

# default location for tools
TOOLS_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/tools"
mkdir -p $TOOLS_HOME
pushd $TOOLS_HOME

# install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
source ~/.zshenv
nvm install node # install node package manager

# install helix editor
echo "Installing helix editor"
clone-repo git@github.com:helix-editor/helix.git
pushd helix
cargo install --locked --path helix-term
ln -s $PWD/runtime ~/.config/helix/runtime
popd

# install pip
sudo apt install python3-pip

# install virtualenv
pip install virtualenv

# install pyenv
curl -s -S -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash

# install zap plugin manager
zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh)
