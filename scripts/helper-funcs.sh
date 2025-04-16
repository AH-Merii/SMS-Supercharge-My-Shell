# Get absolute path to the directory this script is in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source relative files using full path
source "${SCRIPT_DIR}/common.sh"

# Helper function to color text
color_text() {
  local color="$1"
  local text="$2"
  echo -e "${color}${text}${RESET_C}"
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
add_homebrew_path_to_config() {
  local config_file="${1:-$HOME/.zshenv}"

  if [[ -f "$config_file" ]] && ! grep -q "$HOMEBREW_EVAL" "$config_file"; then
    echo "$HOMEBREW_EVAL" | cat - "$config_file" >temp && mv temp "$config_file" &&
      sleep 0.5 && echo -e "$COK - Added Homebrew to $config_file"
  else
    if [[ -f "$config_file" ]]; then
      sleep 0.5 && echo -e "$COK - Homebrew already in $config_file"
    else
      sleep 0.5 && echo -e "$CWR - Config file $config_file does not exist"
    fi
  fi

  return 0
}
# Function to install packages using Homebrew
install_homebrew_package() {
  if brew list "${1}" &>/dev/null; then
    echo -e "$COK - $1 is already installed."
  else
    echo -en "$CNT - Now installing $1"
    brew install "${1}" &>>"${INSTLOG}" &
    local install_pid=$!
    show_progress "$install_pid" "${1} was installed."
  fi
}

cleanup_homebrew_installation() {
  echo -en "$CNT - Cleaning up Homebrew installation..."
  brew cleanup &>>"${INSTLOG}" &
  install_pid=$!
  show_progress "${install_pid}" "Homebrew installation cleaned"
}

stow_all_configs_to_home_dir() {
  for dir in */; do
    conflicts=$(stow -nvt ~ "$dir" 2>&1 | grep 'neither a link nor a directory')

    if [[ -n $conflicts ]]; then
      echo "$conflicts" | while read -r line; do
        filepath=$(echo "$line" | awk -F' ' '{print $4}')
        echo -e "${CWR} - Conflict detected: $(color_text "${WARNING_C}" "${filepath}") already exists."
        while true; do
          echo -en "${CAC} - Would you like to (o)verwrite or (a)dopt? [o/a]: "
          read -r choice </dev/tty
          case "$choice" in
          [Oo]*)
            echo -e "${CCA}${CCA}${COK} - Overwrote $filepath..." && sleep 1
            rm -rf "$filepath"
            break
            ;;
          [Aa]*)
            echo -e "${CCA}${CCA}${COK} - Adopted existing $filepath." && sleep 1
            break
            ;;
          *)
            echo -e "${CAC} - Please enter either 'o' to overwrite or 'a' to adopt."
            ;;
          esac
        done
      done
    fi

    # Final stow call with --adopt, which only affects adopted files
    if ! stow --adopt -vt ~ "$dir" &>>"${INSTLOG}"; then
      echo -e "${CER} - Problem linking $dir, check $INSTLOG"
      return 1
    fi

    if ! stow -vt ~ "$dir" &>>"${INSTLOG}"; then
      echo -e "${CER} - Problem linking $dir, check $INSTLOG"
      return 1
    fi
  done
  echo -e "${COK} - Dotfiles Linked!"
}

ensure_shell_in_etc_shells() {
  local shell_path="$1"

  if [[ -z "$shell_path" || ! -x "$shell_path" ]]; then
    echo -e "${CER} - Invalid or non-executable shell path: $shell_path"
    return 1
  fi

  if grep -Fxq "$shell_path" /etc/shells &>>"${INSTLOG}"; then
    echo -e "${CCA}${COK} - $shell_path is already listed in /etc/shells"
  else
    echo -e "${CCA}${CNT} - Adding ${shell_path} to /etc/shells... " && sleep 1
    if echo "$shell_path" | sudo tee -a /etc/shells &>>"${INSTLOG}"; then
      echo -e "${CCA}${COK} - ${shell_path} added to /etc/shells."
    else
      echo -e "${CCA}${CER} - Unable to add ${shell_path} to /etc/shells."
      return 1
    fi
  fi
}

change_default_shell_to_zsh() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  ensure_shell_in_etc_shells "${zsh_path}" || return 1

  # Change the user's default shell if not already set
  if getent passwd "$USER" | cut -d: -f7 | grep -q "zsh"; then
    echo -e "${CNT} - Changing default shell to ZSH... " && sleep 1
    if usermod --shell "${zsh_path}" "$USER" &>>"$INSTLOG"; then
      echo -e "${CCA}${COK} - ZSH is now your default shell."
    else
      echo -e "${CCA}${CER} - Unable to set ZSH as your default shell."
      return 1
    fi
  else
    echo -e "${CCA}${COK} - ZSH is already your default shell."
  fi

  return 0
}

clean_dotfiles_from_homedir() {
  echo -en "${CAC} - Would you like to run Antidot (declutter your home directory)? (y,n) " && read -r ANTIDOT

  if [[ ${ANTIDOT} == "Y" || ${ANTIDOT} == "y" ]]; then
    echo -e "${CCA}${CNT} - Decluttering home directory..."

    if antidot update &>>"${INSTLOG}"; then
      echo -e "${CCA}${COK} - Antidot rules updated successfully." && sleep 1
      if antidot clean; then
        if grep -F 'eval "$(antidot init)"' "${ZDOTDIR}/.zshrc" &>>"${INSTLOG}"; then
          echo -e "${COK} - eval antidot init already present in .zshrc"
        else
          echo 'eval "$(antidot init)"' >>"$ZDOTDIR/.zshrc"
          echo -e "${COK} - Added antidot configuration to .zsrhc"
        fi

        if eval "$(antidot init)" &>>"${INSTLOG}"; then
          echo -e "${COK} - Home directory is now squeaky clean."
        else
          echo -e "${COK} - Failed to evaluate antidot init"
          return 1
        fi
      else
        echo -e "${CWR} - Antidot 'clean' failed. Check ${INSTLOG} for more info."
        return 1
      fi
    else
      echo -e "${CCA}${CWR} - Antidot 'update' failed. Skipping clean. Check ${INSTLOG} for more info."
      return 1
    fi

  else
    echo -e "${CCA}${CWR} - Skipping antidot cleanup."
    return 0
  fi
}
