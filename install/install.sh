#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/AH-Merii/SMS-Supercharge-My-Shell.git"
DEST_DIR="$HOME/.dotfiles"

# Colored Info
CNT="[${NOTE_C}NOTE${RESET_C}]"
COK="[${OK_C}OK${RESET_C}]"
CER="[${ERROR_C}ERROR${RESET_C}]"
CAT="[${ATTENTION_C}ATTENTION${RESET_C}]"
CWR="[${WARNING_C}WARNING${RESET_C}]"
CAC="[${ACTION_C}ACTION${RESET_C}]"
WARNING_C="\e[1;35m"
NOTE_C="\e[1;36m"
RESET_C="\e[0m"

# Create a fresh log file
echo -e "Installation Log - $(date)" >"${INSTLOG}"

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

echo -en "${CWR} - " && color_text "${WARNING_C}" "This script will run some commands that require sudo. You will be prompted to enter your password."
echo -en "${CNT} - " && color_text "${NOTE_C}" "If you are worried about entering your password then you may want to review the content of the script."
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
if [ -d "${DEST_DIR}" ]; then
  echo "${CNT} ${DEST_DIR} already exists. Pulling latest changes."
  git -C "${DEST_DIR}" pull ||
    echo "${CER} Unable to pull latest changes, check $INSTLOG for more information." &&
    exit 1
  echo "${COK} Pulled latest changes."
else
  git clone "${REPO_URL}" "${DEST_DIR}" ||
    echo "${CER} Unable to clone repo, check $INSTLOG for more information." &&
    exit 1
  echo "${COK} Cloned repo to ${DEST_DIR}."
fi

# Run the main setup script
cd "${DEST_DIR}"
bash scripts/setup.sh
