# Homebrew: macOS only, and only for what the casks and the system pieces still need. Under
# WSL2 Nix carries the Shell tier, so linuxbrew has nothing left to provide.
if test "$OS_KIND" = macos
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew
        if test -x $b
            eval ($b shellenv)
            break
        end
    end
end
