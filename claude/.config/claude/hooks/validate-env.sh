#!/bin/bash
# Setup hook: validate development environment
# Runs on: claude --init, claude --init-only, claude --maintenance

missing=()

# Check required tools
for tool in bun uv fish git gh stow fd rg jq btca op; do
  if ! command -v "$tool" &>/dev/null; then
    missing+=("$tool")
  fi
done

# Check stow symlinks are intact
if [ -L ~/.config/claude/settings.json ]; then
  target=$(readlink ~/.config/claude/settings.json)
  if [ ! -f "$target" ]; then
    echo "WARNING: Broken symlink: ~/.config/claude/settings.json -> $target"
    echo "Run: cd ~/SMS-Supercharge-My-Shell && stow -vt ~ claude"
  fi
fi

# Check terminal-notifier for notifications
if ! command -v terminal-notifier &>/dev/null; then
  echo "OPTIONAL: terminal-notifier not installed. Run: brew install terminal-notifier"
fi

if [ ${#missing[@]} -gt 0 ]; then
  echo "MISSING TOOLS: ${missing[*]}"
  echo "Install with: brew install ${missing[*]}"
  exit 2  # Exit code 2 = blocking error
fi

echo "Environment OK: all required tools installed"
exit 0
