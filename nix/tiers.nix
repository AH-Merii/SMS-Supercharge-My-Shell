# The printed view of what the declarations compute to. A directory listing does not show the
# tiers -- that is the cost ADR 0001 accepted -- so this is where to look: per platform, what
# Shell and Desktop contain and where each program is installed from.
{ lib, writeShellScriptBin }:
{ configurations, tiers, platforms }:
let
  titles = { shell = "Shell"; desktop = "Desktop"; };

  pad = width: s: s + lib.concatStrings (lib.genList (_: " ") (lib.max 0 (width - lib.stringLength s)));
  row = name: source: what: "    ${pad 24 name}${pad 10 source}${what}";

  programRows = c: lib.mapAttrsToList (name: p: row name p.source p.package) c.config.sms.programs;

  # What is left of a distro list once the programs' own packages are taken out is the
  # platform's own: the session stack that belongs to no one program.
  platformRow = c: source:
    let
      own = lib.subtractLists
        (map (p: p.package) (lib.filter (p: p.source == source) (lib.attrValues c.config.sms.programs)))
        c.config.sms.${source};
    in lib.optional (own != [ ])
      (row "platforms/${c.config.sms.platform}" source (lib.concatStringsSep ", " own));

  tierRows = platform: tier:
    let name = "${tier}-${platform}";
    in [ "  ${titles.${tier}}" ] ++ (
      if configurations ? ${name}
      then let c = configurations.${name};
        in programRows c ++ platformRow c "pacman" ++ platformRow c "aur"
      else [ "    no configuration" ]);

  report = lib.concatMapStrings (line: line + "\n") (lib.concatMap
    (platform: [ platform "" ] ++ lib.concatMap (tier: tierRows platform tier ++ [ "" ]) tiers)
    platforms);
in
writeShellScriptBin "tiers" ("cat <<'REPORT'\n" + report + "REPORT\n")
