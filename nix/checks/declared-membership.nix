# Every program is in exactly the tiers and platforms it declares. The declarations are read
# here from programs/, and the membership they ask for is compared against the configurations
# a program actually turns up in. Desktop is Shell and more, so a Shell program is expected in
# both tiers of every platform it declares.
{ lib, runCommand, configurations, programsDir }:
let
  declarations = import ../declarations.nix { inherit lib; } programsDir;

  tiersOf = decl: if decl.tier == "shell" then [ "shell" "desktop" ] else [ decl.tier ];

  # A pair with no configuration (Desktop on macOS, say) is not a place a program can be.
  declaredIn = decl: lib.filter (name: configurations ? ${name})
    (lib.concatMap (tier: map (platform: "${tier}-${platform}") (lib.attrNames decl.install))
      (tiersOf decl));

  foundIn = name: lib.filter (c: configurations.${c}.config.sms.programs ? ${name})
    (lib.attrNames configurations);

  table = membership: lib.concatMapStrings (line: line + "\n")
    (lib.mapAttrsToList
      (name: decl: "${name}: ${lib.concatStringsSep " " (lib.sort (a: b: a < b) (membership name decl))}")
      declarations);
in
runCommand "declared-membership"
{
  declared = table (_: declaredIn);
  found = table (name: _: foundIn name);
  passAsFile = [ "declared" "found" ];
} ''
  diff -u --label declared --label found "$declaredPath" "$foundPath" ||
    { echo "a program is not in the tiers and platforms it declares"; exit 1; }
  touch "$out"
''
