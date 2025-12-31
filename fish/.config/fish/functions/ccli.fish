function ccli --description "Claude Code CLI - get commands and tldr-style references"
    argparse -x 't,c,x,a' t/tldr c/cmd x/exec a/ask h/help -- $argv
    or return

    if set -q _flag_help
        echo '# ccli - Claude Code CLI

## Usage
    ccli [OPTIONS] <query>

## Options
| Flag | Description |
|------|-------------|
| `-c, --cmd` | Output raw command only *(default)* |
| `-t, --tldr` | Output tldr-style reference |
| `-x, --exec` | Show command and execute with confirmation |
| `-a, --ask` | Ask a question and get a response |
| `-h, --help` | Show this help |

## Examples
```bash
# Get a command
ccli "list current tmux session"

# Get tldr-style reference
ccli -t "git stash"

# Pipe command to clipboard
ccli "find large files" | pbcopy

# Execute with confirmation
ccli -x "kill process on port 3000"

# Ask a question
ccli -a "what is the difference between curl and wget"
```' | glow
        return 0
    end

    if test (count $argv) -eq 0
        echo "Error: Query required. Use 'ccli -h' for help."
        return 1
    end

    set -l query $argv

    if set -q _flag_tldr
        claude -p --append-system-prompt "Output a tldr-style reference. Format:
# command-name
> Short description

- Example use case:
\`command --flag argument\`

Keep it concise like the tldr tool." $query | glow

    else if set -q _flag_ask
        claude -p --append-system-prompt "Answer the question concisely and helpfully. Use markdown formatting for readability." $query | glow

    else if set -q _flag_exec
        set -l result (claude -p --append-system-prompt "Output ONLY the raw command. No explanation, no markdown, no code blocks, no backticks." $query)
        echo "→ $result"
        read -P "Run? [y/N] " confirm
        test "$confirm" = y && eval $result

    else
        claude -p --append-system-prompt "Output ONLY the raw command. No explanation, no markdown, no code blocks, no backticks. Just the exact command to copy/run." $query
    end
end
