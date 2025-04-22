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
  run_command --input-message "Authenticating with GitHub" --show-output \
    --success-message "Authentication with Github Successful" -c "gh auth login" &&
    # only attempt to install extension if auth is succesful
    run_with_progress --input-message "Installing gh-notify extension" \
      -c "gh extension install meiji163/gh-notify"
}

main
