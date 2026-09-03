# Karabiner PC-Style Keybindings

macOS key remappings for Windows/Linux muscle memory.

## What it does

| PC Shortcut    | Mac Equivalent   | Action               |
| -------------- | ---------------- | -------------------- |
| Ctrl+C/V/X     | Cmd+C/V/X        | Copy/Paste/Cut       |
| Ctrl+Z         | Cmd+Z            | Undo                 |
| Ctrl+Y         | Cmd+Shift+Z      | Redo                 |
| Ctrl+A         | Cmd+A            | Select all           |
| Ctrl+S         | Cmd+S            | Save                 |
| Ctrl+N         | Cmd+N            | New                  |
| Ctrl+O         | Cmd+O            | Open                 |
| Ctrl+W         | Cmd+W            | Close                |
| Ctrl+T         | Cmd+T            | New tab              |
| Ctrl+F         | Cmd+F            | Find                 |
| Ctrl+G         | Cmd+G            | Find next            |
| Ctrl+R / F5    | Cmd+R            | Reload               |
| Ctrl+K         | Cmd+K            | Insert link (etc.)   |
| Ctrl+Arrow     | Option+Arrow     | Word navigation      |
| Ctrl+Backspace | Option+Backspace | Delete word backward |
| Ctrl+Delete    | Option+Delete    | Delete word forward  |
| Home/End       | Cmd+Left/Right   | Line start/end       |
| Ctrl+Home/End  | Cmd+Up/Down      | Document start/end   |

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

## Excluded apps

These apps keep their native behavior:

- **VMs**: VMware Fusion, VMware Horizon, Parallels, VirtualBox
- **Terminals**: Ghostty, Apple Terminal
- **Editors**: VSCode

## Tab switcher handling

Ctrl+Arrow and Alt+Arrow remappings are disabled while tab switching (Ctrl+Tab or Alt+Tab) so you can navigate the switcher with arrow keys.

## Installation

```bash
cp karabiner.json ~/.config/karabiner/karabiner.json
```

Or symlink for dotfiles management:

```bash
ln -sf ~/dotfiles/karabiner/karabiner.json ~/.config/karabiner/karabiner.json
```
