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
# it does not: this file is live. So the fragment is read rather than sourced, and only the
# lines that mean the same thing in both shells are taken -- `export NAME="VALUE"` with a
# value carrying neither `$` nor a backtick. A value that would expand is skipped rather than
# mangled: home-manager's sessionPath writes `export PATH="$PATH:..."`, and taken literally
# that replaces PATH with those nine characters and leaves the shell with no commands at all.
# If an expanding variable is ever needed here, the answer is babelfish, which is what
# home-manager's own fish module uses to translate this file.
#
# Names and values are matched separately over the same lines, which keeps a value with a
# space in it in one piece. home-manager's already-sourced flag is unquoted and matches
# neither pattern, so it is left to the shells that source the fragment properly.
set -l hm_vars $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
if test -r $hm_vars
    set -l names (string replace -rf '^export ([A-Za-z_][A-Za-z0-9_]*)="[^"$`]*"$' '$1' <$hm_vars)
    set -l values (string replace -rf '^export [A-Za-z_][A-Za-z0-9_]*="([^"$`]*)"$' '$1' <$hm_vars)
    for i in (seq (count $names))
        set -gx $names[$i] $values[$i]
    end
end
