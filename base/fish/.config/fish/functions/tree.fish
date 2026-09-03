function tree --description "eza-powered tree view with icons"
    # Handle help flag
    if contains -- -h $argv; or contains -- --help $argv
        echo '#  tree - eza wrapper

> **Note:** This is not the traditional `tree` command.
> This is a wrapper around `eza --tree` with sensible defaults.

## Usage

    tree [DEPTH] [OPTIONS] [PATH...]

## Quick Depth Shortcut

Pass a number as the first argument to set depth:

    tree 2          # Show 2 levels deep
    tree 3 src/     # Show 3 levels in src/

## Useful eza Flags

| Flag | Description |
|------|-------------|
| `-L, --level=DEPTH` | Limit recursion depth |
| `-a, --all` | Show hidden files |
| `-D, --only-dirs` | Only show directories |
| `-I, --ignore-glob=GLOB` | Ignore files matching glob pattern |
| `--git-ignore` | Ignore files listed in `.gitignore` |
| `-s, --sort=FIELD` | Sort by: name, size, date, modified, extension |
| `--no-icons` | Disable icons |
| `--color=WHEN` | When to use colors: always, auto, never |
| `-r, --reverse` | Reverse sort order |

## Examples

    tree                        # Current dir, default depth
    tree 2                      # 2 levels deep
    tree -a                     # Include hidden files
    tree -D                     # Directories only
    tree --git-ignore           # Respect .gitignore
    tree -I "node_modules"      # Ignore node_modules
    tree -I "*.log" -I "*.tmp"  # Ignore multiple patterns
    tree -s size                # Sort by size
    tree 3 -D src/              # 3 levels, dirs only, in src/

## Defaults Applied

- `--icons=always` - File type icons enabled
- `--tree` - Tree view mode
' | glow -
        return 0
    end

    # If first argument is a number, use it as depth
    if test (count $argv) -gt 0; and string match -qr '^\d+$' -- $argv[1]
        eza --icons=always --tree --level=$argv[1] $argv[2..-1]
    else
        eza --icons=always --tree $argv
    end
end
