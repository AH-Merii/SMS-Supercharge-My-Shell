# Nix, before anything else in conf.d looks for a tool: home-manager owns every tool this
# machine has, so its profile has to be on PATH before `type -q mise` or `type -q starship`
# below can find one. Runs on every shell, not just interactive ones -- a compositor spawn or
# a `fish -c` needs the same tools to resolve.
#
# Nothing here assumes Nix: a machine without it keeps the PATH it had, so this file is inert
# on a box the setup has not run on.

# The daemon install's default profile carries nix itself; the home-manager profile carries
# everything the configuration installs and goes in front of it.
for profile in /nix/var/nix/profiles/default $HOME/.nix-profile
    test -d $profile/bin; and fish_add_path --prepend --global $profile/bin
end

# The session variables the configuration sets, SMS_CHECKOUT among them. home-manager writes
# them as a POSIX shell fragment and ships no fish flavour unless it owns fish's config, which
# it does not: this file is live. The fragment is generated and uniform -- one
# `export NAME="VALUE"` per line, values quoted and literal -- so reading it is a translation
# and not an evaluation. Names and values are matched separately over the same lines, which
# keeps a value with a space in it in one piece; the one unquoted line, home-manager's
# already-sourced flag, matches neither pattern and is left to the shells that need it.
set -l hm_vars $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
if test -r $hm_vars
    set -l names (string replace -rf '^export ([A-Za-z_][A-Za-z0-9_]*)=".*"$' '$1' <$hm_vars)
    set -l values (string replace -rf '^export [A-Za-z_][A-Za-z0-9_]*="(.*)"$' '$1' <$hm_vars)
    for i in (seq (count $names))
        set -gx $names[$i] $values[$i]
    end
end
