# The lists the distro installs are derived, never written down. What a configuration hands to
# pacman (or to the AUR helper) is exactly the programs of its tiers that declare that source
# on its platform, plus the platform directory's own list. A package can therefore not be
# installed without a program or a platform asking for it, nor asked for and left out.
{ lib, runCommand, configuration, programsDir, platformsDir, source }:
let
  inherit (configuration.config.sms) tier platform;

  tiers = if tier == "desktop" then [ "shell" "desktop" ] else [ "shell" ];

  declarations = lib.genAttrs
    (lib.attrNames (lib.filterAttrs (_: kind: kind == "directory") (builtins.readDir programsDir)))
    (name: import (programsDir + "/${name}/program.nix"));

  fromPrograms = lib.mapAttrsToList (_: decl: decl.install.${platform}.${source})
    (lib.filterAttrs
      (_: decl: lib.elem decl.tier tiers && (decl.install.${platform} or { }) ? ${source})
      declarations);

  fromPlatform = lib.concatMap
    (t: (import (platformsDir + "/${platform}/platform.nix")).${t}.${source} or [ ])
    tiers;

  lines = packages: lib.concatMapStrings (p: p + "\n") (lib.sort (a: b: a < b) packages);
in
runCommand "${source}-list-${tier}-${platform}"
{
  declared = lines (fromPrograms ++ fromPlatform);
  derived = lines configuration.config.sms.${source};
  passAsFile = [ "declared" "derived" ];
} ''
  diff -u --label declared --label derived "$declaredPath" "$derivedPath" ||
    { echo "the derived ${source} list is not the union of the declarations and the platform list"; exit 1; }
  touch "$out"
''
