# Keep Fisher + plugins in XDG data dir

set -gx fisher_path $XDG_DATA_HOME/fisher

# Make Fish see plugin functions & completions (must happen unconditionally
# so fisher install can find newly-installed functions when sourcing conf.d).
# Fisher's documented ordering: plugin dirs go right after the user's own
# ~/.config/fish/functions, so a same-named user file wins over a plugin's.
contains -- $fisher_path/functions $fish_function_path
or set -g fish_function_path $fish_function_path[1] $fisher_path/functions $fish_function_path[2..]
contains -- $fisher_path/completions $fish_complete_path
or set -g fish_complete_path $fish_complete_path[1] $fisher_path/completions $fish_complete_path[2..]

if not status is-interactive
    return
end

# Source plugin conf.d explicitly (Fish only auto-sources ~/.config/fish/conf.d),
# skipping any whose name is also a user conf.d file, so the user's copy wins.
for f in $fisher_path/conf.d/*.fish
    test -r $f; or continue
    test -f $__fish_config_dir/conf.d/(path basename $f); and continue
    source $f
end
