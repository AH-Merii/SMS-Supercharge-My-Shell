#!/bin/bash

source common.sh && echo -e "$CNT - Sourced common vars"

# Helper function to color text
color_text() {
  local color="$1"
  local text="$2"
  echo -e "${color}${text}${RESET_C}"
}

INSTLOG="install.log"

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

# Function that would show a progress bar to the user
show_progress() {
  local pid=$1
  local message="$2"
  local delay=0.1
  local spinstr='|/-\'

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
    echo -e "${clear_type}${notification_type} $message"
  else
    echo -e "${CER} ${CROSS} (failed with code $exit_status) ${CROSS}"
  fi
}

# Function that only evaluates if the command exists
maybe_eval() {
  command -v "$1" >/dev/null || return
  eval "$("$@")"
}

# Function to install Homebrew dependencies based on the detected distro
install_homebrew_dependencies() {
  DISTRO=$(detect_distro)
  echo -e "$CNT - Detected Linux distribution: $DISTRO"

  # Check if dependencies are already installed
  echo -en "$CNT - Installing Homebrew dependencies"
  case $DISTRO in
  "ubuntu" | "debian" | "pop" | "elementary" | "linuxmint")
    echo -en " for Debian/Ubuntu based system..."
    sudo apt-get update &>>$INSTLOG &&
      sudo apt-get install -y build-essential procps curl file git &>>$INSTLOG &
    local install_pid=$!
    ;;
  "fedora" | "rhel" | "centos" | "almalinux" | "rocky")
    echo -en " for Fedora/Red Hat based system..."
    sudo yum groupinstall -y 'Development Tools' &>>$INSTLOG &&
      sudo yum install -y procps-ng curl file git &>>$INSTLOG &
    local install_pid=$!
    ;;
  "arch" | "manjaro" | "endeavouros")
    echo -en " for Arch based system..."
    sudo pacman -Sy --needed --noconfirm base-devel procps-ng curl file git &>>$INSTLOG &
    local install_pid=$!
    ;;
  *)
    echo -e "${CCA}${CER} - Unsupported Linux distribution: ${DISTRO}"
    echo -e "${CAT} - Please install the following packages manually: build tools, procps, curl, file, git"
    exit 1
    ;;
  esac

  show_progress "${install_pid}" "All Homebrew dependencies installed successfully"
  return 0
}

# Function to install Homebrew if not found
install_homebrew() {
  if [[ ! -x "${BREW_PREFIX}/bin/brew" ]]; then
    echo -en "$CNT - Installing Homebrew..."

    echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>>"$INSTLOG" &
    local install_pid=$!
    # Show progress until the installation finishes
    show_progress $install_pid "Successfully installed Homebrew"
  else
    echo -e "$COK - Homebrew already installed."
  fi

  # Evaluate Homebrew in current shell
  if [[ -d "$BREW_PREFIX" ]]; then
    eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  fi
}

# Function to add Homebrew to PATH in specified config files
add_homebrew_path_to_configs() {
  local config_files=("$@")

  # Default to ~/.zshenv and ~/.bashrc if no arguments provided
  if [ ${#config_files[@]} -eq 0 ]; then
    config_files=("$HOME/.zshenv" "$HOME/.bashrc")
  fi

  for config_file in "${config_files[@]}"; do
    if [[ -f "$config_file" ]] && ! grep -q "$HOMEBREW_EVAL" "$config_file"; then
      # Add Homebrew Path at the beginning of the file
      echo "$HOMEBREW_EVAL" | cat - "$config_file" >temp && mv temp "$config_file" &&
        sleep 0.5 && echo -e "$COK - Added Homebrew to $config_file"
    else
      if [[ -f "$config_file" ]]; then
        sleep 0.5 && echo -e "$COK - Homebrew already in $config_file"
      else
        sleep 0.5 && echo -e "$CWR - Config file $config_file does not exist"
      fi
    fi
  done
}

# Function to install packages using Homebrew
install_homebrew_package() {
  if brew list "${1}" &>/dev/null; then
    echo -e "$COK - $1 is already installed."
  else
    echo -en "$CNT - Now installing $1"
    brew install "${1}" &>>${INSTLOG} &
    local install_pid=$!
    show_progress "$install_pid" " - ${1} was installed."
  fi
}

stow_all() {
  stow */ -t "${target_dir}" &>>"${INSTLOG}" && echo -e "${COK} - Dotfiles Linked!" || echo "${ER} There was a problem linking your Dotfiles, check install.log for more info. ${CROSS}"
}
