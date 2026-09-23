# The terminal is part of the graphical session, so it is Desktop and pacman keeps it: a
# Nix-built ghostty on Linux is out of scope for the rebuild, and the distro's package is
# already wired to the GPU drivers and the portals beside it. Only Linux for now; the macOS
# cask waits for the nix-darwin phase, so ghostty's config tree is not linked there yet.
{
  tier = "desktop";
  install.linux.pacman = "ghostty";
}
