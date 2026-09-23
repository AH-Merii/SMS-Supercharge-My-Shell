# The printed view of what the declarations compute to. A directory listing does not show the
# tiers -- that is the cost ADR 0001 accepted -- so this is where to look: per platform, what
# Shell and Desktop contain and where each program is installed from.
{ lib, writeShellScriptBin }:
{ configurations, tiers, platforms }:
let
  titles = { shell = "Shell"; desktop = "Desktop"; };

  # The heredoc that prints the report expands the colour variables, so nothing rendered into
  # it may carry shell syntax of its own. Every name comes from a directory listing, and this
  # is what keeps a directory named `$(...)` from ever being run.
  inert = s:
    if lib.any (syntax: lib.hasInfix syntax s) [ "$" "`" "\\" ]
    then throw "tiers: ${s} carries shell syntax and cannot be printed"
    else s;

  paint = role: text: "\${${role}}${text}\${off}";

  pad = width: s: s + lib.concatStrings (lib.genList (_: " ") (lib.max 0 (width - lib.stringLength s)));
  row = name: source: packages:
    "    ${pad 24 (inert name)}${pad 10 (inert source)}${inert packages}";

  # Program, install source and package are the glossary's words for these three columns.
  heading = paint "dim" (row "PROGRAM" "SOURCE" "PACKAGE");

  programRows = c: lib.mapAttrsToList (name: p: row name p.source p.package) c.config.sms.programs;

  # What is left of a distro list once the programs' own packages are taken out is the
  # platform's own: the session stack that belongs to no one program.
  platformRows = c: lib.concatMap (source:
    let
      own = lib.subtractLists
        (map (p: p.package) (lib.filter (p: p.source == source) (lib.attrValues c.config.sms.programs)))
        c.config.sms.distro.${source};
    in lib.optional (own != [ ])
      (row "platforms/${c.config.sms.platform}" source (lib.concatStringsSep ", " own)))
    (lib.attrNames c.config.sms.distro);

  tierRows = platform: tier:
    let name = "${tier}-${platform}";
    in [ ("  " + paint "tier" titles.${tier}) ] ++ (
      if configurations ? ${name}
      then let c = configurations.${name}; in [ heading ] ++ programRows c ++ platformRows c
      else [ ("    " + paint "dim" "no configuration") ]);

  report = lib.concatMapStrings (line: line + "\n") (lib.concatMap
    (platform: [ (paint "platform" (inert platform)) "" ]
      ++ lib.concatMap (tier: tierRows platform tier ++ [ "" ]) tiers)
    platforms);

  # The terminal owns the palette, so these are ANSI roles rather than colours of ours; they
  # empty out when the output is not a terminal, so a pipe gets plain text.
  colours = ''
    if [ -t 1 ] && [ -z "''${NO_COLOR-}" ]; then
      platform=$'\e[1;35m' tier=$'\e[1;36m' dim=$'\e[2m' off=$'\e[0m'
    else
      platform= tier= dim= off=
    fi
  '';
in
writeShellScriptBin "tiers" (colours + "cat <<REPORT\n" + report + "REPORT\n")
