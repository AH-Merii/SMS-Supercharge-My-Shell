---
name: pr-closes-its-issue
description: "When opening a pull request that implements an issue, name the issue in the body with a closing keyword: Closes #N, so the issue closes itself on merge"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 8893c438-4eff-4c01-a944-c3a7e243be03
  modified: 2026-09-23
---

A pull request that implements an issue names it in the body with a closing keyword —
`Closes #126` — not a bare `#126` and not "for #126". One line, in the PR description
rather than only in the commit message.

**Why:** a bare reference only cross-links; it leaves the issue open after the merge. #125
and #126 both sat open on the tracker with their PRs already merged, so the board no longer
said what was done. GitHub closes the issue itself when the keyword is there, and an epic
stays readable without anyone tidying up behind it.

**How to apply:** put `Closes #<n>` in the body when opening the PR with `gh pr create`. If
one PR finishes several issues, repeat the keyword per issue — `Closes #1, Closes #2` —
since `Closes #1 and #2` closes only the first. Keep a bare `#<n>` for an issue the PR
genuinely does not finish. After a merge, check the tracker and close by hand anything the
keyword missed.
