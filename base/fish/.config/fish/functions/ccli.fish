function ccli --description "Claude Code CLI - get commands and tldr-style references"
    argparse -x 't,c,x,a' t/tldr c/cmd x/exec a/ask h/help -- $argv
    or return

    # Render markdown with glow when it is installed, plain cat otherwise.
    set -l render cat
    command -q glow; and set render glow

    if set -q _flag_help
        set -l clip wl-copy
        test (uname) = Darwin; and set clip pbcopy
        echo "# ccli - Claude Code CLI

## Usage
    ccli [OPTIONS] <query>

## Options
| Flag | Description |
|------|-------------|
| \`-c, --cmd\` | Output raw command only *(default)* |
| \`-t, --tldr\` | Output tldr-style reference |
| \`-x, --exec\` | Show command and execute with confirmation |
| \`-a, --ask\` | Ask a question and get a response |
| \`-h, --help\` | Show this help |

## Examples

    # Get a command
    ccli \"list current tmux session\"

    # Get tldr-style reference
    ccli -t \"git stash\"

    # Pipe command to clipboard
    ccli \"find large files\" | $clip

    # Execute with confirmation
    ccli -x \"kill process on port 3000\"

    # Ask a question
    ccli -a \"what is the difference between curl and wget\"
" | $render
        return 0
    end

    if test (count $argv) -eq 0
        echo "Error: Query required. Use 'ccli -h' for help."
        return 1
    end

    set -l query $argv

    # Answer-only mode: no built-in or MCP tools, no MCP servers, no
    # project/local settings (so an untrusted cwd cannot inject hooks or
    # permission rules), and no transcript written to disk. Without this,
    # `claude -p` inherits the interactive config and may run commands while
    # composing its answer, before -x ever asks for confirmation.
    set -l opts --tools "" --disallowedTools "*" --strict-mcp-config --setting-sources user --no-session-persistence
    # --bare also skips hooks, plugins, auto-memory and CLAUDE.md discovery,
    # but it never reads the claude.ai OAuth login; only use it with an API key.
    set -q ANTHROPIC_API_KEY; and set -a opts --bare

    if set -q _flag_tldr
        claude -p $opts --append-system-prompt "Output a tldr-style reference. Format:
# command-name
> Short description

- Example use case:
\`command --flag argument\`

Keep it concise like the tldr tool." $query | $render

    else if set -q _flag_ask
        claude -p $opts --append-system-prompt "Answer the question concisely and helpfully. Use markdown formatting for readability." $query | $render

    else if set -q _flag_exec
        set -l result (claude -p $opts --append-system-prompt "Output ONLY the raw command. No explanation, no markdown, no code blocks, no backticks." $query)
        or return
        printf '%s\n' $result
        if test (count $result) -ne 1
            echo "ccli: expected exactly one line of output, got "(count $result)"; not running it." >&2
            return 1
        end
        read -P "Run? [y/N] " confirm
        or return
        test "$confirm" = y; and eval $result

    else
        claude -p $opts --append-system-prompt "Output ONLY the raw command. No explanation, no markdown, no code blocks, no backticks. Just the exact command to copy/run." $query
    end
end
