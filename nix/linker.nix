# Walks programs/ and the selected platform directory and turns what belongs to the selected
# tier and platform into the configuration's files, its Nix packages, and the lists the distro
# installs. One file entry per file, never per directory, so every directory under ~ stays a
# real directory and runtime files beside a managed one are untouched. Live files point at the
# checkout string, not the store; a file a program names as applied points into the store, so
# it rolls back with the packages.
{ lib, pkgs, mkOutOfStoreSymlink }:
{ tier, platform, checkout, programsDir, platformsDir }:
let
  # Desktop is Shell and more: a Shell program is in every tier.
  tiers = if tier == "desktop" then [ "shell" "desktop" ] else [ "shell" ];

  # Where a program can come from. The first two this configuration installs itself: a nixpkgs
  # attribute, or a package.nix in a program's own directory, for what nixpkgs does not carry.
  # The rest become lists handed to the distro's own install step, which owns the Linux session
  # stack, and are named separately because `distro` is keyed by exactly them.
  distroSources = [ "pacman" "aur" ];
  sources = [ "nixpkgs" "repo" ] ++ distroSources;

  notLinked = [ "program.nix" "package.nix" "README.md" ];

  filesUnder = dir: rel:
    lib.concatLists (lib.mapAttrsToList (name: kind:
      let path = if rel == "" then name else "${rel}/${name}";
      in if kind == "directory" then filesUnder (dir + "/${name}") path else [ path ])
      (builtins.readDir dir));

  vocabulary = import ./vocabulary.nix;

  # mkOutOfStoreSymlink never looks at its target, so a checkout that is not there would build
  # and activate, scattering dangling links across ~ that surface much later as "no such file".
  reachableCheckout =
    if !(builtins.pathExists checkout) then
      throw "sms.checkout is ${checkout}, and there is nothing there; point SMS_CHECKOUT at the checkout the live links should reach"
    else if !(builtins.pathExists "${checkout}/programs") then
      throw "sms.checkout is ${checkout}, which holds no programs/, so it is not a checkout of this repo"
    else checkout;

  # A tier or platform we do not have selects nothing, so a typo would install a program
  # nowhere with every check still green -- the declaration and the configurations would agree
  # it belongs to none. An applied file naming nothing the program ships is the same silence.
  named = name: decl:
    let
      unknown = lib.subtractLists vocabulary.platforms (lib.attrNames decl.install);
      missing = lib.subtractLists (filesUnder (programsDir + "/${name}") "") (decl.applied or [ ]);
    in if !(lib.elem decl.tier vocabulary.tiers)
    then throw "programs/${name}: tier ${decl.tier} is not one of ${lib.concatStringsSep ", " vocabulary.tiers}"
    else if unknown != [ ]
    then throw "programs/${name}: install names ${lib.concatStringsSep ", " unknown}, and the platforms are ${lib.concatStringsSep ", " vocabulary.platforms}"
    else if missing != [ ]
    then throw "programs/${name}: applied names ${lib.concatStringsSep ", " missing}, which the program does not ship"
    else decl;

  declarations = lib.mapAttrs named (import ./declarations.nix { inherit lib; } programsDir);
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

  platformDecl = import (platformsDir + "/${platform}/platform.nix");

  # A union, so a package a program and the platform both name is installed once.
  listFrom = source: lib.sort (a: b: a < b) (lib.unique (
    lib.mapAttrsToList (_: p: p.package) (lib.filterAttrs (_: p: p.source == source) programs)
    ++ lib.concatMap (t: platformDecl.${t}.${source} or [ ]) tiers));

  # One entry per file a selected program ships, carrying the program it came from so that a
  # path two programs claim can be reported with both their names.
  entriesOf = name:
    let decl = selected.${name};
    in map (rel: {
      program = name;
      inherit rel;
      value.source =
        if lib.elem rel (decl.applied or [ ])
        then programsDir + "/${name}/${rel}"
        else mkOutOfStoreSymlink "${reachableCheckout}/programs/${name}/${rel}";
    }) (lib.subtractLists notLinked (filesUnder (programsDir + "/${name}") ""));

  entries = lib.concatMap entriesOf (lib.attrNames selected);

  # concatMapAttrs would merge two programs' link sets silently, last one alphabetically
  # winning, and no check compares paths: the loser would simply not be there. Refuse instead,
  # naming the path and everyone who claims it.
  claimants = lib.foldl'
    (acc: e: acc // { ${e.rel} = (acc.${e.rel} or [ ]) ++ [ e.program ]; })
    { } entries;
  contested = lib.filterAttrs (_: names: lib.length names > 1) claimants;

  # seq, so the checkout is reached whatever a configuration turns out to contain: nothing
  # else here forces it unless some program ships a live file, and a configuration of applied
  # files alone would otherwise accept a checkout that is not there.
  files = builtins.seq reachableCheckout (
    if contested != { }
    then throw (lib.concatStringsSep "; " (lib.mapAttrsToList
      (rel: names: "~/${rel} is claimed by ${lib.concatStringsSep " and " (map (name: "programs/${name}") names)}")
      contested))
    else lib.listToAttrs (map (e: { name = e.rel; inherit (e) value; }) entries));

  fromSource = source: lib.filter (p: p.source == source) (lib.attrValues programs);

  # Checked by hand so a typo is a named refusal rather than callPackage's bare
  # "path does not exist".
  inRepo = p:
    let file = programsDir + "/${p.package}/package.nix";
    in if builtins.pathExists file then pkgs.callPackage file { }
    else throw "install.repo names ${p.package}, and there is no programs/${p.package}/package.nix";
in {
  inherit programs files;
  packages =
    map (p: lib.getAttrFromPath (lib.splitString "." p.package) pkgs) (fromSource "nixpkgs")
    ++ map inRepo (fromSource "repo");
  distro = lib.genAttrs distroSources listFrom;
}
