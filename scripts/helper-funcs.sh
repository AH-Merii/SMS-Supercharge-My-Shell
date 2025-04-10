#!/bin/bash

# Path to brew shellenv
BREW_PREFIX="/home/linuxbrew/.linuxbrew"
HOMEBREW_EVAL='eval "$('"$BREW_PREFIX"'/bin/brew shellenv)"'

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"
INSTLOG="install.log"

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif type lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$DISTRIB_ID | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    elif [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
    else
        DISTRO="unknown"
    fi
    echo $DISTRO
}

# Function that would show a progress bar to the user
show_progress() {
    while ps | grep $1 &> /dev/null; do
        echo -n "."
        sleep 2
    done
    echo -en "Done!\n"
    sleep 1
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
    echo -e "$CNT - Installing Homebrew dependencies."
    case $DISTRO in
        "ubuntu" | "debian" | "pop" | "elementary" | "linuxmint")
            echo -e "$CNT - Installing Homebrew dependencies for Debian/Ubuntu based system..."
            sudo apt-get update &>> $INSTLOG
            sudo apt-get install -y build-essential procps curl file git &>> $INSTLOG
            ;;
        "fedora" | "rhel" | "centos" | "almalinux" | "rocky")
            echo -e "$CNT - Installing Homebrew dependencies for Fedora/Red Hat based system..."
            sudo yum groupinstall -y 'Development Tools' &>> $INSTLOG
            sudo yum install -y procps-ng curl file git &>> $INSTLOG
            ;;
        "arch" | "manjaro" | "endeavouros")
            echo -e "$CNT - Installing Homebrew dependencies for Arch based system..."
            sudo pacman -S --needed --noconfirm base-devel procps-ng curl file git &>> $INSTLOG
            ;;
        *)
            echo -e "$CER - Unsupported Linux distribution: $DISTRO"
            echo -e "$CNT - Please install the following packages manually: build tools, procps, curl, file, git"
            exit 1
            ;;
    esac

    echo -e "$COK - All required Homebrew dependencies have been installed."
    return 0
}

# Function to install Homebrew if not found
install_brew_if_not_found() {
    if ! command -v brew &> /dev/null; then
        echo -en "$CNT - Installing Homebrew..."
        
        # Install Homebrew silently
        echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>> "$INSTLOG" &
        show_progress $!

        # Add Homebrew to PATH in shell config
        if [[ -f ~/.zshrc && ! $(grep "$HOMEBREW_EVAL" ~/.zshrc) ]]; then
            echo "$HOMEBREW_EVAL" >> ~/.zshrc
        fi
        if [[ -f ~/.bashrc && ! $(grep "$HOMEBREW_EVAL" ~/.bashrc) ]]; then
            echo "$HOMEBREW_EVAL" >> ~/.bashrc
        fi

        # Evaluate Homebrew in current shell
        if [[ -d "$BREW_PREFIX" ]]; then
            eval "$("$BREW_PREFIX/bin/brew" shellenv)"
        fi

        # Verify installation
        if command -v brew &> /dev/null; then
            echo -e "\n$CNT - Homebrew installed successfully."
        else
            echo -e "\n$CER - Homebrew installation failed."
            exit 1
        fi
    else
        echo -e "$CNT - Homebrew already installed."
    fi
}

# Function to install packages using Homebrew
install_brew_package() {
    if brew list $1 &> /dev/null; then
        echo -e "$COK - $1 is already installed."
    else
        echo -en "$CNT - Now installing $1 ."
        brew install $1 &>> $INSTLOG &
        show_progress $!
        
        if brew list $1 &> /dev/null; then
            echo -e "\e[1A\e[K$COK - $1 was installed."
        else
            echo -e "\e[1A\e[K$CER - $1 install failed, please check the install.log"
        fi
    fi
}

# Function to install font casks
install_font_cask() {
    if brew list --cask $1 &> /dev/null 2>&1; then
        echo -e "$COK - $1 font is already installed."
    else
        echo -en "$CNT - Now installing $1 font."
        # Make sure the font cask is tapped
        brew tap homebrew/cask-fonts &>> $INSTLOG
        brew install --cask $1 &>> $INSTLOG &
        show_progress $!
        
        # Check if it's installed
        if brew list --cask $1 &> /dev/null 2>&1; then
            echo -e "\e[1A\e[K$COK - $1 font was installed."
        else
            echo -e "\e[1A\e[K$CWR - $1 font install may have failed, check the install.log"
        fi
    fi
}
