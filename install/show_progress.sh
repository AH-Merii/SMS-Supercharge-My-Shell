#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source relative files using full path
source "${SCRIPT_DIR}/common.sh"

#
# Show a progress spinner while a background process runs.
#
# Usage:
#   show_progress --pid <PID> \
#                 --input-message <message> \
#                 --success-message <message> \
#                 [--delay <seconds>] \
#                 [--spinstr <string>] \
#                 [--notification-type <str>]
#
# Globals:
#   COK, CCL, CER, CROSS, CHECK
# Arguments:
#   --pid                PID of the background process to monitor (required)
#   --input-message      Message to display while process is running (required)
#   --success-message    Message to display if process completes successfully (optional)
#   --delay              Delay between spinner frames (default: 0.1s)
#   --spinstr            Spinner character sequence (default: '.oO0@0Oo.')
#   --notification-type  Styling tag to prepend on success (e.g., ${COK}, ${CWR}, ${CAC})
# Outputs:
#   Spinner animation on STDOUT. Errors on STDERR.
# Returns:
#   0 on success, non-zero if the process failed or arguments were missing.
#
# Example:
#   long_running_command &
#   pid=$!
#
#   show_progress \
#     --pid "${pid}" \
#     --input-message "Processing..." \
#     --success-message "Done!"

show_progress() {
  local input_message
  local success_message
  local notification_type
  local pid=""
  local delay="0.1"
  local spinstr='.oO0@0Oo.'

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --pid)
      pid="$2"
      shift 2
      ;;
    --input-message)
      input_message="$2"
      shift 2
      ;;
    --success-message)
      success_message="$2"
      shift 2
      ;;
    --delay)
      delay="$2"
      shift 2
      ;;
    --spinstr)
      spinstr="$2"
      shift 2
      ;;
    --notification-type)
      notification_type="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      return 1
      ;;
    esac
  done

  if [[ ! -v pid || ! -v input_message ]]; then
    echo "Missing required arguments." >&2
    echo "Usage: show_progress --pid <PID> --input-message <msg>" >&2
    return 1
  fi

  echo -ne "${CNT} - ${input_message} "

  while kill -0 "${pid}" 2>/dev/null; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep "$delay"
    printf "\b\b\b\b\b\b"
  done

  wait "${pid}"
  local exit_status="$?"

  if [[ "${exit_status}" -eq 0 ]]; then
    echo -e "${CCL}${notification_type:-${COK}} - ${success_message:-$input_message} ${CHECK}"
  else
    echo -e " - ${CER} ${CROSS} (failed with code ${exit_status}) ${CROSS}"
  fi
}

#
# Run a command with a progress spinner and capture its output.
#
# Usage:
#   run_with_progress --input-message <message> \
#                     [--success-message <message>] \
#                     [--delay <seconds>] \
#                     [--spinstr <string>] \
#                     [--notification-type <str>] \
#                     [--show-output] \
#                     [--redirect-to <file>] \
#                     -c "<command>"
#
# Globals:
#   INSTLOG, COK, CCL, CER, CROSS, CHECK
# Arguments:
#   --input-message      Message to display while the command is running (required)
#   --success-message    Message to display if the command completes successfully (optional)
#   --delay              Delay between spinner frames (default: 0.1s)
#   --spinstr            Spinner character sequence (default: '.oO0@0Oo.')
#   --notification-type  Styling tag to prepend on success (e.g., ${COK}, ${CWR}, ${CAC})
#   --show-output        If specified, command output is displayed in the terminal
#   --redirect-to        File to redirect output to (default: $INSTLOG)
#   -c "<command>"       Quoted command string to execute (required)
#
# Outputs:
#   Spinner animation on STDOUT.
#   If --show-output is not specified, command output is redirected to the specified file (default: INSTLOG).
#   If --show-output is specified, command output is displayed in the terminal.
# Returns:
#   0 on success, non-zero if the command failed or arguments were missing.
#
# Example:
#   run_with_progress \
#     --input-message "Installing dependencies..." \
#     --success-message "Dependencies installed." \
#     -c "sudo apt-get update && sudo apt-get install -y curl"
#
# Example with output display:
#   run_with_progress \
#     --input-message "Running tests..." \
#     --show-output \
#     -c "./run_tests.sh"
run_with_progress() {
  local input_message
  local success_message
  local notification_type
  local delay="0.1"
  local spinstr='.oO0@0Oo.'
  local show_output
  local redirect_to="${INSTLOG}"
  local command_str=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --input-message)
      input_message="$2"
      shift 2
      ;;
    --success-message)
      success_message="$2"
      shift 2
      ;;
    --delay)
      delay="$2"
      shift 2
      ;;
    --spinstr)
      spinstr="$2"
      shift 2
      ;;
    --notification-type)
      notification_type="$2"
      shift 2
      ;;
    --show-output)
      show_output=true
      shift
      ;;
    --redirect-to)
      redirect_to="$2"
      shift 2
      ;;
    -c)
      shift
      command_str="$*"
      break
      ;;
    *)
      echo "Unknown option: $1" >&2
      return 1
      ;;
    esac
  done

  if [[ ! -v input_message || ! -v command_str ]]; then
    echo "Usage: run_with_progress --input-message <msg> [--success-message <msg>] [--notification-type <type>] [--show-output] [--redirect-to <file>] -c <command>" >&2
    return 1
  fi

  # Execute using bash -c with conditional redirection based on show_output flag
  if [[ ! -v "${show_output}" ]]; then
    bash -c "$command_str" &>>"$redirect_to" &
  else
    bash -c "$command_str" &
  fi

  local pid=$!

  show_progress \
    --pid "${pid}" \
    --input-message "${input_message}" \
    ${success_message:+--success-message "${success_message}"} \
    ${notification_type:+--notification-type "${notification_type}"} \
    --delay "${delay}" \
    --spinstr "${spinstr}"
}

