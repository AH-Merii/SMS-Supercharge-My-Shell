# Get absolute path to the directory this script is in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source relative files using full path
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/helper-funcs.sh"

# Create a fresh log file
echo -e "Installation Log - $(date)" >"${INSTLOG}"

# Clear the screen
clear

# Let the user know that we will use sudo
echo -en "$CWR - " && color_text "${WARNING_C}" "This script will run some commands that require sudo. You will be prompted to enter your password."
echo -en "$CNT - " && color_text "${NOTE_C}" "If you are worried about entering your password then you may want to review the content of the script."
sleep 1

# Give the user an option to return out
echo -en "${CAC} - Would you like to continue with the install (y,n) " && read -r CONTINST
if [[ $CONTINST == "Y" || $CONTINST == "y" ]]; then
  echo -e "$CNT - Setup starting..."
  if sudo -v; then
    echo -e "${CCL}${COK} - Login Succeeded"
  else
    echo -e "${CCA}${CER} - Failed to Login"
    return 1
  fi
else
  echo -e "$CNT - This script will now exit, no changes were made to your system."
  exit 1
fi

# Install Homebrew dependencies and Homebrew itself
install_homebrew_dependencies &&
  install_homebrew

# Install packages
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install the packages? (y,n) ' INST

if [[ $INST == "Y" || $INST == "y" ]]; then
  # Install all brew packages
  echo -e "$CNT - Installing packages, this may take a while..."
  for PACKAGE in "${BREW_PACKAGES[@]}"; do
    install_homebrew_package "${PACKAGE}"
  done

  # Cleanup
  echo -e "$CNT - Cleaning up Homebrew installation..."
  brew cleanup &>>"${INSTLOG}" && echo -e "$CCA$COK - Homebrew installation cleaned"
fi

# Copy Config Files
WARN_USER=$(color_text "$WARNING_C" " any existing duplicate config files may be overwritten!")
echo -en "$CAC - Would you like to copy config files? ${WARN_USER} (y,n) " && read -r CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
  if stow_all_configs_to_home_dir; then
    echo -e "${CCL}${COK} Dotfiles Linked!"
  else
    echo -e "${CCL}${CER} - Error encountered when creating symlinks to dotfiles. Check $INSTLOG for more details"
    return 1
  fi
fi

return 0
