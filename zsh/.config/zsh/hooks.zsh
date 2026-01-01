# hooks.zsh - Plugin hooks that must be defined before antidote load

# zsh-vi-mode configuration (must be set before plugin loads)
function zvm_config() {
  # Enable system clipboard integration (auto-detects pbcopy/pbpaste on macOS)
  ZVM_SYSTEM_CLIPBOARD_ENABLED=true
}

# zsh-vi-mode keybindings (runs after plugin loads)
function zvm_after_init() {
  # Override p/P to always use system clipboard
  zvm_bindkey vicmd 'p' zvm_paste_clipboard_after
  zvm_bindkey vicmd 'P' zvm_paste_clipboard_before
}
