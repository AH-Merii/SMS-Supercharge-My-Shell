#!/bin/sh
# Set up a machine end to end. Safe to re-run; every step converges.
#
#   fresh machine:      curl -fsSL https://raw.githubusercontent.com/AH-Merii/SMS-Supercharge-My-Shell/main/bootstrap.sh | sh
#   existing checkout:  ./bootstrap.sh
#
# 1. git, stow, fish, mise from the OS package manager (Homebrew on macOS and WSL)
# 2. clone to ~/SMS-Supercharge-My-Shell unless already running from a checkout
# 3. mise run setup  ->  deps, link, tools, plugins
set -eu

REPO=https://github.com/AH-Merii/SMS-Supercharge-My-Shell.git
DEST="$HOME/SMS-Supercharge-My-Shell"

# Running from inside a checkout (./bootstrap.sh)? Use it instead of cloning.
script_dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || script_dir=""
if [ -n "$script_dir" ] && [ -f "$script_dir/mise.toml" ]; then
  DEST=$script_dir
fi

os=$(uname -s)
wsl=0
if grep -qi microsoft /proc/version 2>/dev/null; then wsl=1; fi

if command -v pacman >/dev/null 2>&1; then
  sudo pacman -Syu --needed --noconfirm git stow fish mise
elif [ "$os" = Darwin ] || [ "$wsl" = 1 ]; then
  if [ "$os" = Darwin ]; then
    xcode-select -p >/dev/null 2>&1 || xcode-select --install
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y build-essential procps curl file git
  fi
  if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [ -x "$b" ]; then
      eval "$("$b" shellenv)"
      break
    fi
  done
  brew install git stow fish mise
else
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y curl git stow fish
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y curl git stow fish
  fi
  if ! command -v mise >/dev/null 2>&1; then
    curl -fsSL https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi
fi

if [ ! -d "$DEST/.git" ]; then
  git clone "$REPO" "$DEST"
fi
cd "$DEST"

mise trust --yes
mise run setup

echo
if [ "$(basename "$SHELL")" != fish ]; then
  echo "Make fish the login shell:  chsh -s \"\$(command -v fish)\""
  echo "On macOS add \$(command -v fish) to /etc/shells first."
fi
echo "Git identity and signing: run ggh (fish will remind you until it is set)."
