# Claude Code memories

Claude Code keeps per-project memories in `$CLAUDE_CONFIG_DIR/projects/<slug>/memory/`,
where `<slug>` is the checkout's absolute path with every `/` turned into `-`. That slug
differs per machine and per user, so the directory cannot be a stow package: the target
path is only known at run time.

`mise run memory` computes the slug for the current checkout and symlinks every file here
into it. Run it on a new machine, or after moving the checkout.

## What lives here

The memories that hold on any machine: how to write PR descriptions, review comments and
issues, how this repo is laid out, and a few standing preferences. `index.md` holds their
one-line entries for `MEMORY.md`, which Claude loads at session start.

## What deliberately does not

Anything true of one machine only stays unversioned in the live directory: the GPU
topology, the monitor's USB-C quirks, the Noctalia notes, the sudo policy. They would be
wrong on a different box, and a wrong memory is worse than a missing one.

`MEMORY.md` itself is not versioned either, since it indexes both kinds. The task appends
any missing line from `index.md` and leaves local entries alone.
