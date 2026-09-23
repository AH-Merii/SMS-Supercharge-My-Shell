# pacman keeps it: the distro's package is already wired to the GPU drivers and the portals
# beside it. Linux only until the nix-darwin phase, so the config tree is not linked on macOS.
{
  tier = "desktop";
  install.linux.pacman = "ghostty";
}
