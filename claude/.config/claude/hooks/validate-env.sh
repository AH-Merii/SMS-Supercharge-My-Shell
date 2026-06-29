#!/bin/bash
# Setup hook: validate development environment

missing=()
optional_missing=()

# Required tools (exit 2 if missing)
for tool in bun uv git gh stow fd rg jq; do
  if ! command -v "$tool" &>/dev/null; then
    missing+=("$tool")
  fi
done

# Optional tools (warning only)
for tool in fish btca op; do
  if ! command -v "$tool" &>/dev/null; then
    optional_missing+=("$tool")
  fi
done

# Check stow symlinks are intact
if [ -L ~/.config/claude/settings.json ] && [ ! -e ~/.config/claude/settings.json ]; then
  echo "WARNING: Broken symlink: ~/.config/claude/settings.json"
  echo "Run: cd ~/SMS-Supercharge-My-Shell && stow claude"
fi

# Report optional missing tools
for tool in "${optional_missing[@]}"; do
  case "$tool" in
    btca)
      echo "OPTIONAL: btca not installed. Run: bun install -g btca" ;;
    *)
      echo "OPTIONAL: $tool not installed" ;;
  esac
done

# Block on required tools
if [ ${#missing[@]} -gt 0 ]; then
  echo "MISSING TOOLS: ${missing[*]}"
  echo "Install with: brew install ${missing[*]}"
  exit 2
fi

exit 0
