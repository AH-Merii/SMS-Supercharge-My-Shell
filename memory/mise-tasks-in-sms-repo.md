---
name: mise-tasks-in-sms-repo
description: When to reach for mise in this repo and which task does what, the plan-then-confirm convention every task follows, the env knobs for dry runs, and the rule that this memory is updated in the same change that adds or renames a task
metadata:
  node_type: memory
  type: project
  originSessionId: 729541b5-93a7-433a-8023-12f62068b0c2
  modified: 2026-09-10
---

mise is the only entry point for anything that installs, links or writes outside the
repo. Never run `stow`, `pacman`, `fisher` or a package manager directly here: the tasks
handle conflicts, profiles and previews, and doing it by hand skips all three. `mise
tasks` lists them; file tasks live in `mise-tasks/`, and `mise.toml` deliberately has no
`[tools]` block, because it would shadow the global config whenever the cwd is inside the
repo.

| Task | What it does |
|---|---|
| `setup` | Fresh machine: deps, link, tools, plugins, greeter, winterm, memory, in that order |
| `deps` | OS packages: pacman/paru on Arch, apt on Debian, `brew bundle` on macOS and WSL |
| `link` | Stow the layers for this profile; conflicts move to `.bak` first |
| `unlink` | Remove those symlinks |
| `check` | Dry-run `link` (the only inline task; it is `STOW_FLAGS=-n mise run link`) |
| `tools` | `mise install` everything in the global mise config |
| `plugins` | fisher plus fish plugins, TPM plus tmux plugins |
| `greeter` | Arch desktop: greetd and noctalia-greeter as the login screen; a no-op elsewhere |
| `winterm` | WSL: the ghostty theme into Windows Terminal's settings.json; a no-op elsewhere |
| `memory` | Link `memory/*.md` into this checkout's Claude project directory |
| `profile` | Print the detected profile |

Every task prints a plan and asks before writing. The preview lives in `lib/plan.sh` as
`plan_<task>`, and the task calls it through `sms_preview`, so a task and its own preview
cannot drift. `setup` prints every plan up front, then sets `SMS_PLAN_CONFIRMED=1` so the
tasks it chains do not each ask again. Tasks are run sequentially inside `setup`, never as
`mise run deps link ...`, which would run them in parallel.

Knobs, all read by the tasks: `DOTFILES_PROFILE` overrides detection,
`STOW_FLAGS=-n` dry-runs `link`, `SMS_YES` skips prompts in `bootstrap.sh`,
`SMS_WINTERM_SETTINGS` points `winterm` at a settings.json it cannot find,
`SMS_BACKUP_MAX` caps how many backup lines print before collapsing to a count.

**Why:** the tasks encode the conflict handling, profile detection and preview that make
this repo safe to re-run on a machine that is already set up. Bypassing them is how a
config gets clobbered instead of backed up. The plan-then-confirm shape is the repo's
main convention, so a new task that skips it is wrong even when it works.

**How to apply:** adding a task means a script in `mise-tasks/` with `#MISE description=`
and `#MISE raw=true`, sourcing `mise-tasks/profile` and `lib/plan.sh`, a matching
`plan_<task>` in `lib/plan.sh`, a line in the README task table, and a line in the setup
chain if it belongs there. Lint with `shellcheck -x` and `shfmt -i 2 -ci`.

**Keep this memory current.** It is a table of a moving target. Whenever a task is added,
renamed, removed, or changes what it writes, update this file in the same change, not
later. The same goes for the knobs and the ordering inside `setup`. A stale table here is
worse than none, because it will be trusted. See [[dotfiles-layers-and-mise]] for the
layout the tasks operate on.
