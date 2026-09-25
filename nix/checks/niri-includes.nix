# Every file config.kdl includes has to exist when niri first starts, or niri falls back to
# its built-in config and never starts Noctalia. Runs the activation entry that creates the
# missing ones against a home of the check's own.
{ lib, runCommand, configuration, programsDir }:
let
  inherit (configuration.config.sms) tier platform;

  configDir = ".config/niri";
  config = programsDir + "/niri/${configDir}/config.kdl";

  # Anchored, so a commented-out include is not one; no include at all is a broken check.
  includes =
    let found = lib.concatMap
      (line: let m = builtins.match ''[ 	]*include "([^"]*)".*'' line; in if m == null then [ ] else m)
      (lib.splitString "\n" (builtins.readFile config));
    in if found == [ ] then throw "programs/niri includes nothing, and the check needs one include" else found;

  # An include is relative to the directory config.kdl is in; "./x" and "x" are the same file.
  resolve = inc: "${configDir}/${lib.removePrefix "./" inc}";

  entry = configuration.config.home.activation.noctaliaKdl.data or
    (throw "the ${tier}-${platform} configuration has no home.activation.noctaliaKdl entry to create niri's included file");
in
runCommand "${tier}-${platform}-niri-includes"
{
  paths = lib.concatMapStrings (inc: resolve inc + "\n") includes;
  passAsFile = [ "paths" "entry" ];
  inherit entry;
  files = configuration.config.home-files;
} ''
  status=0
  fail() { echo "$1"; status=1; }

  # The live links dangle in the sandbox; -L sees them where -e would not.
  export HOME=$PWD/home
  mkdir -p "$HOME/.config"
  cp -r --no-preserve=mode "$files/${configDir}" "$HOME/${configDir}"

  # `run` does the command, or only prints it under a dry run, as home-manager's does.
  seed() {
    bash -eu -c 'run() { "$@"; }; source "$1"' seed "$entryPath" ||
      fail "the noctaliaKdl activation entry failed"
  }
  dry() {
    bash -eu -c 'run() { echo "$@"; }; source "$1"' seed "$entryPath" >/dev/null ||
      fail "the noctaliaKdl activation entry failed as a dry run"
  }

  before=$(find "$HOME" | sort)
  dry
  [[ $(find "$HOME" | sort) == "$before" ]] || fail "a dry run of the noctaliaKdl activation entry wrote to the home"

  # A created include has to be a real file, so -e alone.
  seed
  created=()
  while read -r rel; do
    if [[ -e "$files/$rel" || -L "$files/$rel" ]]; then
      continue
    elif [[ -e "$HOME/$rel" ]]; then
      created+=("$rel")
    else
      fail "niri includes ~/$rel, and nothing ships it or creates it, so niri's config fails to load on a Fresh machine"
    fi
  done < "$pathsPath"
  [[ ''${#created[@]} -gt 0 ]] ||
    fail "the noctaliaKdl activation entry creates nothing niri includes"

  for rel in "''${created[@]}"; do
    # Noctalia's content survives a second activation.
    printf 'layout { }\n' > "$HOME/$rel"
    seed
    [[ $(cat "$HOME/$rel") == 'layout { }' ]] ||
      fail "a second activation rewrote ~/$rel, which is Noctalia's once it has written it"

    # A dangling link is no file to niri; the entry replaces it.
    rm "$HOME/$rel"; ln -s /nowhere/"$rel" "$HOME/$rel"
    seed
    [[ -e "$HOME/$rel" ]] ||
      fail "~/$rel was a link to nothing, and the activation left it so; niri fails on it as on no file at all"
  done

  [ $status -eq 0 ] || exit 1
  touch "$out"
''
