#!/usr/bin/env bash

sesh_fzf_picker() {
  local session
  session="$(
    sesh list --icons | fzf-tmux -p 80%,70% \
      --no-sort --ansi \
      --border-label " sesh " \
      --prompt "⚡  " \
      --header " ^a  All  ^t  Tmux  ^g 󰣖 Configs  ^x 󰫫 Zoxide  ^f  Dirs  ^d 󱓈 Kill Session" \
      --bind "tab:down,btab:up" \
      --bind "ctrl-a:change-prompt(  )+reload(sesh list --icons)" \
      --bind "ctrl-t:change-prompt(  )+reload(sesh list -t --icons)" \
      --bind "ctrl-g:change-prompt(󰣖  )+reload(sesh list -c --icons)" \
      --bind "ctrl-x:change-prompt(󰫫  )+reload(sesh list -z --icons)" \
      --bind "ctrl-f:change-prompt(  )+reload(fd --color=always -H -d 2 -t d -E .Trash . ~)" \
      --bind "ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡ )+reload(sesh list --icons)" \
      --preview-window "right:55%" \
      --preview "sesh preview {}"
  )" || return 0 # fzf cancelled (Esc / ^C)
  [[ -n "$session" ]] || return 0 # nothing chosen; don't run `sesh connect ""`
  sesh connect "$session"
}

setup_sesh_bindings() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"

  if ! command -v sesh >/dev/null; then
    tmux display-message "sesh not found; skipping sesh bindings."
    exit 0
  fi

  tmux bind-key -N "last-session (via sesh)" b run-shell "sesh last"

  if command -v fzf-tmux >/dev/null && command -v fd >/dev/null; then
    tmux bind-key -N "Run sesh fzf-tmux" C-k run-shell "$config_dir/tmux/scripts/configure-sesh-tmux-bindings.sh picker"
  else
    tmux display-message "sesh installed but fzf-tmux or fd not found; skipping sesh picker binding."
  fi
}

# When called with "picker", run the picker directly.
if [[ "${1:-}" == "picker" ]]; then
  sesh_fzf_picker
else
  setup_sesh_bindings
fi
