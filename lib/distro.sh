# shellcheck shell=bash
# The distro's share of a configuration: the lists it expects pacman and the AUR to install,
# read off the configuration, previewed against what is installed and handed over. Shared by
# pacman and setup. Sourced, never run.
#
# Linux with pacman only. The lists are computed from the declarations (CONTEXT.md, "Distro
# list"), so a program is added to them by declaring `install.linux.pacman` or `.aur` and
# never by editing a list; what the switch installs itself is not here.

[ -n "${_SMS_DISTRO:-}" ] && return 0
_SMS_DISTRO=1

# shellcheck source=lib/configuration.sh
source "${MISE_PROJECT_ROOT:?}/lib/configuration.sh"

sms_distro_here() { command -v pacman >/dev/null 2>&1; }

# The lists of $configuration into pacman_all and aur_all, then each split by `pacman -T`
# (which names what is missing) into pacman_want/pacman_have and aur_want/aur_have. An AUR
# package that is installed is in pacman's database like any other, so one query serves both.
sms_distro_lists() {
  local line source name
  pacman_all=() aur_all=()
  while read -r source name; do
    case $source in
      pacman) pacman_all+=("$name") ;;
      aur) aur_all+=("$name") ;;
      '') ;;
      *) sms_warn "$configuration lists $name for $source, which nothing here installs" ;;
    esac
  done < <(nix eval --impure --raw \
    "$MISE_PROJECT_ROOT#homeConfigurations.$configuration.config.sms.distro" \
    --apply 'd: builtins.concatStringsSep "\n" (builtins.concatLists
      (builtins.attrValues (builtins.mapAttrs (s: l: map (p: s + " " + p) l) d)))')

  local missing p
  missing=$(pacman -T "${pacman_all[@]}" "${aur_all[@]}" 2>/dev/null) || true
  local -A gone=()
  while IFS= read -r p; do [[ -n $p ]] && gone[$p]=1; done <<<"$missing"
  pacman_want=() pacman_have=() aur_want=() aur_have=()
  for p in "${pacman_all[@]}"; do
    if [[ -n ${gone[$p]:-} ]]; then pacman_want+=("$p"); else pacman_have+=("$p"); fi
  done
  for p in "${aur_all[@]}"; do
    if [[ -n ${gone[$p]:-} ]]; then aur_want+=("$p"); else aur_have+=("$p"); fi
  done
}

sms_distro_show() {
  sms_section pacman "${#pacman_want[@]} of ${#pacman_all[@]} to install, from the $configuration list"
  [[ ${#pacman_have[@]} -gt 0 ]] && sms_have "${pacman_have[@]}"
  [[ ${#pacman_want[@]} -gt 0 ]] && sms_want "${pacman_want[@]}"
  [[ ${#pacman_all[@]} -gt 0 ]] || sms_note 'nothing for pacman'

  [[ ${#aur_all[@]} -gt 0 ]] || return 0
  sms_section aur "${#aur_want[@]} of ${#aur_all[@]} to install, through paru"
  [[ ${#aur_have[@]} -gt 0 ]] && sms_have "${aur_have[@]}"
  [[ ${#aur_want[@]} -gt 0 ]] && sms_want "${aur_want[@]}"
  if [[ ${#aur_want[@]} -gt 0 ]] && ! command -v paru >/dev/null 2>&1; then
    sms_warn 'paru is not installed; the AUR list will be printed for you to install by hand'
  fi
  return 0
}

sms_distro_install() {
  # Once the plan is confirmed there is nothing left for pacman to ask that the plan did not
  # already show, so its prompt is skipped. paru is different: the plan never showed you a
  # PKGBUILD, so its review survives everything short of an explicit SMS_YES.
  local confirm_pacman='' confirm_paru=''
  if [[ -n ${SMS_YES:-} || -n ${SMS_PLAN_CONFIRMED:-} ]]; then confirm_pacman=--noconfirm; fi
  if [[ -n ${SMS_YES:-} ]]; then confirm_paru='--noconfirm --skipreview'; fi

  if [[ ${#pacman_want[@]} -gt 0 ]]; then
    # -Syu: sync the database and upgrade first; a plain -S against a stale database 404s on
    # the mirrors, and a partial -Sy install is unsupported on Arch.
    # shellcheck disable=SC2086
    sudo pacman -Syu --needed $confirm_pacman "${pacman_want[@]}"
  else
    sms_note 'pacman: all present'
  fi

  [[ ${#aur_want[@]} -gt 0 ]] || return 0
  if ! command -v paru >/dev/null 2>&1; then
    sms_warn "paru is not installed; from the AUR, by hand: ${aur_want[*]}"
    return 0
  fi
  # paru imports PKGBUILD signing keys with gpg, which fails when $GNUPGHOME (fish sets it
  # to ~/.local/share/gnupg) does not exist yet.
  install -d -m 700 "${GNUPGHOME:-$HOME/.gnupg}"
  # shellcheck disable=SC2086
  paru -S --needed $confirm_paru "${aur_want[@]}"
}
