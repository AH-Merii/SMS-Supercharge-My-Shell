# Source relative files using full path
source common.sh
source helper-funcs.sh

# Create a fresh log file
echo -e "Installation Log - $(date)" >"${INSTLOG}"

# Install Homebrew dependencies and Homebrew itself
install_homebrew

# Install packages
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install the packages? (y,n) ' INST

if [[ $INST == "Y" || $INST == "y" ]]; then
  # Install all brew packages
  echo -e "$CNT - Installing packages, this may take a while..."
  for PACKAGE in "${BREW_PACKAGES[@]}"; do
    install_homebrew_package "${PACKAGE}"
  done

  cleanup_homebrew_installation
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
