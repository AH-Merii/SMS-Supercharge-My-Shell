# Get absolute path to the directory this script is in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source relative files using full path
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/helper-funcs.sh"

# === Source .zshenv ===
ZSHENV="${HOME}/.zshenv"
echo -en "${CNT} - Sourcing .zshenv"
sleep 0.5

if [[ -f "${ZSHENV}" ]]; then
  if source "${ZSHENV}" &>>"${INSTLOG}"; then
    echo -e "${CCL}${COK} - Sourced .zshenv"
  else
    echo -e "${CCL}${CROSS} - Failed to source ${ZSHENV} ${CROSS}"
    return 1
  fi
else
  echo -e "${CCL}${CER} - $ZSHENV not found! Unable to complete setup"
  return 1
fi

add_homebrew_path_to_config

# Change default shell to zsh if installed
if command -v zsh &>/dev/null; then
  ZSH_PATH=$(which zsh)
  if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    echo -e "$CNT - Changing default shell to ZSH..."
    sudo chsh -s "$ZSH_PATH" "${USER}" &>>"${INSTLOG}"
    echo -e "${CCA}${COK} - Default shell changed to ZSH."
  else
    echo -e "${CCA}${COK} - ZSH is already your default shell."
  fi
else
  echo -e "${CCA}${CWR} - ZSH is not installed, skipping shell change."
fi

# Clean home directory dotfiles to follow XDG standard
echo -en "${CAC} - Would you like to run antidot (declutter your home directory)? (y,n) " && read -r CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
  echo -e "$CNT - Decluttering home directory..."

  if yes | antidot update &>>"${INSTLOG}" && yes | antidot clean &>>"${INSTLOG}"; then
    echo -e "$CCA$COK - Home directory is now squeaky clean."
  else
    echo -e "$CCA$CWR - Problem encountered decluttering home directory, check $INSTLOG for more info."
    return 1
  fi

else
  return 1
fi

return 0
