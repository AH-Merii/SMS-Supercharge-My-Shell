# pacman keeps it on Linux: the distro's package is already wired to the GPU drivers and the
# portals beside it. The macOS cask is declared and not wired: Desktop on macOS waits for the
# nix-darwin phase, and until then no configuration reads it and the config tree is not
# linked there.
{
  tier = "desktop";
  install = {
    linux.pacman = "ghostty";
    darwin.brew = "ghostty";
  };
}
