#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/AH-Merii/SMS-Supercharge-My-Shell.git"
DEST_DIR="$HOME/.dotfiles"
INSTLOG="install.log"

# Color Codes
NOTE_C="\e[1;36m"
OK_C="\e[1;32m"
ERROR_C="\e[1;31m"
ATTENTION_C="\e[1;37m"
WARNING_C="\e[1;35m"
ACTION_C="\e[1;33m"

# Helper Actions
CCL="\e[2K\r"      # Clears entire current line
CCA="\e[1A\e[2K\r" # Move up 1 line, then clear that line
RESET_C="\e[0m"

# Colored Info
CNT="[${NOTE_C}NOTE${RESET_C}]"
COK="[${OK_C}OK${RESET_C}]"
CER="[${ERROR_C}ERROR${RESET_C}]"
CAT="[${ATTENTION_C}ATTENTION${RESET_C}]"
CWR="[${WARNING_C}WARNING${RESET_C}]"
CAC="[${ACTION_C}ACTION${RESET_C}]"

clear

# Create a fresh log file
echo -e "Installation Log - $(date)" >"${INSTLOG}"

# Function that would show a progress bar to the user
show_progress() {
  local pid=$1
  local message="$2"
  local delay=0.1
  local spinstr='.oO0@0Oo.'

  # Default types
  local notification_type="${3:-$COK}" # Success color/style
  local clear_type="${4:-$CCL}"        # Line clearing style

  # Spinner while process is running
  while kill -0 "${pid}" 2>/dev/null; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done

  # Wait for the process and get exit code
  wait "$pid"
  local exit_status=$?

  if [[ $exit_status ]]; then
    echo -e "${clear_type}${notification_type} - $message"
  else
    echo -e " - ${CER} ${CROSS} (failed with code $exit_status) ${CROSS}"
  fi
}

# Function to detect the Linux distribution
detect_distro() {
  if [ -f /etc/os-release ]; then
    # shellcheck source=/etc/os-release
    . /etc/os-release
    DISTRO=$ID
  elif type lsb_release >/dev/null 2>&1; then
    DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
  elif [ -f /etc/lsb-release ]; then
    # shellcheck source=/etc/lsb-release
    . /etc/lsb-release
    DISTRO=$(echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]')
  elif [ -f /etc/arch-release ]; then
    DISTRO="arch"
  elif [ -f /etc/fedora-release ]; then
    DISTRO="fedora"
  else
    DISTRO="unknown"
  fi
  echo "$DISTRO"
}

install_system_dependencies() {
  DISTRO=$(detect_distro)
  echo -e "$CNT - Detected Linux distribution: $DISTRO"

  # Check if dependencies are already installed
  echo -en "$CNT - Installing System dependencies"
  case $DISTRO in
  "ubuntu" | "debian" | "pop" | "elementary" | "linuxmint")
    echo -en " for Debian/Ubuntu based system..."
    sudo apt-get update &>>"$INSTLOG" &&
      sudo apt-get install -y build-essential procps curl file git &>>"$INSTLOG" &
    local install_pid=$!
    ;;
  "fedora" | "rhel" | "centos" | "almalinux" | "rocky")
    echo -en " for Fedora/Red Hat based system..."
    sudo yum groupinstall -y 'Development Tools' &>>"$INSTLOG" &&
      sudo yum install -y procps-ng curl file git &>>"$INSTLOG" &
    local install_pid=$!
    ;;
  "arch" | "manjaro" | "endeavouros")
    echo -en " for Arch based system..."
    sudo pacman -Sy --needed --noconfirm base-devel procps-ng curl file git &>>"$INSTLOG" &
    local install_pid=$!
    ;;
  *)
    echo -e "${CCA}${CER} - Unsupported Linux distribution: ${DISTRO}"
    echo -e "${CAT} - Please install the following packages manually: build tools, procps, curl, file, git"
    exit 1
    ;;
  esac

  show_progress "${install_pid}" "All System dependencies installed successfully"
  return 0
}

echo -e "${CWR} - ${WARNING_C}This script will run some commands that require sudo. You will be prompted to enter your password.${RESET_C}"
echo -e "${CNT} - ${NOTE_C}If you are worried about entering your password then you may want to review the content of the script.${RESET_C}"
sleep 1

# Give the user an option to return out
echo -en "${CAC} - Would you like to continue with the install (y,n) " && read -r CONTINST
if [[ ${CONTINST} == "Y" || ${CONTINST} == "y" ]]; then
  echo -e "${CNT} - Setup starting..."
  if sudo -v; then
    echo -e "${CCL}${COK} - Login Succeeded"
  else
    echo -e "${CCA}${CER} - Failed to Login"
    return 1
  fi
else
  echo -e "${CNT} - This script will now exit, no changes were made to your system."
  exit 1
fi

install_system_dependencies

# Clnoe repo
echo -e "${CNT} - Cloning dotfiles to ${DEST_DIR}"
if [ -d "${DEST_DIR}" ]; then
  echo -e "${CCA}${CNT} - ${DEST_DIR} already exists. Pulling latest changes."
  git -C "${DEST_DIR}" pull ||
    { echo -e "${CCA}${CER} - Unable to pull latest changes, check $INSTLOG for more information." &&
      exit 1; }
  echo -e "${CCA}${COK} - Pulled latest changes."
else
  git clone "${REPO_URL}" "${DEST_DIR}" ||
    { echo "${CCA}${CER} - Unable to clone repo, check $INSTLOG for more information." &&
      exit 1; }
  echo -e "${CCA}${COK} - Cloned repo to ${DEST_DIR}."
fi

echo -e "${CNT} - Changing dir to ${DEST_DIR}/install"
# Run the main setup script
cd "${DEST_DIR}/install" || {
  echo "${CCA}${CER} - Failed to cd into ${DEST_DIR}/install"
  exit 1
}
echo -e "${CCA}${COK} - Moved to $(pwd)"

bash setup.sh
