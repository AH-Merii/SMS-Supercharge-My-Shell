# shellcheck shell=bash
# One switch in its three pieces, so `switch` and `setup` run the same code: whose home this
# is and what the switch will do to it (sms_switch_scan), the preview of that
# (sms_switch_show) and the activation (sms_switch_activate). Sourced, never run.
#
# The preview follows the rules of the activation it precedes, so the two cannot disagree:
# a path home-manager already links is relinked in silence; a regular file or directory at a
# managed path is moved to <path>.<ext> first, whatever its content; a link home-manager does
# not own is replaced without a backup when it reaches the same content, and refused when it
# does not, because home-manager backs up files and never links. Links of the current
# generation that the new one drops are removed.

[ -n "${_SMS_SWITCH:-}" ] && return 0
_SMS_SWITCH=1

# shellcheck source=lib/configuration.sh
source "${MISE_PROJECT_ROOT:?}/lib/configuration.sh"

# --- whose home ---------------------------------------------------------------------

# The activation script carries the username the configuration was built for, and checks
# it against USER itself; it is read back here so the refusal comes before the activation's
# sanity run, which already creates the profile directories. The current generation is
# checked too: a switch run as another user in this home (sudo, say) builds cleanly for that
# user, and the generation already here is what says whose home it is.
_sms_username_of() { # _sms_username_of <generation>
  local line name
  line=$(grep -m1 'checkStringEq USER ' "$1/activate") || return 1
  # Shell-escaped, so a name of unusual characters arrives in single quotes.
  name=${line#*checkStringEq USER \"\$USER\" }
  name=${name#\'}
  printf '%s\n' "${name%\'}"
}

# What home-manager counts as its own link: one into any generation's files.
_sms_managed="$(readlink -e /nix/store)/*-home-manager-files/*"
# shellcheck disable=SC2053  # a glob, matched unquoted on purpose
_sms_owned() { [[ $(readlink "$1" 2>/dev/null) == $_sms_managed ]]; }

# The names of the packages a generation's profile is built from: the profile's direct
# references, less the store hash and the output suffixes that split one package over several.
_sms_packages_of() { # _sms_packages_of <generation>
  local path name output
  for path in $(nix-store --query --references "$(readlink -e "$1/home-path")"); do
    name=${path#/nix/store/}
    name=${name:33}
    for output in man doc bin info dev; do name=${name%-"$output"}; done
    printf '%s\n' "$name"
  done | sort -u
}

# What the switch to $generation would do to this home, into the arrays the preview prints
# and the activation needs: added, removed, link, unlink, backup, blocked, and $ext, the
# backup extension. Refuses before anything is computed when the home is someone else's.
sms_switch_scan() {
  local user state gen expected
  user=${USER:-$(id -un)}
  state=${XDG_STATE_HOME:-$HOME/.local/state}
  current=''
  if [[ -e $state/home-manager/gcroots/current-home ]]; then
    current=$(readlink -e "$state/home-manager/gcroots/current-home")
  fi
  for gen in $generation $current; do
    if ! expected=$(_sms_username_of "$gen"); then
      sms_warn "cannot read who $gen was built for; home-manager checks it on activation"
      continue
    fi
    if [[ $expected != "$user" ]]; then
      sms_err "$HOME is set up for $expected and USER is $user; nothing written"
      exit 1
    fi
  done

  local new_packages old_packages
  new_packages=$(_sms_packages_of "$generation")
  old_packages=''
  [[ -z $current ]] || old_packages=$(_sms_packages_of "$current")
  mapfile -t added < <(comm -13 <(printf '%s\n' "$old_packages") <(printf '%s\n' "$new_packages"))
  mapfile -t removed < <(comm -23 <(printf '%s\n' "$old_packages") <(printf '%s\n' "$new_packages") | grep -v '^$' || true)

  local files source rel target
  files=$(readlink -e "$generation/home-files")

  link=() backup=() blocked=() unchanged=0
  while IFS= read -r -d '' source; do
    rel=${source#"$files/"}
    target=$HOME/$rel
    if [[ -L $target ]]; then
      if [[ ! -e $target ]]; then
        link+=("$rel")
      elif _sms_owned "$target"; then
        if [[ $(readlink -f "$target") == "$(readlink -f "$source")" ]]; then
          unchanged=$((unchanged + 1))
        else
          link+=("$rel")
        fi
      elif cmp -s "$source" "$target"; then
        link+=("$rel")
      else
        blocked+=("$rel")
      fi
    elif [[ -e $target ]]; then
      backup+=("$rel")
    else
      link+=("$rel")
    fi
  done < <(find "$files" \( -type f -o -type l \) -print0)

  unlink=()
  if [[ -n $current && -e $current/home-files ]]; then
    local old_files
    old_files=$(readlink -e "$current/home-files")
    while IFS= read -r -d '' source; do
      rel=${source#"$old_files/"}
      [[ -e $files/$rel ]] && continue
      _sms_owned "$HOME/$rel" && unlink+=("$rel")
    done < <(find "$old_files" \( -type f -o -type l \) -print0)
  fi

  # One extension for the whole switch, as home-manager takes one. `bak` unless a backup of
  # that name is already there, which home-manager would refuse to clobber; then a timestamped
  # one, so nothing already backed up is touched.
  ext=bak
  for rel in "${backup[@]}"; do
    if [[ -e $HOME/$rel.bak ]]; then
      ext="bak.$(date +%Y%m%d%H%M%S)"
      break
    fi
  done
}

# The links in the way that no backup can move: printed and refused, so the activation never
# reaches home-manager's own refusal halfway through.
_sms_switch_refuse_blocked() {
  [[ ${#blocked[@]} -gt 0 ]] || return 0
  local rel
  echo
  sms_err "in the way, and home-manager backs up files but not links; move these aside first:"
  for rel in "${blocked[@]}"; do sms_err "  $rel -> $(readlink "$HOME/$rel")"; done
  exit 1
}

sms_switch_show() {
  sms_header "switch to $configuration"
  sms_note "$generation"

  if [[ -n $current ]]; then
    sms_section packages "${#added[@]} to install, ${#removed[@]} to remove, against the current generation"
  else
    sms_section packages "${#added[@]} to install, no current generation: a first switch"
  fi
  [[ ${#added[@]} -gt 0 ]] && sms_want "${added[@]}"
  [[ ${#removed[@]} -gt 0 ]] && sms_drop "${removed[@]}"
  [[ ${#added[@]} -gt 0 || ${#removed[@]} -gt 0 ]] || sms_note 'no change'

  sms_section files "${#link[@]} to link, $unchanged already linked"
  [[ ${#link[@]} -gt 0 ]] && sms_link "${link[@]}"
  [[ ${#unlink[@]} -gt 0 ]] && sms_unlink "${unlink[@]}"

  if [[ ${#backup[@]} -gt 0 ]]; then
    sms_section backups "${#backup[@]} in the way, each moved to <path>.$ext, then linked"
    sms_backup "${backup[@]}"
  else
    sms_section backups 'nothing in the way'
  fi

  _sms_switch_refuse_blocked
}

sms_switch_activate() {
  _sms_switch_refuse_blocked

  # The activation looks for the user's profile directory and refuses when it is not there.
  # Nix creates it on the first profile operation, and on a Fresh machine this is that
  # operation.
  mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"
  HOME_MANAGER_BACKUP_EXT=$ext "$generation/activate"

  # bat sees the custom theme only through its cache, and refuses a cache a different bat
  # built; the generation's own bat rebuilds it, whatever this shell's PATH still finds.
  local bat=$generation/home-path/bin/bat
  if [[ -x $bat ]]; then
    "$bat" cache --build >/dev/null
    sms_note "rebuilt bat's cache"
  fi

  printf '\n  %sswitched to %s%s\n\n' "$c_bold$c_green" "$configuration" "$c_reset"
}
