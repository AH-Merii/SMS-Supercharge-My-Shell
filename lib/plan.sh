# shellcheck shell=bash
# What a task would do, without doing it. Sourced, never run.
#
# `setup` and the individual tasks both call these, so the combined plan and the
# standalone previews are the same code and cannot drift.
#
# Every plan_* reads from $MISE_PROJECT_ROOT, never from $HOME: the plan is computed
# before `link` has stowed anything, so on a fresh machine $HOME holds none of it yet.
# Every detector is guarded with `command -v` and degrades to a note rather than an
# empty list, since the plan runs before `deps` installs the tools it inspects.

# $profile and $layers come from mise-tasks/profile, which every caller sources first.
# shellcheck disable=SC2154

[ -n "${_SMS_PLAN:-}" ] && return 0
_SMS_PLAN=1

# shellcheck source=lib/ui.sh
source "${MISE_PROJECT_ROOT:?}/lib/ui.sh"

# Package names from a pkglist, minus comments and blanks.
pkgs() { grep -hv '^#' "$@" | grep -v '^$'; }

# Stow package names in a layer.
layer_pkgs() { ls -1 "$1"; }

_n() { [[ $1 == 1 ]] && printf '1 %s' "$2" || printf '%d %ss' "$1" "$2"; }

# How many `will back up` lines to print before collapsing to a count.
_SMS_BACKUP_MAX=${SMS_BACKUP_MAX:-12}

# Split "$@" against a newline-separated set, into the _have and _want arrays.
_split_by_installed() {
  local set=$1 p
  shift
  local -A seen=()
  while IFS= read -r p; do [[ -n $p ]] && seen[$p]=1; done <<<"$set"
  _have=() _want=()
  for p in "$@"; do
    if [[ -n ${seen[$p]:-} ]]; then _have+=("$p"); else _want+=("$p"); fi
  done
}

# Same, but the set lists what is *missing* (what `pacman -T` reports).
_split_by_missing() {
  local set=$1 p
  shift
  local -A gone=()
  while IFS= read -r p; do [[ -n $p ]] && gone[$p]=1; done <<<"$set"
  _have=() _want=()
  for p in "$@"; do
    if [[ -n ${gone[$p]:-} ]]; then _want+=("$p"); else _have+=("$p"); fi
  done
}

