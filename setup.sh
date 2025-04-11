#!/bin/bash
set -euo pipefail

# Source helper functions and common vars
source scripts/common.sh && echo -e "$CNT - Sourced common vars" || exit 1
source scripts/helper-funcs.sh && echo -e "$CNT - Sourced helper functions" || exit 1

clear

# Run bash setup, then zsh setup, then completions ΓÇö only if the previous succeeded
if source scripts/bash_setup.sh; then
  echo -e "$COK - Bash setup succeeded."

  if source scripts/zsh_setup.sh; then
    echo -e "$COK - ZSH setup succeeded."

    # Only try to load completions if zsh_setup sourced successfully
    if declare -f load_completions &>/dev/null; then
      echo -en "$CNT - Updating & loading zsh completions"
      sleep 0.5
      load_completions && echo -e "${CCL}${COK} - Completions loaded." || echo -e "${CCA}${CWR} Unable to load completions."
    else
      echo -e "${CCA}${CWR} - Function load_completions not available, skipping..."
    fi

    # Setup complete
    echo -e "$CNT - \033[36m SETUP COMPLETE, ENJOY YOUR NEW SUPERCHARGED DEVELOPER ENVIRONMENT!\033[0m\n\033[95mPLEASE RESTART YOUR TERMINAL TO COMPLETE SETUP\033[0m"
  else
    echo -e "${CER} - zsh_setup failed. Exiting setup."
    exit 1
  fi

else
  echo -e "${CER} - bash_setup failed. Exiting setup."
  exit 1
fi
