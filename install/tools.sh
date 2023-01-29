#!/bin/bash

# source scripts containing helper functions
source "../scripts/helper-funcs"

# default location for tools
TOOLS_HOME="${HOME}/tools"
mkdir -p "${TOOLS_HOME}"
pushd "${TOOLS_HOME}"

# install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# install go
version=$(curl https://go.dev/VERSION?m=text)
url=https://go.dev/dl/$version.linux-amd64.tar.gz
curl -Lo "go.tar.gz" $url
rm -rf "$HOME/.local/go" && tar -C "$HOME/.local/" -xzf "go.tar.gz"
mv usr/local/go/bin/go usr/local/bin 
 
# install helix editor
echo "Installing helix editor"
clone-repo git@github.com:helix-editor/helix.git
pushd helix
cargo install --locked --path helix-term
ln -s $PWD/runtime ~/.config/helix/runtime
popd

# install zap plugin manager
zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh)

# install starship
curl -sS https://starship.rs/install.sh | sh

# install binaries from repos
loop-apply install-latest-release "programs/binary-repos.txt"
