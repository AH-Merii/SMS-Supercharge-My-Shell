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

add_homebrew_path_to_config || return 1

change_default_shell_to_zsh || return 1

clean_dotfiles_from_homedir || return 1
return 0
