#!/bin/bash

# Source helper functions
source scripts/helper-funcs.sh && echo -e "$CNT - Sourced helper functions"

# Create a fresh log file
echo -e "Installation Log - $(date)" >"${INSTLOG}"

# Tools to install via Homebrew
brew_packages=(
    # Development tools
    gcc
    neovim
    lazygit
    bat
    fzf
    eza
    git-delta
    tmux
    csvlens
    ripgrep
    stow
    curl
    wget
    jq
    htop
    bottom
    unzip
    openssh
    zoxide

    # misc
    zsh
    pyenv
    pipx
    pixi
    uv
    go
    rust
    node
    antidote
    doron-cohen/tap/antidot
    # wl-clipboard
    xclip

    # Fonts and Visual
    # font-fira-code-nerd-font
    # font-inter

    # Terminal emulators
    # kitty
)

# Clear the screen
clear

# Let the user know that we will use sudo
echo -en "$CWR - " && color_text "${WARNING_C}" "This script will run some commands that require sudo. You will be prompted to enter your password."
echo -en "$CNT - " && color_text "${NOTE_C}" "If you are worried about entering your password then you may want to review the content of the script."
sleep 1

# Give the user an option to exit out
echo -en "${CAC} - Would you like to continue with the install (y,n) " && read -r CONTINST
if [[ $CONTINST == "Y" || $CONTINST == "y" ]]; then
    echo -e "$CNT - Setup starting..."
    sudo touch /tmp/setup.tmp
else
    echo -e "$CNT - This script will now exit, no changes were made to your system."
    exit
fi

# Install Homebrew dependencies and Homebrew itself
install_brew_dependencies
install_brew_if_not_found

# Install packages
sleep 1 && read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install the packages? (y,n) ' INST

if [[ $INST == "Y" || $INST == "y" ]]; then
    # Install all brew packages
    echo -e "$CNT - Installing packages, this may take a while..."
    for PACKAGE in "${brew_packages[@]}"; do
        install_brew_package "${PACKAGE}"
    done

    # Cleanup
    echo -e "$CNT - Cleaning up Homebrew installation..." && sleep 1
    brew cleanup &>>"${INSTLOG}" && echo -e "$CCA$COK - Homebrew installation cleaned"
fi

# Copy Config Files
WARN_USER=$(color_text "$WARNING_C" " any existing duplicate config files will be overwritten!")
echo -en "$CAC - Would you like to copy config files? ${WARN_USER} (y,n) " && read -r CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
    # Create symlinks to dotfiles using stow
    stow_overwrite

    echo -en "$CCA$CNT - Sourcing .zshenv" && sleep 0.5 && [ -f ~/.zshenv ] && . ~/.zshenv &>>"${INSTLOG}" && echo -e "$CCL$COK - Sourced .zshenv" # Export environment variables from .zshenv
    echo -en "$CNT - Sourcing .zshrc" && sleep 0.5 && [ -f "${ZDOTDIR}/.zshrc" ] && . "${ZDOTDIR}/.zshrc" &>>"${INSTLOG}" && echo -e "$CCL$COK - Sourced .zshrc"
fi

# Change default shell to zsh if installed
if command -v zsh && echo -e "command not found" &>/dev/null; then
    ZSH_PATH=$(which zsh)
    if [[ "$SHELL" != "$ZSH_PATH" ]]; then
        echo -en "$CNT - Changing default shell to ZSH..."
        sudo chsh -s "$ZSH_PATH" "${USER}" &>>"${INSTLOG}"
        echo -e "$COK - Default shell changed to ZSH."
    else
        echo -e "$COK - ZSH is already your default shell."
    fi
else
    echo -e "$CWR - ZSH is not installed, skipping shell change."
fi

# Clean home directory dotfiles to follow XDG standard
echo -en "${CAC} - Would you like to run antidot (declutter your home directory)? (y,n) " && read -r CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then

    echo -e "$CNT - Decluttering home directory..."
    yes | antidot update &>>"${INSTLOG}" &&
        yes | antidot clean &>>"${INSTLOG}"
    echo -e "$CCA$COK - Home directory is now squeaky clean"

fi



# Load zsh autocompletions
echo -en "$CNT - Updating & loading zsh completions" && sleep 0.5 && load_completions && echo -e "${CCL}${COK} - Completions loaded." || echo -e "${CCA}$CWR Unable to load completions."

# Setup complete
echo -e "$CNT - \033[36m SETUP COMPLETE, ENJOY YOUR NEW SUPERCHARGED DEVELOPER ENVIRONMENT!\033[0m\n\033[95mPLEASE RESTART YOUR TERMINAL TO COMPLETE SETUP\033[0m"
