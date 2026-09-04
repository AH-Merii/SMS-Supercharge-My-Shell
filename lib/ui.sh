# shellcheck shell=bash
# Colours and prompts for the install tasks. Sourced, never run.
#
# bootstrap.sh does not use this file -- when curl-piped it runs before the repo is
# cloned, so it inlines its own minimal copy of the colour vars and sms_confirm.
# Keep the two in step.

[ -n "${_SMS_UI:-}" ] && return 0
_SMS_UI=1

# Colour on stdout, not stdin: under `curl ... | sh` stdin is the pipe while stdout is
# still the terminal, so testing -t 0 here would silently drop every colour.
# NO_COLOR is checked first and wins outright -- FORCE_COLOR only overrides the tty
# test, it does not get to override someone saying they do not want colour.
if [[ -z ${NO_COLOR:-} ]] &&
  { [[ -n ${FORCE_COLOR:-} ]] || { [[ -t 1 ]] && [[ ${TERM:-dumb} != dumb ]]; }; }; then
  c_reset=$'\e[0m' c_bold=$'\e[1m' c_dim=$'\e[2m'
  c_red=$'\e[31m' c_green=$'\e[32m' c_yellow=$'\e[33m' c_cyan=$'\e[36m'
else
  c_reset='' c_bold='' c_dim='' c_red='' c_green='' c_yellow='' c_cyan=''
fi

sms_header() { printf '\n%s%s%s\n' "$c_bold$c_cyan" "$1" "$c_reset"; }
sms_section() { printf '\n  %s%s%s  %s%s%s\n' "$c_bold" "$1" "$c_reset" "$c_dim" "${2:-}" "$c_reset"; }
sms_note() { printf '    %s%s%s\n' "$c_dim" "$1" "$c_reset"; }
sms_warn() { printf '    %s%s%s\n' "$c_bold$c_yellow" "$1" "$c_reset"; }
sms_err() { printf '    %s%s%s\n' "$c_bold$c_red" "$1" "$c_reset" >&2; }

# Indent and wrap a list of names under a coloured label.
_sms_list() {
  local colour=$1 label=$2
  shift 2
  [[ $# -gt 0 ]] || return 0
  local width=$((${COLUMNS:-$(tput cols 2>/dev/null || echo 80)} - 24))
  [[ $width -ge 20 ]] || width=20
  local first=1 line
  while IFS= read -r line; do
    if [[ $first == 1 ]]; then
      printf '    %s%-18s%s %s\n' "$colour" "$label" "$c_reset" "$line"
      first=0
    else
      printf '    %-18s %s\n' '' "$line"
    fi
  done < <(printf '%s\n' "$*" | fold -s -w "$width" | sed 's/ *$//')
}

sms_have() { _sms_list "$c_dim$c_green" 'already installed' "$@"; }
sms_want() { _sms_list "$c_yellow" 'will install' "$@"; }
sms_drop() { _sms_list "$c_yellow" 'will remove' "$@"; }
sms_backup() { _sms_list "$c_yellow" 'will back up' "$@"; }

# Ask a Y/n question, default yes. Keep this small: called from an `if`, its body runs
# with errexit disabled, so a bug in here would be swallowed rather than reported.
sms_confirm() {
  [[ -n ${SMS_YES:-} || -n ${SMS_PLAN_CONFIRMED:-} ]] && return 0

  # Open the tty once as fd 3 rather than redirecting each read: `read < /dev/tty` on an
  # unopenable tty under `set -e` behaves differently across bash versions. Prompt on
  # fd 3 too, so `mise run setup | tee log` cannot swallow the question.
  #
  # Probed in a subshell rather than attempted directly. `exec` is a special builtin, so
  # a failed redirection on it kills the whole shell in POSIX mode instead of returning
  # non-zero, and even in bash `exec 3<>/dev/tty 2>/dev/null` would both leak the error
  # (redirections apply in order) and latch 2>/dev/null onto the shell when it succeeds.
  if ! (exec 3<>/dev/tty) 2>/dev/null; then
    sms_note 'no terminal to prompt on - assuming yes'
    return 0
  fi
  exec 3<>/dev/tty

  local reply
  printf '\n  %s%s [Y/n]%s ' "$c_bold" "$1" "$c_reset" >&3
  IFS= read -r reply <&3 || reply=
  exec 3>&-

  case ${reply,,} in
    '' | y | yes) return 0 ;;
    *) return 1 ;;
  esac
}

# Print a plan and confirm it -- unless `setup` already showed the combined plan and got
# an answer, in which case showing the same section again would just be noise.
sms_preview() {
  [[ -n ${SMS_PLAN_CONFIRMED:-} ]] && return 0
  "$1"
  sms_confirm "$2"
}
