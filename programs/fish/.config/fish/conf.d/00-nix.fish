# Nix, before anything else in conf.d looks for a tool: home-manager owns every program on
# this machine, so its profile has to be on PATH before `type -q mise` or `type -q starship`
# below can find one. Runs on every shell, not just interactive ones -- a compositor spawn or
# a `fish -c` needs the same tools to resolve.
#
# Nothing here assumes Nix: a machine without it keeps the PATH it had, so this file is inert
# on a box the setup has not run on.

# The daemon install's default profile carries nix itself; the home-manager profile carries
# everything the configuration installs and wins over it.
for profile in /nix/var/nix/profiles/default $HOME/.nix-profile
    test -d $profile/bin; and fish_add_path --prepend --global $profile/bin
end

# home-manager writes the session variables its configuration sets -- SMS_CHECKOUT among them
# -- as a fish script beside the profile. It does not exist until the first switch.
set -l hm_vars $HOME/.nix-profile/etc/profile.d/hm-session-vars.fish
test -r $hm_vars; and source $hm_vars