#
# Run a command and handle its output, similar to run_with_progress but without the spinner.
#
# Usage:
#   run_command --input-message <message> \
#               [--success-message <message>] \
#               [--notification-type <str>] \
#               [--show-output] \
#               [--redirect-to <file>] \
#               -c "<command>"
#
# Globals:
#   INSTLOG, COK, CCL, CER, CROSS, CHECK
# Arguments:
#   --input-message      Message to display before running the command (required)
#   --success-message    Message to display if the command completes successfully (optional)
#   --notification-type  Styling tag to prepend on success (e.g., ${COK}, ${CWR}, ${CAC})
#   --show-output        If specified, command output is displayed in the terminal
#   --redirect-to        File to redirect output to (default: $INSTLOG)
#   -c "<command>"       Quoted command string to execute (required)
#
# Outputs:
#   Status messages on STDOUT.
#   If --show-output is not specified, command output is redirected to the specified file (default: INSTLOG).
#   If --show-output is specified, command output is displayed in the terminal.
# Returns:
#   0 on success, non-zero if the command failed or arguments were missing.
#
# Example:
#   run_command \
#     --input-message "Installing dependencies..." \
#     --success-message "Dependencies installed." \
#     -c "sudo apt-get update && sudo apt-get install -y curl"
#
# Example with output display:
#   run_command \
#     --input-message "Running tests..." \
#     --show-output \
#     -c "./run_tests.sh"

run_command() {
  local input_message
  local success_message
  local notification_type
  local show_output
  local redirect_to="${INSTLOG}"
  local command_str=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --input-message)
      input_message="$2"
      shift 2
      ;;
    --success-message)
      success_message="$2"
      shift 2
      ;;
    --notification-type)
      notification_type="$2"
      shift 2
      ;;
    --show-output)
      show_output=true
      shift
      ;;
    --redirect-to)
      redirect_to="$2"
      shift 2
      ;;
    -c)
      shift
      command_str="$*"
      break
      ;;
    *)
      echo "Unknown option: $1" >&2
      return 1
      ;;
    esac
  done

  echo command str "${command_str}"
  echo input message "${input_message}"

  if [[ ! -v input_message || ! -v command_str ]]; then
    echo "Usage: run_command --input-message <msg> [--success-message <msg>] [--notification-type <type>] [--show-output] [--redirect-to <file>] -c <command>" >&2
    return 1
  fi

  # Display input message
  echo -e "${CNT} - ${input_message}"

  # Execute the command with conditional redirection
  local exit_status=0

  if [[ ! -v show_output ]]; then
    bash -c "$command_str" &>>"$redirect_to" || exit_status=$?
  else
    bash -c "$command_str" || exit_status=$?
  fi

  # Display success or failure message
  if [[ "${exit_status}" -eq 0 ]]; then
    echo -e "${CCL}${notification_type:-${COK}} - ${success_message:-$input_message} ${CHECK}"
  else
    echo -e "${CER} ${CROSS} ${input_message} (failed with code ${exit_status}) ${CROSS}"
  fi

  return $exit_status
}
