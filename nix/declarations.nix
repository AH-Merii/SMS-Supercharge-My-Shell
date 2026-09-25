# Every program's declaration, read off programs/. Reading the declarations is shared; what
# they mean is not. The tier and platform rules are restated in each check on purpose, so that
# a check cannot come to agree with the linker by running the linker's own code.
{ lib }:
dir:
lib.genAttrs
  (lib.attrNames (lib.filterAttrs (_: kind: kind == "directory") (builtins.readDir dir)))
  (name: import (dir + "/${name}/program.nix"))
