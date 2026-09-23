# What the Linux session needs that belongs to no one program, keyed by tier the way a
# program's declaration is. pacman keeps the session stack so the greeter, the portals and
# the keyring move together with the compositor and the drivers.
{
  desktop.pacman = [
    "gnome-keyring"
    "greetd"
    "noctalia"
    "noctalia-greeter"
    "xdg-desktop-portal-gnome"
    "xdg-desktop-portal-gtk"
    "xwayland-satellite"
  ];
}
