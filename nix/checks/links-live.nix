# The test the linker exists to pass: what ~ reaches for a program's config is the file in
# the checkout, never a copy in the store, and the files that describe the program are not
# linked at all. The link is followed as far as the store goes; the checkout itself is not
# in the sandbox, so the last hop is compared as a string.
{ runCommand, home }:
let
  files = home.config.home-files;
  checkout = home.config.sms.checkout;
in
runCommand "bat-links-live" { } ''
  live() {
    local target
    target=$(readlink "${files}/$1") || { echo "$1 is not linked"; exit 1; }
    while [[ $target == /nix/store/* ]]; do target=$(readlink "$target"); done
    case $target in
      "${checkout}/"*) echo "$1 -> $target" ;;
      *) echo "$1 -> $target, not under ${checkout}"; exit 1 ;;
    esac
  }
  absent() {
    # -L as well as -e: a live link dangles in the sandbox, and -e alone would miss it.
    [[ ! -e "${files}/$1" && ! -L "${files}/$1" ]] || { echo "$1 is linked and must not be"; exit 1; }
  }

  live .config/bat/config
  live .config/bat/themes/ansi-roles.tmTheme
  absent program.nix
  absent README.md
  touch "$out"
''
