# The test the linker exists to pass: a live file reaches the checkout, an applied file reaches
# the store, and the files describing a program are not linked at all.
#
# Read from programs/ rather than from the linker, so the check cannot come to agree with it by
# running its code. A live link is followed only as far as the store goes -- home-manager puts
# its own store symlink in front of the out-of-store one -- and since the checkout is not in
# the sandbox, the last hop is compared as a string.
{ lib, runCommand, configuration, programsDir }:
let
  inherit (configuration.config.sms) tier platform checkout;

  tiers = if tier == "desktop" then [ "shell" "desktop" ] else [ "shell" ];
  notLinked = [ "program.nix" "package.nix" "README.md" ];

  declarations = import ../declarations.nix { inherit lib; } programsDir;
  selected = lib.filterAttrs
    (_: decl: lib.elem decl.tier tiers && decl.install ? ${platform})
    declarations;

  filesUnder = dir: rel:
    lib.concatLists (lib.mapAttrsToList (name: kind:
      let path = if rel == "" then name else "${rel}/${name}";
      in if kind == "directory" then filesUnder (dir + "/${name}") path else [ path ])
      (builtins.readDir dir));

  shipped = name: filesUnder (programsDir + "/${name}") "";

  partition = name: decl:
    let
      files = shipped name;
      applied = decl.applied or [ ];
    in {
      absent = lib.intersectLists notLinked files;
      inherit applied;
      live = lib.subtractLists (notLinked ++ applied) files;
    };
  parts = lib.mapAttrsToList (name: decl: partition name decl) selected;

  paths = kind: lib.concatMapStrings (p: p + "\n")
    (lib.sort (a: b: a < b) (lib.concatMap (part: part.${kind}) parts));
in
runCommand "files-live-and-applied-${tier}-${platform}"
{
  live = paths "live";
  applied = paths "applied";
  absent = paths "absent";
  passAsFile = [ "live" "applied" "absent" ];
} ''
  files=${configuration.config.home-files}
  status=0

  # The last target a chain of store symlinks reaches, or nothing if the path is not a link.
  final() {
    local target
    target=$(readlink "$files/$1") || return 1
    while [[ $target == /nix/store/* && -L $target ]]; do target=$(readlink "$target"); done
    printf '%s' "$target"
  }

  while read -r rel; do
    if ! target=$(final "$rel"); then
      echo "live $rel is not linked"; status=1; continue
    fi
    case $target in
      "${checkout}/"*) ;;
      *) echo "live $rel reaches $target, which is not under ${checkout}"; status=1 ;;
    esac
  done < "$livePath"

  while read -r rel; do
    if ! target=$(final "$rel"); then
      echo "applied $rel is not linked"; status=1; continue
    fi
    case $target in
      /nix/store/*) ;;
      *) echo "applied $rel reaches $target, which is not in the store"; status=1 ;;
    esac
  done < "$appliedPath"

  # -L as well as -e: a live link dangles in the sandbox, and -e alone would miss it.
  while read -r rel; do
    if [[ -e "$files/$rel" || -L "$files/$rel" ]]; then
      echo "$rel is linked and must not be"; status=1
    fi
  done < "$absentPath"

  [ $status -eq 0 ] || exit 1
  touch "$out"
''
