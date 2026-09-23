# OS detection, done once per shell. Later conf.d files branch on $OS_KIND:
#   macos  linux  wsl
switch (uname -s)
    case Darwin
        set -gx OS_KIND macos
    case Linux
        if set -q WSL_DISTRO_NAME; or string match -qi '*microsoft*' (cat /proc/version 2>/dev/null)
            set -gx OS_KIND wsl
        else
            set -gx OS_KIND linux
        end
    case '*'
        set -gx OS_KIND linux
end