_show_split() {
  [[ ${#_have[@]} -gt 0 ]] && sms_have "${_have[@]}"
  if [[ ${#_want[@]} -gt 0 ]]; then
    sms_want "${_want[@]}"
  else
    sms_note 'all present'
  fi
  return 0
}

# --- OS packages ------------------------------------------------------------------

_plan_pacman() {
  local lists=("$MISE_PROJECT_ROOT/pkglist/arch.txt") wanted=() missing
  [[ $profile == desktop ]] && lists+=("$MISE_PROJECT_ROOT/pkglist/arch-desktop.txt")
  mapfile -t wanted < <(pkgs "${lists[@]}")
  [[ ${#wanted[@]} -gt 0 ]] || return 0

  # `pacman -T` prints exactly the not-installed ones and exits 127 when there are any,
  # so it needs `|| true`. Declare `missing` separately: `local x=$(...)` would mask it.
  missing=$(pacman -T "${wanted[@]}" 2>/dev/null) || true
  _split_by_missing "$missing" "${wanted[@]}"

  # `deps` runs `pacman -Syu`, a full system upgrade, not just these N packages.
  sms_section pacman "full system upgrade (-Syu) + $(_n ${#_want[@]} 'new package')"
  _show_split
}

_plan_aur() {
  [[ $profile == desktop ]] || return 0
  local wanted=() missing
  mapfile -t wanted < <(pkgs "$MISE_PROJECT_ROOT/pkglist/aur.txt")
  [[ ${#wanted[@]} -gt 0 ]] || return 0
  missing=$(pacman -T "${wanted[@]}" 2>/dev/null) || true
  _split_by_missing "$missing" "${wanted[@]}"

  if ! command -v paru >/dev/null 2>&1; then
    # deps guards its paru call on `command -v paru`, and paru is in no pkglist, so
    # without it these are skipped in silence today.
    sms_section AUR 'paru not installed'
    sms_warn "paru not installed - $(_n ${#_want[@]} 'AUR package') will be SKIPPED"
    [[ ${#_want[@]} -gt 0 ]] && sms_note "skipped: ${_want[*]}"
    return 0
  fi

  sms_section 'AUR (paru)' "$(_n ${#wanted[@]} package)"
  _show_split
  if [[ -n ${SMS_YES:-} && ${#_want[@]} -gt 0 ]]; then
    sms_warn '--yes: installing without the PKGBUILD review (--skipreview)'
  fi
}

_plan_apt() {
  local wanted=() installed
  mapfile -t wanted < <(pkgs "$MISE_PROJECT_ROOT/pkglist/debian.txt")
  [[ ${#wanted[@]} -gt 0 ]] || return 0

  # db:Status-Status, not a bare -W: the latter reports removed-but-not-purged packages
  # as installed. ${Package}, not ${binary:Package}: that appends :i386-style suffixes
  # which would never match the pkglist names.
  installed=$(dpkg-query -f '${db:Status-Status} ${Package}\n' -W 2>/dev/null |
    awk '$1 == "installed" { print $2 }') || true
  _split_by_installed "$installed" "${wanted[@]}"
  sms_section apt "$(_n ${#wanted[@]} package)"
  _show_split
}

_plan_brew() {
  local wanted=() installed out=''
  # `brew bundle list` evaluates the Brewfile's `if OS.mac?` block; the file cannot be
  # grepped directly. Not `brew bundle check --verbose`: its wording churns between
  # releases and it exits 1 whenever anything is missing.
  #
  # Filtered to plausible package names rather than trusted wholesale: if a future brew
  # drops --all or changes the output, a diagnostic would otherwise be rendered as a
  # list of things to install.
  out=$(brew bundle list --file="$MISE_PROJECT_ROOT/Brewfile" --all 2>/dev/null) || out=''
  mapfile -t wanted < <(printf '%s\n' "$out" | grep -E '^[A-Za-z0-9@._+-]+$' || true)
  if [[ ${#wanted[@]} -eq 0 ]]; then
    sms_section Homebrew ''
    sms_note 'could not list Brewfile entries; brew bundle will resolve them'
    return 0
  fi
  installed=$({
    brew list --formula -1 2>/dev/null
    brew list --cask -1 2>/dev/null
  }) || true
  _split_by_installed "$installed" "${wanted[@]}"
  sms_section Homebrew "$(_n ${#wanted[@]} package)"
  _show_split
}

plan_os_packages() {
  if command -v pacman >/dev/null 2>&1; then
    _plan_pacman
    _plan_aur
  elif command -v apt-get >/dev/null 2>&1; then
    if command -v dpkg-query >/dev/null 2>&1; then
      _plan_apt
    else
      sms_section apt ''
      sms_note 'dpkg-query unavailable; cannot tell what is already installed'
    fi
  fi
  # Separate `if`, mirroring deps: brew bundle runs whenever brew is on PATH.
  command -v brew >/dev/null 2>&1 && _plan_brew
  return 0
}

# --- stow -------------------------------------------------------------------------

# Everything `stow -R` would object to, as "backup <relpath>" and "warn <message>"
# lines. One dry run, callers filter. Pure: no side effects.
#
# The four backup patterns are stow's four "something is already there" messages
# (Stow.pm, 2.4.1). The "stowed to a different package" one carries a `path => dest`
# payload, hence the ` =>.*` strip -- without it the layout-change case that this
# repo's link header promises to handle would capture junk.
stow_issues() {
  local layer=$1
  shift
  local out
  out=$(stow -n -d "$layer" -R "$@" 2>&1 || true)
  printf '%s\n' "$out" | sed -nE \
    -e 's/^ *\* existing target is not owned by stow: (.+)$/backup \1/p' \
    -e 's/^ *\* existing target is stowed to a different package: (.+) =>.*$/backup \1/p' \
    -e 's/^ *\* cannot stow [^ ]+ over existing target (.+) since neither a link nor a directory.*$/backup \1/p' \
    -e 's/^ *\* cannot stow non-directory .+ over existing directory target (.+)$/backup \1/p' \
    -e 's/^ *\* (source is an absolute symlink .+)$/warn \1/p'
}

stow_conflicts() { stow_issues "$@" | sed -n 's/^backup //p'; }

plan_links() {
  sms_section stow "$(_n ${#layers[@]} layer)"
  local layer lpkgs=() issues=() conflicts=() warns=() line
  for layer in "${layers[@]}"; do
    mapfile -t lpkgs < <(layer_pkgs "$MISE_PROJECT_ROOT/$layer")
    _sms_list "$c_dim" "$layer" "${lpkgs[*]}"
    command -v stow >/dev/null 2>&1 || continue
    mapfile -t issues < <(stow_issues "$MISE_PROJECT_ROOT/$layer" "${lpkgs[@]}")
    for line in "${issues[@]}"; do
      case $line in
        'backup '*) conflicts+=("${line#backup }") ;;
        'warn '*) warns+=("${line#warn }") ;;
      esac
    done
  done

  if ! command -v stow >/dev/null 2>&1; then
    sms_note 'stow not installed yet; conflicts will be checked during link'
    return 0
  fi

  # Capped: on a machine with a lot of pre-existing config this list runs to hundreds of
  # lines and buries the rest of the plan.
  local shown=0 c
  for c in "${conflicts[@]}"; do
    [[ $shown -ge $_SMS_BACKUP_MAX ]] && break
    if [[ $shown == 0 ]]; then
      printf '    %s%-18s%s %s -> %s.bak\n' "$c_yellow" 'will back up' "$c_reset" "$c" "$c"
    else
      printf '    %-18s %s -> %s.bak\n' '' "$c" "$c"
    fi
    shown=$((shown + 1))
  done
  if [[ ${#conflicts[@]} -gt $shown ]]; then
    sms_note "... and $((${#conflicts[@]} - shown)) more (all moved to <name>.bak, never overwritten)"
  fi
  for c in "${warns[@]}"; do sms_warn "$c"; done
  return 0
}

plan_unlink() {
  sms_section stow "$(_n ${#layers[@]} layer)"
  local layer lpkgs=()
  for layer in "${layers[@]}"; do
    mapfile -t lpkgs < <(layer_pkgs "$MISE_PROJECT_ROOT/$layer")
    _sms_list "$c_dim" "$layer" "${lpkgs[*]}"
  done
  sms_warn 'every symlink for these packages will be removed'
}

# --- mise tools -------------------------------------------------------------------

plan_tools() {
  local cfg=$MISE_PROJECT_ROOT/base/mise/.config/mise/config.toml
  if [[ ! -f $cfg ]]; then
    sms_section 'mise tools' ''
    sms_note 'no base/mise/.config/mise/config.toml in the repo'
    return 0
  fi

  # Read the repo's config rather than asking mise to resolve one: on a fresh machine
  # the global config is only stowed by `link`, which runs after this is printed.
  # Names in the [tools] block match `mise ls` output exactly, github:/npm: keys
  # included, once the quotes come off.
  local wanted=()
  mapfile -t wanted < <(awk '
    /^\[tools\]/ { t = 1; next }
    /^\[/        { t = 0 }
    t && /^[^#[:space:]]/ {
      split($0, kv, "=")
      gsub(/^[ \t]+|[ \t]+$/, "", kv[1])
      gsub(/^"|"$/, "", kv[1])
      if (kv[1] != "") print kv[1]
    }
  ' "$cfg")
  [[ ${#wanted[@]} -gt 0 ]] || return 0

  # Deliberately not `mise ls --missing`: that resolves every `latest` over the network,
  # which on a cold machine is tens of seconds of silence before the prompt appears.
  # MISE_GLOBAL_CONFIG_FILE is not in `mise settings ls`, so treat it as version-coupled
  # and fall back to a note rather than letting a mise upgrade break setup.
  local installed
  if ! installed=$(MISE_GLOBAL_CONFIG_FILE=$cfg mise ls --installed --no-header 2>/dev/null |
    awk '{ print $1 }'); then
    sms_section 'mise tools' "$(_n ${#wanted[@]} tool)"
    sms_note 'could not determine which tools are installed; mise install will sort it out'
    return 0
  fi

  _split_by_installed "$installed" "${wanted[@]}"
  sms_section 'mise tools' "${#_want[@]} of ${#wanted[@]} missing"
  _show_split
}

# --- plugins ----------------------------------------------------------------------

plan_plugins() {
  sms_section plugins ''

  local fp=$MISE_PROJECT_ROOT/base/fish/.config/fish/fish_plugins
  if [[ -f $fp ]]; then
    local fish_count
    fish_count=$(grep -cv '^[[:space:]]*$' "$fp" || true)
    if command -v fish >/dev/null 2>&1 && fish -c 'functions -q fisher' 2>/dev/null; then
      sms_note "fisher present; will sync $(_n "$fish_count" 'fish plugin') (fisher update)"
    else
      sms_want "fisher + $(_n "$fish_count" 'fish plugin')"
    fi
  fi

  local tconf=$MISE_PROJECT_ROOT/base/tmux/.config/tmux/plugins.tmux.conf
  [[ -f $tconf ]] || return 0
  local dir=${XDG_CONFIG_HOME:-$HOME/.config}/tmux/plugins
  local repos=() have=() want=() r
  mapfile -t repos < <(sed -nE "s/^[[:space:]]*set -g @plugin '([^']+)'.*/\1/p" "$tconf")
  for r in "${repos[@]}"; do
    if [[ -d $dir/${r##*/} ]]; then have+=("${r##*/}"); else want+=("${r##*/}"); fi
  done
  [[ ${#have[@]} -gt 0 ]] && sms_have "${have[@]}"
  [[ ${#want[@]} -gt 0 ]] && sms_want "${want[@]}"
  return 0
}
