# mise: runtimes and CLI tools (see ~/.config/mise/config.toml).
# Interactive shells get full activation; everything else (scripts, compositor spawns,
# editors started from a launcher) gets the shims so the same tools resolve.
if type -q mise
    if status is-interactive
        mise activate fish | source
    else
        # -g: global, not universal, so the shims stay out of interactive shells
        fish_add_path -g --prepend $XDG_DATA_HOME/mise/shims
    end
end
