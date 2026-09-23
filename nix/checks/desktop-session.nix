# The Desktop session sees what the shell sees. The compositor is started by greetd and not
# by fish, so nothing fish puts on the PATH reaches it: the environment.d entry is what puts
# the Nix profile on the session's PATH and data dirs, and this is where its absence shows.
#
# The fonts and the cursor theme are held to the programs that ask for them, read off
# programs/ rather than off the platform module, so the check cannot agree with the module by
# reading the module: every font family ghostty's config names must be one the profile
# carries, and the cursor theme niri's config names must be the one the profile carries and
# the one ~ points the toolkits at.
{ lib, runCommand, fontconfig, configuration, programsDir }:
let
  inherit (configuration.config) home;
  inherit (configuration.config.sms) tier platform;

  lines = file: lib.splitString "\n" (builtins.readFile file);

  # `font-family = "..."` and its bold and italic variants; a commented-out line is not a
  # request, and match is anchored so it does not see one.
  families = lib.unique (lib.concatMap
    (line: let m = builtins.match ''font-family[a-z-]* *= *"([^"]*)"'' line; in if m == null then [ ] else m)
    (lines (programsDir + "/ghostty/.config/ghostty/config")));

  # niri's `xcursor-theme "..."` and `xcursor-size N`, one each.
  one = what: pattern: file:
    let found = lib.concatMap
      (line: let m = builtins.match pattern line; in if m == null then [ ] else m)
      (lines file);
    in if lib.length found == 1 then lib.head found
    else throw "programs/niri names ${toString (lib.length found)} ${what}s, and the check needs one";
  niri = programsDir + "/niri/.config/niri/cfg/misc.kdl";
  niriCursor = one "xcursor-theme" ''[ ]*xcursor-theme "([^"]*)"'' niri;
  niriCursorSize = one "xcursor-size" ''[ ]*xcursor-size ([0-9]+)'' niri;
in
runCommand "${tier}-${platform}-session"
{
  nativeBuildInputs = [ fontconfig ];
  families = lib.concatMapStrings (f: f + "\n") families;
  passAsFile = [ "families" ];
  inherit niriCursor niriCursorSize;
  profile = home.path;
  profileDirectory = home.profileDirectory;
  files = configuration.config.home-files;
} ''
  status=0
  fail() { echo "$1"; status=1; }

  # fontconfig reads the profile's fonts the way the session will, from the conf.d entry
  # fontconfig.enable writes -- and only through it, so the entry is checked by being used.
  # -R, since every file under home-files is a link into the store.
  conf=$(grep -Rl "$profile/share/fonts" "$files/.config/fontconfig/conf.d" 2>/dev/null | head -n1) ||
    fail "fontconfig has no conf.d entry naming the profile's fonts"
  if [ -n "$conf" ]; then
    cat > fonts.conf <<EOF
  <?xml version="1.0"?>
  <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
  <fontconfig>
    <include ignore_missing="yes">$conf</include>
    <cachedir>$PWD/cache</cachedir>
  </fontconfig>
  EOF
    FONTCONFIG_FILE=$PWD/fonts.conf fc-list : family | tr ',' '\n' | sort -u > installed
    while read -r family; do
      grep -Fxq "$family" installed || fail "ghostty asks for the font family $family, which the profile does not carry"
    done < "$familiesPath"
  fi

  [ -d "$profile/share/icons/$niriCursor/cursors" ] ||
    fail "niri asks for the cursor theme $niriCursor, which the profile does not carry"
  for index in .icons/default/index.theme .local/share/icons/default/index.theme; do
    grep -qx "Inherits=$niriCursor" "$files/$index" 2>/dev/null ||
      fail "~/$index does not point the toolkits at $niriCursor"
  done
  grep -qx "export XCURSOR_SIZE=\"$niriCursorSize\"" "$profile/etc/profile.d/hm-session-vars.sh" 2>/dev/null ||
    fail "niri's cursor size is $niriCursorSize and the session's XCURSOR_SIZE is not"

  # environment.d is what the systemd user session reads; the compositor and everything it
  # spawns inherit it. The profile first on both, so a Nix tool shadows a distro one.
  entry=$(cat "$files"/.config/environment.d/*.conf 2>/dev/null) ||
    fail "there is no environment.d entry"
  case $(printf '%s\n' "$entry" | sed -n 's/^PATH=//p') in
    "$profileDirectory/bin:"*) ;;
    *) fail "environment.d does not put $profileDirectory/bin first on the session PATH" ;;
  esac
  printf '%s\n' "$entry" | grep -q "^XDG_DATA_DIRS=.*$profileDirectory/share" ||
    fail "environment.d does not put $profileDirectory/share on the session's XDG_DATA_DIRS"

  [ $status -eq 0 ] || exit 1
  touch "$out"
''
