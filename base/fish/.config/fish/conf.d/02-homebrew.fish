# Homebrew: macOS and WSL only. Arch and servers use pacman/apt plus mise instead.
switch $OS_KIND
    case macos
        for b in /opt/homebrew/bin/brew /usr/local/bin/brew
            if test -x $b
                eval ($b shellenv)
                break
            end
        end
    case wsl
        if test -x /home/linuxbrew/.linuxbrew/bin/brew
            eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
        end
end
