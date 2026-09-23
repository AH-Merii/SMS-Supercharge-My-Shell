#!/bin/sh
# A Fresh machine, from nothing to set up. Safe to re-run; every step converges.
#
#   fresh machine:      curl -fsSL https://raw.githubusercontent.com/AH-Merii/SMS-Supercharge-My-Shell/main/bootstrap.sh | sh
#   a Linux desktop:    ... | sh -s -- --tier desktop
#   existing checkout:  ./bootstrap.sh [--tier desktop]
#   unattended:         ./bootstrap.sh -y      (piped: ... | sh -s -- -y)
#
# 1. Nix, by the Determinate installer, unless nix is already here
# 2. the clone at ~/SMS-Supercharge-My-Shell, unless this runs from a checkout already
# 3. `mise run setup`, in a shell that borrows git, mise and bash from nixpkgs: the machine
#    has none of them yet, and after the first switch it has them from the configuration
#
# The installer asks its own question and setup asks one for every step it runs; this script
# asks nothing. -y (or SMS_YES=1) answers all of them.
set -eu

REPO=https://github.com/AH-Merii/SMS-Supercharge-My-Shell.git
DEST="$HOME/SMS-Supercharge-My-Shell"

SMS_YES=${SMS_YES:-}
tier=shell
while [ $# -gt 0 ]; do
  case $1 in
    -y | --yes) SMS_YES=1 ;;
    --tier)
      tier=${2:?--tier needs a value}
      shift
      ;;
    --tier=*) tier=${1#--tier=} ;;
    -h | --help)
      sed -n '2,15p' "$0" 2>/dev/null || printf 'usage: bootstrap.sh [-y|--yes] [--tier shell|desktop]\n'
      exit 0
      ;;
    *)
      printf 'bootstrap.sh: unknown option %s (try -h)\n' "$1" >&2
      exit 2
      ;;
  esac
  shift
done
if [ -n "$SMS_YES" ]; then export SMS_YES; fi

# Under `curl ... | sh` stdin is the pipe, and the installer's and setup's questions read
# stdin rather than /dev/tty; without this they hit EOF the moment they are asked.
#
# Probed in a subshell first. `exec` is a special builtin, so a failed redirection on it
# kills the shell outright in POSIX sh: `exec </dev/tty || true` would never reach the
# `|| true`, and a no-tty run (CI, a pipeline) would die here with no output at all.
if [ ! -t 0 ] && (exec </dev/tty) 2>/dev/null; then
  exec </dev/tty
fi

# --- nix --------------------------------------------------------------------------

if ! command -v nix >/dev/null 2>&1; then
  # Multi-user daemon, flakes on, and `/nix/nix-installer uninstall` as the way back. A
  # container has no init to own the daemon, so there the installer is told not to look
  # for one and nix runs daemonless.
  set -- install
  if [ "$(uname -s)" = Linux ] && [ ! -d /run/systemd/system ]; then
    set -- install linux --init none
  fi
  if [ -n "$SMS_YES" ]; then set -- "$@" --no-confirm; fi
  curl -fsSL https://install.determinate.systems/nix | sh -s -- "$@"
fi
# The installer puts nix on the PATH of new shells; this one is not new.
if ! command -v nix >/dev/null 2>&1; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# --- clone ------------------------------------------------------------------------

# Running from inside a checkout (./bootstrap.sh)? Use it instead of cloning.
script_dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || script_dir=""
if [ -n "$script_dir" ] && [ -f "$script_dir/mise.toml" ]; then
  DEST=$script_dir
fi

# Borrowed from nixpkgs for this one run. The configuration installs its own git, mise and
# bash on the first switch; on macOS the system bash is too old for the tasks either way.
borrow() { nix shell nixpkgs#git nixpkgs#mise nixpkgs#bash --command "$@"; }

if [ ! -e "$DEST/.git" ]; then
  borrow git clone "$REPO" "$DEST"
fi
cd "$DEST"

# --- setup ------------------------------------------------------------------------

borrow mise trust --yes
# setup shows one plan, asks one question and prints the closing advice about the login
# shell and ggh, so it lands however setup was reached and never after a declined plan.
borrow mise run setup -- --tier "$tier"
