# niri is the graphical session itself, so pacman keeps it: the compositor moves with the
# drivers and the portals the distro ships beside it. This directory owns only its config tree.
{
  tier = "desktop";
  install.linux.pacman = "niri";
}
