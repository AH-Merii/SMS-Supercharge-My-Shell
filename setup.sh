#!/bin/bash

# source helper functions
source ./scripts/helper-funcs.sh && echo "$CNT - Sourced helper functions"


# language servers to install
lsp_stage=(
    bash-language-server
    python-lsp-server
    vscode-langservers-extracted
    terraform-ls
    texlab
    marksman
    taplo-cli
    gopls
    dockerfile-language-server
    rust-analyzer
)

# tools to install
tool_stage=(
    helix
    kitty
    lf
    lazygit
    bat
    fzf
    exa
    git-delta-git
    tmux
    ripgrep
    stow
    curl
    wget
    jq
    xclip
)

# miscellaneous
misc_stage=(
    zsh
    pyenv
    python-virtualenv
    python-pip
    go
    zsh-antidote
    zsh-theme-powerlevel10k
    ttf-firacode-nerd
    inter-font
    wl-clipboard
)


# clear the screen
clear

# let the user know that we will use sudo
echo -e "$CNT - This script will run some commands that require sudo. You will be prompted to enter your password.
If you are worried about entering your password then you may want to review the content of the script."
sleep 1

# give the user an option to exit out
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to continue with the install (y,n) ' CONTINST
if [[ $CONTINST == "Y" || $CONTINST == "y" ]]; then
    echo -e "$CNT - Setup starting..."
    sudo touch /tmp/setup.tmp
else
    echo -e "$CNT - This script will now exit, no changes were made to your system."
    exit
fi

# checks for paru, and installs it if it is not found
install_paru_if_not_found

### Install all of the above pacakges ####
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install the packages? (y,n) ' INST
if [[ $INST == "Y" || $INST == "y" ]]; then

    # LSP Stage - Language Servers
    echo -e "$CNT - LSP Stage - Installing Language Servers, this may take a while..."
    for SOFTWR in ${lsp_stage[@]}; do
        install_software_paru $SOFTWR 
    done

    # dev tool Stage - dev tools
    echo -e "$CNT - Installing dev tools, this may take a while..."
    for SOFTWR in ${tool_stage[@]}; do
        install_software_paru $SOFTWR 
    done

    # misc Stage - Supercharging Shell
    echo -e "$CNT - Supercharging your shell, this may take a while..."
    for SOFTWR in ${misc_stage[@]}; do
        install_software_paru $SOFTWR 
    done
    
fi

### Copy Config Files ###
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to copy config files? (y,n) ' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
    echo -e "$CNT - Creating config files symobic links using stow..."

    # create symlinks to dotfiles using stow
    stow */ --verbose -t ~ && echo -e "$CNT - Linked config files." &>> $INSTLOG

    # export environment variables from .zshenv
    [ -f ~/.zshenv ] && source ~/.zshenv && echo -e "$CNT - Sourced .zshenv" &>> $INSTLOG

fi

### Copy Config Files ###
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to run antidot (declutter your home directory)? (y,n) ' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then

    echo -e "$CNT - Decluttering home directory..."
    antidot update &>> $INSTLOG
    antidot clean &>> $INSTLOG
    antidot init &>> $INSTLOG

fi

# setup complete
echo -e "$CNT - \033[36m SETUP COMPLETE, ENJOY YOUR NEW SUPERCHARGED DEVELOPER ENVIRONMENT!\033[0m\n\033[95mPLEASE RESTART YOUR TERMINAL TO COMPLETE SETUP\033[0m"

