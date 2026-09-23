# Walks programs/ and the selected platform directory and turns what belongs to the selected
# tier and platform into the configuration's files, its Nix packages, and the lists the distro
# installs. One file entry per file, never per directory, so every directory under ~ stays a
# real directory and runtime files beside a managed one are untouched. Live files point at the
# checkout string, not the store.
{ lib, pkgs, mkOutOfStoreSymlink }:
{ tier, platform, checkout, programsDir, platformsDir }:
let
  # Desktop is Shell and more: a Shell program is in every tier.
  tiers = if tier == "desktop" then [ "shell" "desktop" ] else [ "shell" ];

  # Where a program can come from. nixpkgs is installed by this configuration; pacman and aur
  # are lists the Linux install step hands to the distro, which owns the session stack.
  sources = [ "nixpkgs" "pacman" "aur" ];

  # A program's own description is not config; neither is a README.
  notLinked = [ "program.nix" "README.md" ];

  dirsIn = dir: lib.attrNames (lib.filterAttrs (_: kind: kind == "directory") (builtins.readDir dir));

  filesUnder = dir: rel:
    lib.concatLists (lib.mapAttrsToList (name: kind:
      let path = if rel == "" then name else "${rel}/${name}";
      in if kind == "directory" then filesUnder (dir + "/${name}") path else [ path ])
      (builtins.readDir dir));

  declarations = lib.genAttrs (dirsIn programsDir)
    (name: import (programsDir + "/${name}/program.nix"));
  selected = lib.filterAttrs
    (_: decl: lib.elem decl.tier tiers && decl.install ? ${platform})
    declarations;

  sourceOf = name: how:
    let named = lib.intersectLists sources (lib.attrNames how);
    in if lib.length named == 1 then lib.head named
    else throw "programs/${name}: install.${platform} must name exactly one of ${lib.concatStringsSep ", " sources}";

  programs = lib.mapAttrs (name: decl:
    let source = sourceOf name decl.install.${platform};
    in {
      inherit (decl) tier;
      inherit source;
      package = decl.install.${platform}.${source};
    }) selected;

  # What the platform needs that belongs to no one program, tiered the way a program is.
  platformDecl = import (platformsDir + "/${platform}/platform.nix");

  listFrom = source: lib.sort (a: b: a < b) (
    lib.mapAttrsToList (_: p: p.package) (lib.filterAttrs (_: p: p.source == source) programs)
    ++ lib.concatMap (t: platformDecl.${t}.${source} or [ ]) tiers);

  linksOf = name:
    lib.listToAttrs (map (rel: {
      name = rel;
      value.source = mkOutOfStoreSymlink "${checkout}/programs/${name}/${rel}";
    }) (lib.subtractLists notLinked (filesUnder (programsDir + "/${name}") "")));
in {
  inherit programs;
  files = lib.concatMapAttrs (name: _: linksOf name) selected;
  packages = map (p: lib.getAttrFromPath (lib.splitString "." p.package) pkgs)
    (lib.filter (p: p.source == "nixpkgs") (lib.attrValues programs));
  pacman = listFrom "pacman";
  aur = listFrom "aur";
}
