# The lists the distro installs are derived, never written down. What a configuration hands to
# pacman (or to the AUR helper) is exactly the union of the programs of its tiers that declare
# that source on its platform and the platform directory's own list. A package can therefore
# not be installed without a program or a platform asking for it, nor asked for and left out,
# nor -- since it is a union -- installed twice because both asked.
{ lib, runCommand, configuration, programsDir, platformsDir, source }:
let
  inherit (configuration.config.sms) tier platform;

  tiers = if tier == "desktop" then [ "shell" "desktop" ] else [ "shell" ];

  declarations = import ../declarations.nix { inherit lib; } programsDir;

  fromPrograms = lib.mapAttrsToList (_: decl: decl.install.${platform}.${source})
    (lib.filterAttrs
      (_: decl: lib.elem decl.tier tiers && (decl.install.${platform} or { }) ? ${source})
      declarations);

  fromPlatform = lib.concatMap
    (t: (import (platformsDir + "/${platform}/platform.nix")).${t}.${source} or [ ])
    tiers;

  # Only the declared side is deduplicated: a duplicate in the derived list is a package the
  # install step would fetch twice, and this check is where that shows.
  lines = packages: lib.concatMapStrings (p: p + "\n") (lib.sort (a: b: a < b) packages);
in
runCommand "${source}-list-${tier}-${platform}"
{
  declared = lines (lib.unique (fromPrograms ++ fromPlatform));
  derived = lines configuration.config.sms.distro.${source};
  passAsFile = [ "declared" "derived" ];
} ''
  diff -u --label declared --label derived "$declaredPath" "$derivedPath" ||
    { echo "the derived ${source} list is not the union of the declarations and the platform list"; exit 1; }
  touch "$out"
''
