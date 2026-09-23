# What the Desktop session on Linux gets from home-manager and no program owns: the fonts, the
# cursor theme, and the environment the compositor's session runs in. greetd starts the
# compositor, not fish, so nothing conf.d puts on the PATH reaches it; environment.d is what
# the systemd user session reads, and everything niri spawns inherits it.
{ config, pkgs, ... }:
{
  # Not NixOS: the profile's share/ has to be named to XDG_DATA_DIRS, and the terminfo and
  # nix.sh paths are not where NixOS keeps them. This writes the data dirs into environment.d.
  targets.genericLinux.enable = true;

  # genericLinux writes the data dirs and leaves the PATH alone. The profile first, then the
  # daemon's default profile that carries nix itself, in front of what the session had.
  systemd.user.sessionVariables.PATH =
    "${config.home.profileDirectory}/bin:/nix/var/nix/profiles/default/bin:$PATH";

  # A conf.d entry naming the profile's fonts; without it they are installed and no program
  # sees them.
  fonts.fontconfig.enable = true;

  # The Nerd Fonts ghostty's config names, with Meslo as a third face and Noto for what none of
  # them cover: the bar's text and the emoji in notifications.
  home.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.caskaydia-cove
    nerd-fonts.meslo-lg
    noto-fonts
    noto-fonts-color-emoji
  ];

  # niri names the theme and the size in its own config and exports them to what it spawns;
  # this puts the theme on the profile so there is one to find and points ~/.icons and
  # ~/.local/share/icons at it for the toolkits that look there. The session check holds the
  # two to the same name and size. No gtk settings: Noctalia writes those.
  home.pointerCursor = {
    enable = true;
    package = pkgs.phinger-cursors;
    name = "phinger-cursors-dark";
    size = 48;
  };
}
