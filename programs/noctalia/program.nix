# pacman keeps it: Noctalia is the bar, the launcher and the greeter's look in one, and the
# distro packages it beside the greeter that shares that look. settings.toml is live because
# Noctalia rewrites it, and the palette rides along with it.
#
# On 5.1.0 `noctalia config validate` flags capsule and color on widget.cat and color on
# widget.wallhaven as unknown. The shell applies them (the wallhaven icon goes white without
# its color); the validator is what is wrong, fixed upstream after 5.1.0. This note cannot sit
# beside the keys because Noctalia writes settings.toml back without comments. Two keys that
# 5.0 moved, shell.ui_scale to [accessibility] ui_scale and shell.launcher.session_search to
# [shell.launcher.providers.session] global, were dropped rather than followed: both had run
# at their defaults since the move, and the look stays as it was.
{
  tier = "desktop";
  install.linux.pacman = "noctalia";
}
