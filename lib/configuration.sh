# shellcheck shell=bash
# Which configuration a task works on, and its build. Sourced by check and activate, never run.
#
# A configuration is one tier on one platform (CONTEXT.md). The tier is a flag; the platform
# is a flag too, detected from the machine when not given. The build is home-manager's
# activation package for that pair, which `activate` then runs.

[ -n "${_SMS_CONFIGURATION:-}" ] && return 0
_SMS_CONFIGURATION=1

# shellcheck source=lib/ui.sh
source "${MISE_PROJECT_ROOT:?}/lib/ui.sh"

# Every evaluation reads the username and home from the environment, hence --impure on
# every nix command, and the checkout the live links point at is this one: a worktree under
# test links into itself, and an activation from the main checkout brings a home that was moved
# to a worktree back.
export SMS_CHECKOUT=$MISE_PROJECT_ROOT

sms_detect_platform() {
  case "$(uname -s)" in
    Darwin) echo darwin ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then echo wsl; else echo linux; fi
      ;;
    *) echo linux ;;
  esac
}

# Parse the tier and platform flags into $tier, $platform and $configuration, the name the
# flake exposes the pair under. The pairs that exist are the flake's to say, so an unknown one
# is refused with the flake's own list rather than a copy kept here.
sms_configuration() {
  tier='' platform=''
  while [[ $# -gt 0 ]]; do
    case $1 in
      --tier)
        tier=${2:?--tier needs a value}
        shift 2
        ;;
      --tier=*)
        tier=${1#--tier=}
        shift
        ;;
      --platform)
        platform=${2:?--platform needs a value}
        shift 2
        ;;
      --platform=*)
        platform=${1#--platform=}
        shift
        ;;
      *)
        sms_err "unknown argument: $1 (expected --tier <tier> [--platform <platform>])"
        return 1
        ;;
    esac
  done
  if [[ -z $tier ]]; then
    sms_err 'which tier? --tier shell or --tier desktop'
    return 1
  fi
  [[ -n $platform ]] || platform=$(sms_detect_platform)
  configuration="$tier-$platform"

  local known
  known=$(nix eval --impure --json "$MISE_PROJECT_ROOT#homeConfigurations" --apply builtins.attrNames)
  if [[ $known != *"\"$configuration\""* ]]; then
    sms_err "no configuration $configuration; the flake has ${known//\"/}"
    return 1
  fi
}

# Build the selected configuration into $generation, the activation package's store path.
# Nothing under ~ is touched: --no-link keeps even the ./result link out of the checkout.
sms_build() {
  sms_note "building $configuration"
  # shellcheck disable=SC2034  # generation is consumed by the tasks that source this file
  generation=$(nix build --impure --no-link --print-out-paths \
    "$MISE_PROJECT_ROOT#homeConfigurations.$configuration.activationPackage")
}
