#!/bin/bash

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

    # Default type is COK, can be overridden
    local notification_type="${3:-$COK}"
    local clear_type="${4:-$CCA}" # by default move one line up and clear

    while kill -0 "${pid}" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done

    # Clear the line above and reprint it with COK
    echo -e "${clear_type}${notification_type} - $message"
}

# Function that only evaluates if the command exists
maybe_eval() {
    command -v "$1" >/dev/null || return
    eval "$("$@")"
}

# Function to install Homebrew dependencies based on the detected distro
install_brew_dependencies() {
    DISTRO=$(detect_distro)
    echo -e "$CNT - Detected Linux distribution: $DISTRO"

    # Check if dependencies are already installed
    echo -en "$CNT - Installing Homebrew dependencies"
    case $DISTRO in
    "ubuntu" | "debian" | "pop" | "elementary" | "linuxmint")
        echo -en " for Debian/Ubuntu based system..."
        sudo apt-get update &>>$INSTLOG &
        local update_pid=$!
        sudo apt-get install -y build-essential procps curl file git &>>$INSTLOG &
        local install_pid=$!
        ;;
    "fedora" | "rhel" | "centos" | "almalinux" | "rocky")
        echo -e " for Fedora/Red Hat based system..."
        sudo yum groupinstall -y 'Development Tools' &>>$INSTLOG &
        local update_pid=$!
        sudo yum install -y procps-ng curl file git &>>$INSTLOG &
        local install_pid=$!
        ;;
    "arch" | "manjaro" | "endeavouros")
        echo -e " for Arch based system..."
        sudo pacman -Sy --needed --noconfirm base-devel procps-ng curl file git &>>$INSTLOG &
        local install_pid=$!
        ;;
    *)
        echo -e "$CCA"
        echo -e "$CER - Unsupported Linux distribution: $DISTRO"
        echo -e "$CAT - Please install the following packages manually: build tools, procps, curl, file, git"
        exit 1
        ;;
    esac

    # show_progress to display the completion message after each of the background task finishes, only show if defined
    [[ -n "${update_pid}" ]] && show_progress "${update_pid}" "Package list updated successfully" "$CNT" "$CCL"
    [[ -n "${install_pid}" ]] && show_progress "${install_pid}" "All Homebrew dependencies installed successfully"
    return 0
}

# Function to install Homebrew if not found
install_brew_if_not_found() {
    if ! command -v brew &>/dev/null; then
        echo -en "$CNT - Installing Homebrew..."

        # Install Homebrew
        echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>>"$INSTLOG" &
        local install_pid=$!

        # Show progress until the installation finishes
        sleep 1 && show_progress $install_pid "Successfully installed Homebrew"

    else
        sleep 1 && echo -e "$CCA$COK - Homebrew already installed."
    fi

    # Add Homebrew to PATH in shell config
    if [[ -f ~/.zshenv ]] && ! grep -q "$HOMEBREW_EVAL" ~/.zshenv; then
        # Add Homebrew Path at the beginning of the file
        echo "$HOMEBREW_EVAL" | cat - ~/.zshenv >temp && mv temp ~/.zshenv &&
            sleep 0.5 && echo -e "$COK - Added Homebrew to ~/.zshenv"

    else
        sleep 0.5 && echo -e "$COK - Homebrew already in ~/.zshenv"
    fi
    if [[ -f ~/.bsahrc ]] && ! grep -q "$HOMEBREW_EVAL" ~/.bashrc; then
        echo "$HOMEBREW_EVAL" | cat - ~/.bashrc >temp && mv temp ~/.bashrc &&
            sleep 0.5 && echo -e "$COK - Added Homebrew to ~/.bashrc"
    else
        sleep 0.5 && echo -e "$COK - Homebrew already in ~/.bashrc"
    fi

    # Evaluate Homebrew in current shell
    if [[ -d "$BREW_PREFIX" ]]; then
        eval "$("$BREW_PREFIX/bin/brew" shellenv)"
    fi
}

# Function to install packages using Homebrew
install_brew_package() {
    if brew list "${1}" &>/dev/null; then
        echo -e "$COK - $1 is already installed."
    else
        echo -en "$CNT - Now installing $1"
        brew install "${1}" &>>${INSTLOG} &
        local install_pid=$!
        show_progress "$install_pid" "Now installing ${1}" "$CNT" "$CCL"

        if brew list "${1}" &>/dev/null; then
            echo -e "$CCA$COK - ${1} was installed."
        else
            echo -e "$CCA$CER - ${1} install failed, please check the install.log"
        fi
    fi
}

stow_overwrite() {
    local target_dir="${2:-$HOME}"
    local packages="${1:-*/}"

    # Get a list of all files that would be stowed
    local files
    files=$(find "${packages}" -type f | sed "s|^[^/]*/||")

    echo -e "$CNT - Creating config files symbolic links using stow..." && sleep 1
    # Remove any existing files in the target directory
    for file in $files; do
        if [ -f "${target_dir}/${file}" ] && [ ! -L "${target_dir}/${file}" ]; then
            echo -en "${CAC} Found existing file: ${target_dir}/${file}"
            read -p "      Overwrite? (y/n): " choice

            case "$choice" in
            y | Y | yes | YES)
                echo -e "${CCA}${COK} Overwriting: ${target_dir}/${file}"
                rm "${target_dir}/${file}"
                ;;
            *)
                echo -e "${CNT} Skipping: ${target_dir}/${file}"
                ;;
            esac
        fi
    done

    # Now run stow
    stow "${packages}" -t "${target_dir}" && echo -e "${COK} - Dotfiles Linked!"

    echo "Done!"
}
