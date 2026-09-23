#!/bin/bash
# ccstatusline custom-command widget: context window usage as a threshold-coloured bar.
#
# ccstatusline pipes Claude Code's statusline JSON payload to stdin and keeps our
# ANSI codes because the widget sets preserveColors. Output is a single line:
#   ▓▓▓▓░░░░░░ 42%
# green <70%, yellow 70-89%, red >=90%.
#
# Prints nothing (exit 0) when usage is unknown — before the first API call and
# after /compact, context_window fields are null or absent.

INPUT=$(cat)

# used_percentage is pre-computed by Claude Code, but is null early in a session.
PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // empty')

if [ -z "$PCT" ]; then
  # Fall back to the per-component breakdown: input + cache writes + cache reads.
  PCT=$(echo "$INPUT" | jq -r '
    .context_window as $c
    | ($c.context_window_size // 0) as $size
    | ($c.current_usage // {}) as $u
    | (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) as $used
    | if $size > 0 and $used > 0 then ($used * 100 / $size) else empty end
  ')
fi

[ -z "$PCT" ] && exit 0

# Integer percent, clamped to 0-100 so a bar is never over- or under-filled.
PCT=${PCT%%.*}
[ -z "$PCT" ] && exit 0
[ "$PCT" -lt 0 ] && PCT=0
[ "$PCT" -gt 100 ] && PCT=100

WIDTH=10
FILLED=$((PCT * WIDTH / 100))
EMPTY=$((WIDTH - FILLED))

printf -v FILL "%${FILLED}s"
printf -v PAD "%${EMPTY}s"
BAR="${FILL// /▓}${PAD// /░}"

if [ "$PCT" -ge 90 ]; then
  COLOR='\033[31m' # red
elif [ "$PCT" -ge 70 ]; then
  COLOR='\033[33m' # yellow
else
  COLOR='\033[32m' # green
fi

printf '%b%s %d%%%b\n' "$COLOR" "$BAR" "$PCT" '\033[0m'
