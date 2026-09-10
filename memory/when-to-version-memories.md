---
name: when-to-version-memories
description: "When saving a memory in this repo, decide whether it goes in the versioned memory/ directory or stays local: portable facts are versioned, anything true of one machine only is not"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 729541b5-93a7-433a-8023-12f62068b0c2
  modified: 2026-09-10
---

Every memory saved while working in this repo gets classified once, at the moment it is
written. One test: would this still be true on a machine that is not this one?

- **Yes** — write the file into `memory/` in the repo, add its one-line entry to
  `memory/index.md`, and run `mise run memory` to link it into the live project
  directory. Guidelines, repo layout, standing preferences.
- **No** — write it straight into the live project directory and leave it unversioned.
  Hardware topology, this monitor's quirks, the sudo policy, anything naming a device or
  a path outside the checkout.

`MEMORY.md` is never versioned: it indexes both kinds, and the task appends only the
lines missing from `index.md`.

**Why:** the versioned half propagates to every machine that runs `mise run memory`. A
machine-specific fact that escapes into it arrives on the next box as a confident
statement that is wrong there, and a wrong memory is worse than a missing one. The
opposite mistake is cheap by comparison: a portable memory left local is merely absent
elsewhere.

**How to apply:** classify before writing, not after. When it is genuinely ambiguous,
keep it local and say so, rather than versioning on a guess. The repo-side rationale
lives in `memory/README.md`. Related: [[mise-tasks-in-sms-repo]],
[[dotfiles-layers-and-mise]].
