#!/bin/bash

# Source helper functions
source scripts/helper-funcs.sh && echo "$CNT - Sourced helper functions"

# Create a fresh log file
echo "Installation Log - $(date)" > $INSTLOG

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
echo -e "$CNT - This script will run some commands that require sudo. You will be prompted to enter your password.
If you are worried about entering your password then you may want to review the content of the script."
sleep 1

# Give the user an option to exit out
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to continue with the install (y,n) ' CONTINST
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

# Enable Homebrew font casks
# echo -e "$CNT - Enabling Homebrew font casks..."
# brew tap homebrew/cask-fonts &>> $INSTLOG

# Install packages
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install the packages? (y,n) ' INST
if [[ $INST == "Y" || $INST == "y" ]]; then
    # Install all brew packages
    echo -e "$CNT - Installing packages, this may take a while..."
    for PACKAGE in "${brew_packages[@]}"; do
        # Check if it's a font package
        if [[ $PACKAGE == font-* ]]; then
            install_font_cask $PACKAGE
        else
            install_brew_package $PACKAGE
        fi
    done
    
    # Cleanup
    echo -e "$CNT - Cleaning up Homebrew installation..."
    brew cleanup &>> $INSTLOG
fi

# Copy Config Files
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to copy config files? (y,n) ' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
    echo -e "$CNT - Creating config files symbolic links using stow..."
    # Create symlinks to dotfiles using stow
    stow */ --verbose -t ~ && echo -e "$CNT - Linked config files." &>> $INSTLOG
    # Export environment variables from .zshenv
    [ -f ~/.zshenv ] && source ~/.zshenv && echo -e "$CNT - Sourced .zshenv" &>> $INSTLOG
fi


# Clean home directory dotfiles to follow XDG standard
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to run antidot (declutter your home directory)? (y,n) ' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then

    echo -e "$CNT - Decluttering home directory..."
    yes | antidot update &>> $INSTLOG
    yes | antidot clean &>> $INSTLOG

fi

# Change default shell to zsh if installed
if command -v zsh &> /dev/null; then
    ZSH_PATH=$(which zsh)
    if [[ "$SHELL" != "$ZSH_PATH" ]]; then
        echo -e "$CNT - Changing default shell to ZSH..."
        sudo chsh -s "$ZSH_PATH" $USER &>> $INSTLOG
        echo -e "$COK - Default shell changed to ZSH."
    else
        echo -e "$COK - ZSH is already your default shell."
    fi
else
    echo -e "$CWR - ZSH is not installed, skipping shell change."
fi

# Load zsh autocompletions
load_completions

# Setup complete
echo -e "$CNT - \033[36m SETUP COMPLETE, ENJOY YOUR NEW SUPERCHARGED DEVELOPER ENVIRONMENT!\033[0m\n\033[95mPLEASE RESTART YOUR TERMINAL TO COMPLETE SETUP\033[0m"
