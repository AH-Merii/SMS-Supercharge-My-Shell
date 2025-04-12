source common.sh
source helper-funcs.sh

# Change default shell to zsh if installed
if command -v zsh && echo -e "command not found" &>/dev/null; then
  ZSH_PATH=$(which zsh)
  if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    echo -en "$CNT - Changing default shell to ZSH..."
    sudo chsh -s "$ZSH_PATH" "${USER}" &>>"${INSTLOG}"
    echo -e "${CCL}${COK} - Default shell changed to ZSH."
  else
    echo -e "${CCL}${COK} - ZSH is already your default shell."
  fi
else
  echo -e "${CWR} - ZSH is not installed, skipping shell change."
fi

add_homebrew_path_to_configs

# Clean home directory dotfiles to follow XDG standard
echo -en "${CAC} - Would you like to run antidot (declutter your home directory)? (y,n) " && read -r CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then

  echo -e "$CNT - Decluttering home directory..."
  yes | antidot update &>>"${INSTLOG}" &&
    yes | antidot clean &>>"${INSTLOG}" &&
    echo -e "$CCA$COK - Home directory is now squeaky clean." ||
    echo -e "$CCA$CWR - Problem encountered decluttering home diretory, check $INSTLOG for more info."

fi
