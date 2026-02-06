---
description: Fish shell configuration and scripting patterns
autoActivateWhen: user discusses fish shell, fish config, fish functions, fish abbreviations, or files in .config/fish/
---

# Fish Shell Conventions

## File Organization (in SMS repo: fish/.config/fish/)
- `conf.d/` -- Config snippets loaded alphabetically; use numeric prefixes (00-, 20-, 50-) to control order
- `functions/*.fish` -- Autoloaded functions (one function per file, name must match filename)

## Scripting Rules
- Use `set -gx` for global exports, `set -l` for local vars
- Prefer `string` builtins over sed/awk for string manipulation
- Use `fish_add_path` instead of manually editing PATH
- No POSIX-isms: no $(), no &&/||, use `and`/`or`/`; and`

## Testing
- `fish --no-execute <file>` to syntax-check without running
- `fish_indent` to format fish scripts
