# Homebrew initialization (macOS + Linux)
switch (uname)
    case Darwin
        for b in /opt/homebrew/bin/brew /usr/local/bin/brew
            if test -x $b
                eval ($b shellenv)
                break
            end
        end
    case '*'
        if test -x /home/linuxbrew/.linuxbrew/bin/brew
            eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
        end
end

