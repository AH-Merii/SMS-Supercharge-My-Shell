# Source relative files using full path
source common.sh
source helper-funcs.sh

# Create a fresh log file
echo -e "Installation Log - $(date)" >"${INSTLOG}"

# Clear the screen
clear

# Let the user know that we will use sudo
echo -en "$CWR - " && color_text "${WARNING_C}" "This script will run some commands that require sudo. You will be prompted to enter your password."
echo -en "$CNT - " && color_text "${NOTE_C}" "If you are worried about entering your password then you may want to review the content of the script."
sleep 1

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
  stow_all_configs_to_home_dir || return 1
  return 0
else
  return 1
fi
