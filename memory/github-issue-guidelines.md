---
name: github-issue-guidelines
description: "An issue is one problem a stranger could pick up: what happens, what should happen, how to see it, on which commit and version, and which issues it relates to"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 729541b5-93a7-433a-8023-12f62068b0c2
  modified: 2026-09-10T09:45:40.142Z
---

An issue is a note to whoever fixes it, which may be you in six months with no memory of
today. Give them one problem, what it should do instead, and a way to see it themselves.

- **One problem per issue.** A sweep that finds five things is five issues, or one
  tracking issue linking them. `Closes #N` only works when N is one thing.
- **Title states the fault.** "podman_connection module costs ~155ms per prompt", not
  "starship slowness".
- **Pin it in time.** Repo commit, the tool's version, the machine layer (Arch desktop,
  macOS, WSL). A bug without a version is a rumour.
- **Expected, then actual.** Bugs get something runnable: a command, a script, a
  screenshot. Gaps get what cannot be done today and what any fix must respect.
- **What was already ruled out.** Where it does not reproduce, what was tried, what was
  read. Nobody can reconstruct this later.
- **Cause and fix only when checked**, and say how. A hunch is fine if called a hunch.
  Ghostty closes confident unverified root-cause reports as slop and thanks the ones that
  link a test.
- **Link the neighbours.** Where it came from (the PR, the `nextpr:` or `hmm:` comment,
  the discussion) and any issue it blocks, duplicates, or shares a cause with.

Write plainly and stop when the content stops. Cut every sentence the eventual fix's diff
would explain.

**Why:** The user's audit issues (2026-09-07) bundle several unrelated findings each, so
no single PR can close them and they are tiring to read. Ghostty's AI policy (2026-01)
allows AI on issues but requires a human to research and cut, since "AI tends toward
verbosity"; the reports Hashimoto praises are short, verified, reproducible, and pinned to
a version. The user asked for issues without fluff and for a version reference every time.

**How to apply:** Draft, then check: one problem, version pinned, expected and actual,
something runnable, ruled-out list, links to related issues. Same standard as
[[pr-description-guidelines]] for the body's why, and reuse the callouts from
[[pr-review-comment-guidelines]] as issue material.
