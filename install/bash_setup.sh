# Source relative files using full path
source common.sh
source helper-funcs.sh

# Distro detection
get_distro() {
  if command -v pacman &>/dev/null; then
    echo "arch"
  elif command -v apt &>/dev/null; then
    echo "debian"
  elif [ -f /etc/os-release ]; then
    . /etc/os-release
    case "${ID}" in
      arch|manjaro|endeavouros|garuda|artix)
        echo "arch"
        ;;
      debian|ubuntu|mint|pop|elementary|linuxmint|zorin)
        echo "debian"
        ;;
      *)
        echo "unknown"
        ;;
    esac
  else
    echo "unknown"
  fi
}

DISTRO=$(get_distro)

install_linux_packages() {
  case "$DISTRO" in
    arch)
      echo -e "$CNT - Installing packages via pacman..."
      sudo pacman -S --needed --noconfirm "${@}"
      ;;
    debian)
      echo -e "$CNT - Installing packages via apt..."
      sudo apt update
      sudo apt install -y "${@}"
      ;;
    *)
      echo -e "${CER} - Unsupported distribution: $DISTRO"
      exit 1
      ;;
  esac
}

# Create a fresh log file
echo -e "Installation Log - $(date)" >"${INSTLOG}"

# Install packages
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install the packages? (y,n) ' INST

if [[ $INST == "Y" || $INST == "y" ]]; then
  # Install all brew packages
  echo -e "$CNT - Installing packages, this may take a while..."
  for PACKAGE in "${BREW_PACKAGES[@]}"; do
    install_linux_packages "${PACKAGE}"
  done

  if [[ "$DISTRO" == "unknown" ]]; then
    install_homebrew
    cleanup_homebrew_installation
  fi
fi

# Copy Config Files
WARN_USER=$(color_text "$WARNING_C" "Any existing duplicate config files may be overwritten!")
echo -en "$CAC - Would you like to copy config files? ${WARN_USER} (y,n) " && read -r CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
  cd .. || echo -e "${CER} - Unable to change reach root dir in dotfiles."
  stow_all_configs_to_home_dir || return 1
  cd "install/" || echo -e "${CER} - Unable to change reach install dir."
  return 0
else
  return 1
fi
