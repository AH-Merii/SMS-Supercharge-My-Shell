#!/bin/bash
# Shared notification library — sourced by hook scripts, not executed directly
# shellcheck disable=SC2034

# ---------------------------------------------------------------------------
# load_config — source user config with sane defaults
# ---------------------------------------------------------------------------
load_config() {
    local lib_dir lib_source
    lib_source="${BASH_SOURCE[0]}"
    # Resolve symlinks (GNU Stow creates symlinks from ~/.config/claude/hooks/)
    if command -v readlink &>/dev/null; then
        lib_source="$(readlink -f "$lib_source" 2>/dev/null || echo "$lib_source")"
    fi
    lib_dir="$(cd "$(dirname "$lib_source")" && pwd)"

    if [[ -f "$lib_dir/notify-config.sh" ]]; then
        # shellcheck source=notify-config.sh
        source "$lib_dir/notify-config.sh"
    fi

    # Defaults for anything not set by the config file
    : "${NOTIFY_BELL:=true}"
    : "${NOTIFY_OSC:=true}"
}

# ---------------------------------------------------------------------------
# get_pane_label — human-readable label for the current terminal pane
#   $1 = cwd (fallback)
#   $2 = session_id (fallback)
# ---------------------------------------------------------------------------
get_pane_label() {
    local cwd="${1:-}" session_id="${2:-}"

    # Try tmux first — use $TMUX_PANE to target the correct pane
    # (not the currently focused one, which may be a different session)
    if [[ -n "${TMUX:-}" ]]; then
        local label
        if [[ -n "${TMUX_PANE:-}" ]]; then
            label="$(tmux display-message -t "$TMUX_PANE" -p '#S:#I (#W)' 2>/dev/null)"
        else
            label="$(tmux display-message -p '#S:#I (#W)' 2>/dev/null)"
        fi
        if [[ -n "$label" ]]; then
            printf '%s' "$label"
            return
        fi
    fi

    # Fallback: basename of cwd
    if [[ -n "$cwd" ]]; then
        printf '%s' "$(basename "$cwd")"
        return
    fi

    # Last resort: first 8 chars of session_id
    if [[ -n "$session_id" ]]; then
        printf '%s' "${session_id:0:8}"
        return
    fi

    printf '%s' "claude"
}

# ---------------------------------------------------------------------------
# send_bell — terminal bell (writes to /dev/tty to bypass stdout capture)
# ---------------------------------------------------------------------------
send_bell() {
    printf '\a' > /dev/tty 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# send_osc — OSC 777 desktop notification (with tmux DCS passthrough)
#   $1 = title
#   $2 = body
# ---------------------------------------------------------------------------
send_osc() {
    local title="${1:-}" body="${2:-}"

    # Sanitize: strip semicolons from title/body (OSC 777 uses ; as delimiter)
    title="${title//;/ }"
    body="${body//;/ }"

    # Write to /dev/tty to bypass stdout capture by Claude Code
    if [[ -n "${TMUX:-}" ]]; then
        # tmux DCS passthrough — double ESC, wrap in DCS envelope
        printf '\033Ptmux;\033\033]777;notify;%s;%s\007\033\\' "$title" "$body" > /dev/tty 2>/dev/null || true
    else
        printf '\033]777;notify;%s;%s\007' "$title" "$body" > /dev/tty 2>/dev/null || true
    fi
}

# ---------------------------------------------------------------------------
# notify — orchestrator: dispatches to all enabled channels
#   $1 = title
#   $2 = message
#   $3 = urgency (low/medium/high)
#   $4 = group_id
#   $5 = cwd
#   $6 = session_id
# ---------------------------------------------------------------------------
notify() {
    local title="${1:-Claude Code}" message="${2:-}"
    local urgency="${3:-low}" group_id="${4:-claude}"
    local cwd="${5:-}" session_id="${6:-}"

    load_config

    local pane_label
    pane_label="$(get_pane_label "$cwd" "$session_id")"

    # Enriched title for channels that support longer text
    local rich_title="Claude [$pane_label] — $title"

    # Dispatch to enabled channels
    # Bell is synchronous (needs the TTY, instant)
    if [[ "${NOTIFY_BELL}" == "true" ]]; then
        send_bell
    fi

    if [[ "${NOTIFY_OSC}" == "true" ]]; then
        # OSC title includes pane label for multi-session context
        send_osc "Claude [$pane_label]" "$message" &
    fi

    wait 2>/dev/null
}
