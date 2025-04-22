#!/bin/bash
## Make sure you ran the install.sh script and have reset your terminal before attempting to run this script
# Get absolute path to the directory this script is in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source relative files using full path
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/show_progress.sh"

# Main function to orchestrate the setup
main() {
  run_with_progress --input-message "Setting Up Vale" -c "vale sync"

  # check if you are authenticated with github if not authenticate github
  run_command --input-message "Checking GitHub Authentication" \
    --success-message "GitHub already authenticated" \
    -c "gh auth status" >/dev/null 2>&1
  local github_auth_status=$?

  if [[ "${github_auth_status}" -ne 0 ]]; then
    run_command --input-message "Authenticating with GitHub" --show-output \
      --success-message "Authentication with Github Successful" -c "gh auth login"
    local github_auth_status=$?
    #only attempt to install extension if auth is succesful
    [[ "${github_auth_status}" -ne 0 ]] && run_with_progress --input-message "Installing gh-notify extension" \
      -c "gh extension install meiji163/gh-notify"
  fi

}

main
