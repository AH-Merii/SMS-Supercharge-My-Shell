# starship, rendered in the background; only the bottom line, status and vi mode, in place.
status is-interactive; or return
type -q starship; or return

starship init fish | source

set -g __prompt_dir (command mktemp -d)
# A blank line until the first render lands, so the input line does not move.
set -g __prompt_top \n
set -g __prompt_right ''

# The fish_prompt event fires for a new prompt and not for a repaint.
function __prompt_mark_stale --on-event fish_prompt
    set -g __prompt_stale 1
end

# Only the render asked for last is shown; an older one landing late is dropped.
function __prompt_landed --on-signal USR1
    set -l top right landed
    begin
        read -z top
        read -z right
        read -z landed
    end <$__prompt_dir/prompt
    test "$landed" = "$__prompt_pid"; or return
    set -g __prompt_top $top
    set -g __prompt_right $right
    commandline -f repaint
end

function __prompt_cleanup --on-event fish_exit
    command rm -rf $__prompt_dir
end

function fish_prompt
    set -l last_pipestatus $pipestatus
    set -l last_status $status
    set -l keymap insert
    switch "$fish_key_bindings"
        case fish_hybrid_key_bindings fish_vi_key_bindings fish_helix_key_bindings
            set keymap $fish_bind_mode
    end
    set -l flags --terminal-width=$COLUMNS --status=$last_status --pipestatus="$last_pipestatus" \
        --keymap=$keymap --cmd-duration=$CMD_DURATION --jobs=(jobs -g | count)

    if set -q __prompt_stale; or test "$__prompt_width" != "$COLUMNS"
        set -e __prompt_stale
        set -g __prompt_width $COLUMNS
        fish --no-config -c '
            set -l shell $argv[1]
            set -l dir $argv[2]
            set -e argv[1..2]
            starship prompt $argv | read -lz top
            starship prompt --right $argv | read -lz right
            printf "%s\0%s\0%s\0" "$top" "$right" $fish_pid >$dir/prompt.new
            and command mv $dir/prompt.new $dir/prompt
            and kill -USR1 $shell
        ' $fish_pid $__prompt_dir $flags 2>/dev/null &
        set -g __prompt_pid $last_pid
        disown
    end

    printf %s $__prompt_top
    starship prompt --profile bottom $flags
end

function fish_right_prompt
    printf %s $__prompt_right
end
