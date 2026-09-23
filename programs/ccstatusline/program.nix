# The one program nixpkgs does not carry, so it is installed from `repo`: package.nix beside
# this file. See the spec's rule -- a gap in nixpkgs becomes a small in-repo package and never
# a second package manager.
#
# context-bar.sh is the repo's one applied file. Unlike settings.json, which ccstatusline's own
# TUI rewrites and which therefore has to stay live and writable, the script is only ever
# changed here; copying it into the store makes it roll back with the package that runs it.
{
  tier = "shell";
  applied = [ ".config/ccstatusline/context-bar.sh" ];
  install = {
    linux.repo = "ccstatusline";
    darwin.repo = "ccstatusline";
    wsl.repo = "ccstatusline";
  };
}
