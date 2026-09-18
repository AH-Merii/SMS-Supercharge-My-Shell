# Walks programs/ and turns every program that belongs to the selected tier and platform
# into its home-manager file entries and its package. One entry per file, never per
# directory, so every directory under ~ stays a real directory and runtime files beside a
# managed one are untouched. Live files point at the checkout string, not the store.
{ lib, pkgs, mkOutOfStoreSymlink }:
{ tier, platform, checkout, programsDir }:
let
  # Desktop is Shell and more: a Shell program is in every tier.
  inTier = decl: decl.tier == tier || decl.tier == "shell";
  onPlatform = decl: decl.install ? ${platform};

  # A program's own description is not config; neither is a README.
  notLinked = [ "program.nix" "README.md" ];

  filesUnder = dir: rel:
    lib.concatLists (lib.mapAttrsToList (name: kind:
      let path = if rel == "" then name else "${rel}/${name}";
      in if kind == "directory" then filesUnder (dir + "/${name}") path else [ path ])
      (builtins.readDir dir));

  declarations = lib.mapAttrs (name: _: import (programsDir + "/${name}/program.nix"))
    (lib.filterAttrs (_: kind: kind == "directory") (builtins.readDir programsDir));
  selected = lib.filterAttrs (_: decl: inTier decl && onPlatform decl) declarations;

  linksOf = name:
    lib.listToAttrs (map (rel: {
      name = rel;
      value.source = mkOutOfStoreSymlink "${checkout}/programs/${name}/${rel}";
    }) (lib.subtractLists notLinked (filesUnder (programsDir + "/${name}") "")));

  packageOf = _: decl:
    let how = decl.install.${platform};
    in lib.optional (how ? nixpkgs) (lib.getAttrFromPath (lib.splitString "." how.nixpkgs) pkgs);
in {
  files = lib.concatMapAttrs (name: _: linksOf name) selected;
  packages = lib.concatLists (lib.mapAttrsToList packageOf selected);
}
