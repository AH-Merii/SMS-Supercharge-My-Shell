#!/bin/sh
# Set up a machine end to end. Safe to re-run; every step converges.
#
#   fresh machine:      curl -fsSL https://raw.githubusercontent.com/AH-Merii/SMS-Supercharge-My-Shell/main/bootstrap.sh | sh
#   existing checkout:  ./bootstrap.sh
#   unattended:         ./bootstrap.sh -y      (piped: ... | sh -s -- -y)
#
# 1. git, stow, fish, mise from the OS package manager (Homebrew on macOS and WSL)
# 2. clone to ~/SMS-Supercharge-My-Shell unless already running from a checkout
# 3. mise run setup  ->  deps, link, tools, plugins
#
# Both steps show what they will install and ask before doing it. -y (or SMS_YES=1)
# accepts everything, ours and the package managers'.
set -eu

REPO=https://github.com/AH-Merii/SMS-Supercharge-My-Shell.git
DEST="$HOME/SMS-Supercharge-My-Shell"

# Remote installers, pinned. Homebrew/install has no tags or releases, so it is pinned to a
# commit. mise's installer embeds the checksums of its own release's binaries, so pinning
# the script pins mise too (the route mise.jdx.dev/installing-mise.html recommends). To bump:
# pick the new ref, download the file at that ref, hash it with `sha256sum` (macOS:
# `shasum -a 256`), and change ref and hash together -- README, "Install".
HOMEBREW_INSTALL_REF=7a133dcc74051ee4efc79467ed215dfedf45aea2 # main, 2026-09-04
HOMEBREW_INSTALL_SHA256=12479a24be3f5307eecac7cde670fad7118640f031229e964f544b1367b52a41
MISE_TAG=v2026.9.1
MISE_INSTALL_SHA256=3731dfec59ffb0bc23df96ae19b4b51470db939c875c2fdf01cf6c25b1b1e039

SMS_YES=${SMS_YES:-}
for arg in "$@"; do
  case $arg in
    -y | --yes) SMS_YES=1 ;;
    -h | --help)
      sed -n '2,13p' "$0" 2>/dev/null || printf 'usage: bootstrap.sh [-y|--yes]\n'
      exit 0
      ;;
    *)
      printf 'bootstrap.sh: unknown option %s (try -h)\n' "$arg" >&2
      exit 2
      ;;
  esac
done
if [ -n "$SMS_YES" ]; then export SMS_YES; fi

# Under `curl ... | sh` stdin is the pipe, and pacman/apt/paru read stdin rather than
# /dev/tty -- without this they hit EOF and abort the moment their prompts are enabled.
#
# Probed in a subshell first. `exec` is a special builtin, so a failed redirection on it
# kills the shell outright in POSIX sh: `exec </dev/tty || true` would never reach the
# `|| true`, and a no-tty run (CI, a pipeline) would die here with no output at all.
if [ ! -t 0 ] && (exec </dev/tty) 2>/dev/null; then
  exec </dev/tty
fi

# --- ui ---------------------------------------------------------------------------
# Deliberately duplicated from lib/ui.sh: when curl-piped this runs before the repo is
# cloned, so that file does not exist yet. Keep the two in step.

# NO_COLOR wins outright; FORCE_COLOR only overrides the tty test.
if [ -z "${NO_COLOR:-}" ] &&
  { [ -n "${FORCE_COLOR:-}" ] || { [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]; }; }; then
  c_reset=$(printf '\033[0m') c_bold=$(printf '\033[1m') c_dim=$(printf '\033[2m')
  c_green=$(printf '\033[32m') c_yellow=$(printf '\033[33m') c_cyan=$(printf '\033[36m')
else
  c_reset='' c_bold='' c_dim='' c_green='' c_yellow='' c_cyan=''
fi

sms_confirm() {
  if [ -n "$SMS_YES" ]; then return 0; fi
  # Probe in a subshell before the real exec; see the note on /dev/tty above.
  if ! (exec 3<>/dev/tty) 2>/dev/null; then
    printf '    %sno terminal to prompt on - assuming yes%s\n' "$c_dim" "$c_reset"
    return 0
  fi
  exec 3<>/dev/tty
  printf '\n  %s%s [Y/n]%s ' "$c_bold" "$1" "$c_reset" >&3
  IFS= read -r reply <&3 || reply=
  exec 3>&-
  case $reply in
    '' | y | Y | yes | YES | Yes) return 0 ;;
    *) return 1 ;;
  esac
}

# Download $1 to $3, refusing to go on unless its sha256 is $2.
fetch_verified() {
  curl -fsSL -o "$3" "$1"
  if command -v sha256sum >/dev/null 2>&1; then
    got=$(sha256sum "$3")
  else
    got=$(shasum -a 256 "$3")
  fi
  got=${got%% *}
  if [ "$got" != "$2" ]; then
    printf '\n  %schecksum mismatch for %s%s\n    expected %s\n    got      %s\n' \
      "$c_yellow" "$1" "$c_reset" "$2" "$got" >&2
    exit 1
  fi
}

# Everything the active package manager already has, one name per line.
installed_set() {
  case $mgr in
    pacman) pacman -Qq 2>/dev/null ;;
    apt) dpkg-query -f '${db:Status-Status} ${Package}\n' -W 2>/dev/null |
      awk '$1 == "installed" { print $2 }' ;;
    dnf) rpm -qa --qf '%{NAME}\n' 2>/dev/null ;;
    brew) { brew list --formula -1; brew list --cask -1; } 2>/dev/null ;;
    *) : ;;
  esac
}

