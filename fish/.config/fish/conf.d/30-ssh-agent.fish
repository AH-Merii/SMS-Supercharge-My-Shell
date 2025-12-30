# SSH agent initialization (cross-platform)
# macOS: Uses Keychain integration if available
# Linux: Falls back to ssh-agent management

# Skip if this is an SSH session with forwarded agent
if test -n "$SSH_CONNECTION"
    ssh-add -l >/dev/null 2>&1
    if test $status -eq 0 -o $status -eq 1
        return 0
    end
end

# macOS with Keychain - just ensure key is added
if test (uname) = Darwin
    # macOS ssh-agent runs via launchd, just add key if needed
    ssh-add -l >/dev/null 2>&1
    if test $status -eq 1
        # Agent running but no keys - add default key using Keychain
        ssh-add --apple-use-keychain 2>/dev/null
    end
    return 0
end

# Linux: manual ssh-agent management
set -g SSH_ENV "$HOME/.ssh/agent-fish.env"

function __ssh_agent_is_started
    if test -f "$SSH_ENV" -a -z "$SSH_AGENT_PID"
        source "$SSH_ENV" >/dev/null
    end
    if test -z "$SSH_AGENT_PID"
        return 1
    end
    ssh-add -l >/dev/null 2>&1
    test $status -ne 2
end

function __ssh_agent_start
    ssh-agent -c | sed 's/^echo/#echo/' > "$SSH_ENV"
    chmod 600 "$SSH_ENV"
    source "$SSH_ENV" >/dev/null
end

if not __ssh_agent_is_started
    __ssh_agent_start
    ssh-add
end
