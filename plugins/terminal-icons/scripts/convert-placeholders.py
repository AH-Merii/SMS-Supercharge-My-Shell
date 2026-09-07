#!/usr/bin/env python3
"""Convert icon placeholders to actual Unicode characters.

Supports two placeholder formats (case-insensitive):
  {{ U+XXXX }}     - by codepoint (spaces prevent self-conversion)
  {{ nf-name }}    - by icon name

Only codepoints inside a Private Use Area are converted; anything else
(control characters, ASCII, bidi overrides, ...) is left untouched so a file
that merely contains the syntax cannot be mutated into arbitrary characters.

Usage: convert-placeholders.py <file>
"""

import json
import os
import re
import sys
import tempfile


def is_pua(codepoint):
    """Check if codepoint is in any Private Use Area range.

    Mirrors is_pua() in identify-icons.py.
    """
    # BMP PUA: U+E000-U+F8FF
    # Supplementary PUA-A: U+F0000-U+FFFFF
    # Supplementary PUA-B: U+100000-U+10FFFF
    return (0xE000 <= codepoint <= 0xF8FF or
            0xF0000 <= codepoint <= 0xFFFFF or
            0x100000 <= codepoint <= 0x10FFFF)


def atomic_write(file_path, content):
    """Write content to file_path via a temp file in the same directory."""
    directory = os.path.dirname(os.path.abspath(file_path))
    fd, tmp_path = tempfile.mkstemp(prefix=".convert-", dir=directory)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as f:
            f.write(content)
        try:
            os.chmod(tmp_path, os.stat(file_path).st_mode)
        except OSError:
            pass
        os.replace(tmp_path, file_path)
    except BaseException:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise


def main():
    if len(sys.argv) < 2:
        print("Usage: convert-placeholders.py <file>", file=sys.stderr)
        sys.exit(1)

    file_path = sys.argv[1]

    if not os.path.isfile(file_path):
        print(f"File not found: {file_path}", file=sys.stderr)
        sys.exit(1)

    # Read file content (newline="" preserves the file's line endings)
    with open(file_path, "r", encoding="utf-8", newline="") as f:
        content = f.read()

    # Quick check for placeholders (case-insensitive)
    placeholder_pattern = re.compile(
        r'\{\{(u\+[0-9a-f]+|nf-[a-z0-9_-]+)\}\}', re.IGNORECASE
    )
    if not placeholder_pattern.search(content):
        sys.exit(0)

    # Load icon database
    script_dir = os.path.dirname(os.path.abspath(__file__))
    data_path = os.path.join(script_dir, "..", "data", "nerdfont-icons.json")
    with open(data_path, "r", encoding="utf-8") as f:
        icons = json.load(f)

    # Build reverse lookup: name -> codepoint (lowercase keys for case-insensitive lookup)
    name_to_codepoint = {name.lower(): data["codepoint"] for name, data in icons.items()}

    def replace_placeholder(match):
        placeholder = match.group(1)

        if placeholder.upper().startswith("U+"):
            # Codepoint format
            try:
                codepoint = int(placeholder[2:], 16)
            except ValueError:
                return match.group(0)
        else:
            # Named format (nf-*)
            lookup_key = placeholder.lower()
            if lookup_key not in name_to_codepoint:
                return match.group(0)
            codepoint = int(name_to_codepoint[lookup_key], 16)

        # Only ever emit Private Use Area characters
        if not is_pua(codepoint):
            return match.group(0)
        return chr(codepoint)

    # Replace all placeholders (case-insensitive)
    new_content = placeholder_pattern.sub(replace_placeholder, content)

    # Write back only if changed
    if new_content != content:
        atomic_write(file_path, new_content)
        print(f"Converted placeholders in {file_path}")


if __name__ == "__main__":
    main()
