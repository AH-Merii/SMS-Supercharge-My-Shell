# What belongs to no one program. pacman keeps the session stack so the greeter, the portals
# and the keyring move together with the compositor and the drivers; the compositor and the
# bar are programs of their own and name pacman themselves. What home-manager adds to the
# session -- the fonts, the cursor theme, the environment -- is desktop.nix beside this.
#
# The greeter's files under /etc and /var/lib are root's and are not part of any
# configuration: `mise run greeter` installs them and asks for sudo. Nothing here reaches
# outside ~.
{
  # A build dependency of the aur list rather than a tool anyone runs: makepkg needs the system
  # toolchain at system paths, which no Nix package can stand in for. Everything else a shell
  # needs is a program, so a Linux without pacman reads nothing here.
  shell.pacman = [
    "base-devel"
  ];

  desktop.pacman = [
    "gnome-keyring"
    "greetd"
    "noctalia-greeter"
    "xdg-desktop-portal-gnome"
    "xdg-desktop-portal-gtk"
    "xwayland-satellite"
  ];
}
