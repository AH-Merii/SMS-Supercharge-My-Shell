# Path to brew shellenv
BREW_PREFIX="/home/linuxbrew/.linuxbrew"
HOMEBREW_EVAL="eval \$($BREW_PREFIX/bin/brew shellenv)"

# Color Codes
NOTE_C="\e[1;36m"
OK_C="\e[1;32m"
ERROR_C="\e[1;31m"
ATTENTION_C="\e[1;37m"
WARNING_C="\e[1;35m"
ACTION_C="\e[1;33m"

# Helper Actions
CCL="\r\e[2K\r"      # Clears entire current line
CCA="\r\e[1A\e[2K\r" # Move up 1 line, then clear that line
RESET_C="\e[0m"

# Colored Info
CNT="\r[${NOTE_C}NOTE${RESET_C}]"
COK="\r[${OK_C}OK${RESET_C}]"
CER="\r[${ERROR_C}ERROR${RESET_C}]"
CAT="\r[${ATTENTION_C}ATTENTION${RESET_C}]"
CWR="\r[${WARNING_C}WARNING${RESET_C}]"
CAC="\r[${ACTION_C}ACTION${RESET_C}]"

# ASCII Icons
CROSS="\u274C"

# Tools to install via Homebrew
BREW_PACKAGES=(
  # Development tools
  gcc
  neovim
  lazygit
  bat
  fzf
  eza
  git-delta
  tmux
  csvlens
  ripgrep
  stow
  curl
  wget
  jq
  htop
  bottom
  unzip
  openssh
  zoxide

  # misc
  zsh
  pyenv
  pipx
  pixi
  uv
  go
  rust
  node
  antidote
  doron-cohen/tap/antidot
  # wl-clipboard
  xclip

  # Fonts and Visual
  # font-fira-code-nerd-font
  # font-inter

  # Terminal emulators
  # kitty
)
