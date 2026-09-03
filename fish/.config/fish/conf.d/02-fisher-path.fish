# Keep Fisher + plugins in XDG data dir

set -gx fisher_path $XDG_DATA_HOME/fisher

# Make Fish see plugin functions & completions (must happen unconditionally
# so fisher install can find newly-installed functions when sourcing conf.d)
set -g fish_function_path $fisher_path/functions $fish_function_path
set -g fish_complete_path $fisher_path/completions $fish_complete_path

if not status is-interactive
    return
end

# Source plugin conf.d explicitly (Fish only auto-sources ~/.config/fish/conf.d)
set -l confs $fisher_path/conf.d/*.fish
for f in $confs
    test -r $f; and source $f
end
