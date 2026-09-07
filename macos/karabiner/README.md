# Karabiner PC-Style Keybindings

macOS key remappings for Windows/Linux muscle memory.

## What it does

| PC Shortcut       | Mac Equivalent    | Action               |
| ----------------- | ----------------- | -------------------- |
| Ctrl+C/V/X        | Cmd+C/V/X         | Copy/Paste/Cut       |
| Ctrl+Z            | Cmd+Z             | Undo                 |
| Ctrl+Y            | Cmd+Shift+Z       | Redo                 |
| Ctrl+A            | Cmd+A             | Select all           |
| Ctrl+S            | Cmd+S             | Save                 |
| Ctrl+N            | Cmd+N             | New                  |
| Ctrl+O            | Cmd+O             | Open                 |
| Ctrl+W            | Cmd+W             | Close                |
| Ctrl+T            | Cmd+T             | New tab              |
| Ctrl+F            | Cmd+F             | Find                 |
| Ctrl+G            | Cmd+G             | Find next            |
| Ctrl+R / F5       | Cmd+R             | Reload               |
| Ctrl+K            | Cmd+K             | Insert link (etc.)   |
| Ctrl+Left/Right   | Option+Left/Right | Word navigation      |
| Ctrl+Up/Down      | Cmd+Up/Down       | Document start/end   |
| Ctrl+Backspace    | Option+Backspace  | Delete word backward |
| Ctrl+Delete       | Option+Delete     | Delete word forward  |
| Home/End          | Cmd+Left/Right    | Line start/end       |
| Ctrl+Home/End     | Cmd+Up/Down       | Document start/end   |
| Cmd+.             | Ctrl+Cmd+Space    | Emoji picker         |

### Browser-specific (Firefox, Chrome, Edge, Brave, Safari, Zen)

| PC Shortcut       | Mac Equivalent   | Action       |
| ----------------- | ---------------- | ------------ |
| Alt+Left/Right    | Cmd+[/]          | Back/Forward |
| Ctrl+Plus/Minus/0 | Cmd+Plus/Minus/0 | Zoom         |

### Terminal-specific (Ghostty, Apple Terminal)

| PC Shortcut | Action            |
| ----------- | ----------------- |
| Home        | Ctrl+A (readline) |
| End         | Ctrl+E (readline) |

### Ghostty-only: Hyper shortcuts

Hyper is Cmd+Ctrl+Option+Shift. These fire only while Ghostty is frontmost, so the
combinations do not collide with fzf's bindings inside the shell.

| Shortcut | Action                                                          |
| -------- | --------------------------------------------------------------- |
| Hyper+S  | `open -a Slack`                                                 |
| Hyper+F  | Raycast window management: toggle fullscreen (`raycast://` URL) |

## Excluded apps

These apps keep their native behavior:

- **VMs**: VMware Fusion, VMware Horizon, Parallels, VirtualBox
- **Terminals**: Ghostty, Apple Terminal
- **Editors**: VSCode

The emoji picker rule is excluded only in VMs.

## Tab switcher handling

Ctrl+Arrow and Alt+Arrow remappings are disabled while tab switching (Ctrl+Tab or Alt+Tab)
so you can navigate the switcher with arrow keys. A variable is set when Ctrl+Tab or Alt+Tab
is pressed and cleared when the Ctrl or Option key is released. The reset manipulators accept
any held modifier (`"optional": ["any"]`) so that Ctrl+Shift+Tab, where Shift is already down
when Ctrl goes down, still clears the state on release.

## Per-keyboard settings

`devices` marks one keyboard (`vendor_id` 7504, `product_id` 24926, a ZMK board) with
`treat_as_built_in_keyboard` so macOS applies built-in-keyboard behaviour to it. Karabiner
matches this block by device ID; on any other keyboard it is a silent no-op. Change or add an
entry under `devices` for your own board (Karabiner-Elements Settings > Devices shows the IDs).

## Installation

This package is part of the `macos` layer, which the `macos` profile links automatically:

```bash
mise run link                  # link every layer for this machine's profile
stow -d macos karabiner        # or link just this package by hand
```

Both create `~/.config/karabiner/karabiner.json` as a symlink into
`macos/karabiner/.config/karabiner/`. Karabiner-Elements reloads the file on change.
