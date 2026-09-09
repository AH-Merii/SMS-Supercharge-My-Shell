# shellcheck shell=bash
# Windows Terminal, seen from WSL. Sourced by lib/plan.sh and mise-tasks/winterm, never run.
#
# Its settings.json lives on the Windows side, out of stow's reach, so the theme gets there
# by editing that file through /mnt/c. Everything is derived from the ghostty theme at the
# time it runs, so base/ghostty/.config/ghostty/themes/OneDark stays the only place the
# palette is defined (README, Colours). Slots 16 and up have no place in a Windows
# Terminal scheme; fish sets those itself (conf.d/08-palette.fish).

[ -n "${_SMS_WINTERM:-}" ] && return 0
_SMS_WINTERM=1

winterm_theme=${MISE_PROJECT_ROOT:?}/base/ghostty/.config/ghostty/themes/OneDark
# Microsoft's own Nerd Font build of Cascadia (cursive italic, ligatures, the glyphs), and
# it ships inside Windows Terminal, so nothing is installed on the Windows side.
winterm_font='Cascadia Code NF'

winterm_is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }

# Where settings.json is, as a /mnt path: the Store app, its Preview, or an unpackaged
# install, whichever exists. SMS_WINTERM_SETTINGS=<path> skips the search.
winterm_settings() {
  if [[ -n ${SMS_WINTERM_SETTINGS:-} ]]; then
    printf '%s\n' "$SMS_WINTERM_SETTINGS"
    return 0
  fi
  local cmd=/mnt/c/Windows/System32/cmd.exe appdata p
  [[ -x $cmd ]] || return 1
  # Run from /mnt/c: given a WSL cwd, cmd.exe warns about UNC paths on stderr and carries
  # on from C:\, which is harmless but noisy. An unset variable echoes back as its name.
  appdata=$(cd /mnt/c && "$cmd" /c 'echo %LOCALAPPDATA%' 2>/dev/null | tr -d '\r') || return 1
  [[ -n $appdata && $appdata != %* ]] || return 1
  appdata=$(wslpath -u "$appdata") || return 1
  for p in \
    "$appdata/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json" \
    "$appdata/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json" \
    "$appdata/Microsoft/Windows Terminal/settings.json"; do
    if [[ -f $p ]]; then
      printf '%s\n' "$p"
      return 0
    fi
  done
  return 1
}

# The scheme, as JSON: the ghostty theme's background, foreground, cursor and selection
# colours and its sixteen slots, under the names Windows Terminal uses. Named after the
# theme file, so a renamed theme replaces rather than duplicates. Fails if the theme is
# missing any of them, rather than writing a scheme with holes.
winterm_scheme() {
  local -A c=()
  local key val i
  while IFS="=" read -r key val; do
    c[${key%%-*}]=$val # cursor-color -> cursor, selection-background -> selection
  done < <(sed -nE \
    -e 's/^(background|foreground|cursor-color|selection-background)[[:space:]]*=[[:space:]]*(#[0-9a-fA-F]{6}).*/\1=\2/p' \
    -e 's/^palette[[:space:]]*=[[:space:]]*([0-9]+)=(#[0-9a-fA-F]{6}).*/\1=\2/p' \
    "$winterm_theme")
  local names=(black red green yellow blue purple cyan white
    brightBlack brightRed brightGreen brightYellow brightBlue brightPurple brightCyan brightWhite)
  local args=(
    --arg name "$(basename "$winterm_theme")"
    --arg background "${c[background]:-}"
    --arg foreground "${c[foreground]:-}"
    --arg cursorColor "${c[cursor]:-}"
    --arg selectionBackground "${c[selection]:-}"
  )
  for i in "${!names[@]}"; do
    args+=(--arg "${names[$i]}" "${c[$i]:-}")
  done
  jq -n "${args[@]}" '
    $ARGS.named
    | if any(.[]; . == "") then error("theme is missing a colour: " + ([to_entries[] | select(.value == "") | .key] | join(", "))) else . end
  '
}

# settings.json ($1) with the scheme installed and made the default, the font set, and
# bold kept as a weight rather than a jump to the bright slot (the default, "all", would
# turn a bold slot 0 into slot 8). Defaults cover every profile; the WSL profiles get the
# same three explicitly, so a value set on one of them cannot shadow the defaults.
winterm_render() {
  jq --indent 4 --argjson scheme "$(winterm_scheme)" --arg font "$winterm_font" '
    if (.profiles | type) != "object" then
      error("profiles is a list; this settings.json predates Windows Terminal 1.0")
    else . end
    | .schemes = ((.schemes // []) | map(select(.name != $scheme.name)) + [$scheme])
    | .profiles.defaults |= (
        del(.fontFace)
        | .colorScheme = $scheme.name
        | .intenseTextStyle = "bold"
        | .font.face = $font)
    | .profiles.list |= ((. // []) | map(
        if .source == "Windows.Terminal.Wsl" then
          del(.fontFace)
          | .colorScheme = $scheme.name
          | .intenseTextStyle = "bold"
          | .font.face = $font
        else . end))
  ' "$1"
}

# Whether $2 (rendered settings) says the same as the file $1, ignoring layout.
winterm_same() {
  [[ $(jq -S . "$1" 2>/dev/null) == "$(jq -S . <<<"$2")" ]]
}
