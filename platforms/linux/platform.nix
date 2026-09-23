# What the Linux session needs that belongs to no one program, keyed by tier the way a
# program's declaration is. pacman keeps the session stack so the greeter, the portals and
# the keyring move together with the compositor and the drivers.
{
  # What every Linux machine needs before Nix owns anything: the toolchain paru builds AUR
  # packages with, and the pieces that are wired into the system rather than into a shell --
  # the SSH and GPG agents the desktop's keyring talks to, and luarocks for the neovim
  # plugins that build against the distro's Lua. git, fish, tmux and mise were on this list
  # and are programs now.
  shell.pacman = [
    "base-devel"
    "gnupg"
    "luarocks"
    "openssh"
    "unzip"
    "wget"
  ];

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
