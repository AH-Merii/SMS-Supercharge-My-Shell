---
name: when-a-pull-conflicts
description: "When pulling from remote conflicts with local commits, rebase and replay rather than merging; resolve directly when clear, delegate a quick check when not, ask when still unsure"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 729541b5-93a7-433a-8023-12f62068b0c2
  modified: 2026-09-10
---

When a pull conflicts with local commits, rebase and replay the local work on top of the
remote. Do not resolve it with a merge commit.

Most hunks are clear — resolve them and move on. Only when one genuinely is not:

- Delegate the look to a subagent and keep it **quick**: when was each side written, and
  which PR did it arrive through. A merged PR carries a body and review comments saying
  why; a local WIP commit usually does not. Two minutes, not an audit.
- If that does not settle it, ask, showing both sides and what the check found.

**Why:** replaying keeps the local commits as commits the user signed, on their own SHAs.
A wrongly resolved hunk is nearly invisible afterwards — an ordinary line in a merged
file, not something flagged as deleted — so the cost of guessing lands long after the
guess.

**How to apply:** rebase, resolve what is clear, stop at the first hunk that is not.
Never `--skip`, or blanket `--ours`/`--theirs`, to get the rebase moving. `rerere` is
enabled with `autoupdate`, so a resolution recorded once is replayed silently later; if a
conflict resolves itself in a way that looks unfamiliar, that is why. Related:
[[landing-a-pr]], [[change-only-what-was-asked]].
