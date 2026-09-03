# mise: runtimes and CLI tools (see ~/.config/mise/config.toml).
# Interactive shells get full activation; everything else (scripts, compositor spawns,
# editors started from a launcher) gets the shims so the same tools resolve.
if type -q mise
    if status is-interactive
        mise activate fish | source
    else
        fish_add_path --prepend $XDG_DATA_HOME/mise/shims
    end
end
