# A runtime is an ordinary tool, and mise owns nothing but a project's pin. The two halves of
# that decision are one check because they are one decision: every machine's default node, bun,
# go, rust and python toolchain comes from the lock file, and mise's global config declares
# nothing that could shadow it in every directory.
#
# The runtimes are named here rather than read off programs/, because naming them is the point:
# a declaration deleted or renamed should fail this, not quietly redefine what a Shell machine
# has. What each one installs is still read from its declaration, so the check does not also
# own the package names.
{ lib, pkgs, runCommand, configuration, programsDir }:
let
  runtimes = [ "bun" "go" "node" "rust" "uv" ];

  declarations = import ../declarations.nix { inherit lib; } programsDir;
  inherit (configuration.config.sms) platform;

  # Store paths rather than names: a declaration names a nixpkgs attribute, and an attribute
  # is not always its package's name -- nodejs_22 is the nodejs package -- so comparing the
  # two strings would report a runtime as missing while it sat in the set.
  installed = map (pkg: pkg.outPath) configuration.config.home.packages;

  missing = lib.concatMap (name:
    if !(declarations ? ${name})
    then [ "there is no programs/${name}" ]
    else let attribute = declarations.${name}.install.${platform}.nixpkgs or null; in
      if attribute == null
      then [ "programs/${name} does not install from nixpkgs on ${platform}" ]
      else lib.optional
        (!(lib.elem (lib.getAttrFromPath (lib.splitString "." attribute) pkgs).outPath installed))
        "programs/${name} declares ${attribute}, which is not in the package set")
    runtimes;

  mise = programsDir + "/mise/.config/mise/config.toml";
in
runCommand "runtimes-and-pins-${configuration.config.sms.tier}-${platform}"
{
  inherit mise;
  missing = lib.concatMapStrings (line: line + "\n") missing;
  passAsFile = [ "missing" ];
} ''
  status=0

  if [ -s "$missingPath" ]; then
    echo "every runtime must be a tool of this configuration:"
    cat "$missingPath"
    status=1
  fi

  # A mise config declares tools under [tools] and nowhere else, so its absence is what says
  # the global config installs nothing.
  if grep -qE '^[[:space:]]*\[tools' "$mise"; then
    echo "mise's global config declares tools, and must declare none:"
    grep -nE '^[[:space:]]*\[tools' "$mise"
    status=1
  fi

  [ $status -eq 0 ] || exit 1
  touch "$out"
''
