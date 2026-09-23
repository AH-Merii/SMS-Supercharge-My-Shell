#!/usr/bin/env bash
set -euo pipefail

# Unbind everything in every table on THIS server
while read -r tbl; do
  tmux unbind -a -T "$tbl"
done < <(tmux list-keys | awk '/bind-key[ ]+-T/ {print $3}' | sort -u)

# Starts a temporary blank server and dumps its defaults and kills it afterwards
default_bindings="$(tmux -L def -f /dev/null start-server \; list-keys \; kill-server)"

# Feeds the default keybindings back into tmux as a source-file
echo "${default_bindings}" | tmux source-file -