# Print the plan for $pkgs under $mgr, splitting into what is already there and what is
# not. Sets $want so the caller can skip the install when there is nothing to do.
show_plan() {
  set=$(installed_set || true)
  have='' want=''
  for p in $pkgs; do
    if printf '%s\n' "$set" | grep -qxF "$p"; then
      have="$have $p"
    else
      want="$want $p"
    fi
  done
  printf '\n%sSMS · bootstrap%s\n' "$c_bold$c_cyan" "$c_reset"
  printf '\n  %s%s%s\n' "$c_bold" "$mgr" "$c_reset"
  if [ -n "$have" ]; then
    printf '    %s%-18s%s%s\n' "$c_dim$c_green" 'already installed' "$c_reset" "$have"
  fi
  if [ -n "$want" ]; then
    printf '    %s%-18s%s%s\n' "$c_yellow" 'will install' "$c_reset" "$want"
  else
    printf '    %sall present%s\n' "$c_dim" "$c_reset"
  fi
  return 0
}

# --- detect -----------------------------------------------------------------------

# Running from inside a checkout (./bootstrap.sh)? Use it instead of cloning.
script_dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || script_dir=""
if [ -n "$script_dir" ] && [ -f "$script_dir/mise.toml" ]; then
  DEST=$script_dir
fi

os=$(uname -s)
wsl=0
if grep -qi microsoft /proc/version 2>/dev/null; then wsl=1; fi

if command -v pacman >/dev/null 2>&1; then
  mgr=pacman
  pkgs="git stow fish mise"
elif [ "$os" = Darwin ] || [ "$wsl" = 1 ]; then
  mgr=brew
  pkgs="git stow fish mise"
elif command -v apt-get >/dev/null 2>&1; then
  mgr=apt
  pkgs="curl git stow fish"
elif command -v dnf >/dev/null 2>&1; then
  mgr=dnf
  pkgs="curl git stow fish"
else
  mgr=none
  pkgs=""
fi

# --- install ----------------------------------------------------------------------

if [ "$mgr" = none ]; then
  printf '\n  %sno supported package manager found; install git, stow, fish and mise yourself%s\n' \
    "$c_yellow" "$c_reset"
else
  show_plan
  sms_confirm 'Install these?' || {
    printf '\n  aborted, nothing installed\n\n'
    exit 0
  }
fi

confirm_pacman=''
confirm_yes=''
if [ -n "$SMS_YES" ]; then
  confirm_pacman=--noconfirm
  confirm_yes=-y
  DEBIAN_FRONTEND=noninteractive
  export DEBIAN_FRONTEND
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

case $mgr in
  pacman)
    # shellcheck disable=SC2086
    sudo pacman -Syu --needed $confirm_pacman $pkgs
    ;;
  brew)
    if [ "$os" = Darwin ]; then
      xcode-select -p >/dev/null 2>&1 || xcode-select --install
    elif command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update
      # shellcheck disable=SC2086
      sudo apt-get install $confirm_yes build-essential procps curl file git
    fi
    if ! command -v brew >/dev/null 2>&1; then
      fetch_verified "https://raw.githubusercontent.com/Homebrew/install/$HOMEBREW_INSTALL_REF/install.sh" \
        "$HOMEBREW_INSTALL_SHA256" "$tmp/brew-install.sh"
      NONINTERACTIVE=1 /bin/bash "$tmp/brew-install.sh"
    fi
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
      if [ -x "$b" ]; then
        eval "$("$b" shellenv)"
        break
      fi
    done
    # shellcheck disable=SC2086
    brew install $pkgs
    ;;
  apt)
    sudo apt-get update
    # shellcheck disable=SC2086
    sudo apt-get install $confirm_yes $pkgs
    if ! command -v mise >/dev/null 2>&1; then
      # mise from its signed apt repo, so apt keeps it current; extrepo carries the repo
      # definition and key (mise.jdx.dev/installing-mise.html#apt: Debian 11+, Ubuntu
      # 22.04+). Falls through to the pinned installer below where that is not available.
      # shellcheck disable=SC2086
      sudo apt-get install $confirm_yes extrepo &&
        sudo extrepo enable mise &&
        sudo apt-get update &&
        sudo apt-get install $confirm_yes mise ||
        printf '    %smise apt repo unavailable, using the pinned installer%s\n' "$c_yellow" "$c_reset"
    fi
    ;;
  dnf)
    # shellcheck disable=SC2086
    sudo dnf install $confirm_yes $pkgs
    if ! command -v mise >/dev/null 2>&1; then
      # mise from its COPR (mise.jdx.dev/installing-mise.html#dnf), same reasoning as apt.
      # shellcheck disable=SC2086
      sudo dnf $confirm_yes copr enable jdxcode/mise &&
        sudo dnf install $confirm_yes mise ||
        printf '    %smise COPR unavailable, using the pinned installer%s\n' "$c_yellow" "$c_reset"
    fi
    ;;
esac

if ! command -v mise >/dev/null 2>&1; then
  # Same script as https://mise.run, taken from the release so the pin is stable. It
  # checks the binary it downloads against the checksums it carries for $MISE_TAG.
  fetch_verified "https://github.com/jdx/mise/releases/download/$MISE_TAG/install.sh" \
    "$MISE_INSTALL_SHA256" "$tmp/mise-install.sh"
  MISE_INSTALL_HELP=0 sh "$tmp/mise-install.sh" # conf.d/05-mise.fish already activates it
  export PATH="$HOME/.local/bin:$PATH"
fi

if [ ! -d "$DEST/.git" ]; then
  git clone "$REPO" "$DEST"
fi
cd "$DEST"

mise trust --yes

# setup prints its own plan, asks its own question, and prints the closing advice about
# chsh and ggh -- so it lands however setup was reached, and never after a declined plan.
mise run setup
