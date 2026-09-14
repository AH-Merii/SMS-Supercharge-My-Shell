---
name: landing-a-pr
description: "Immediately before merging a PR, rebase it onto the latest origin/main; then squash and merge by default, rebase and merge when separate commits are worth keeping, merge commits only when forced"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 729541b5-93a7-433a-8023-12f62068b0c2
  modified: 2026-09-10
---

Fetch and rebase onto the latest `origin/main` immediately before merging a PR — not on
every push. Push freely while the branch is in review; rebase when it is about to land.

**Why:** other agents land changes concurrently, so main may have moved since the branch
was last green. A change that does not conflict textually can still break the branch — a
renamed helper, a changed default, a moved file — and git reports a clean rebase either
way. Rebasing at merge time means the last CI run is against what main actually is,
rather than against whatever it was when the branch was opened.

Merge method, in order of preference:

1. **Squash and merge.** The default.
2. **Rebase and merge.** When the branch holds several unrelated commits worth keeping
   separately in history. This costs the signatures outright: GitHub rewrites the commits
   and cannot sign on the user's behalf, so they land unsigned, not merely re-signed. A
   tradeoff the user has accepted deliberately — do not treat it as a mistake to warn
   about each time.
3. **Merge commit.** Only when neither of the above will do.

The mechanics behind that ranking: GitHub's merge button never fast-forwards, even when
the branch descends directly from the base. Squash and merge-commit both build a new
commit signed by GitHub's web-flow key; rebase-and-merge "always updates the committer
information and creates new commit SHAs" and arrives unsigned. `gh pr merge` uses the
same three methods. Fast-forward-only has been requested since 2021 and is unimplemented
— do not wait for it. The only way to keep the user's own signature on main is to
fast-forward it directly (`git push origin origin/<branch>:main`), which is not the
chosen workflow here.

Signed originals survive either way: `refs/pull/N/head` persists after the branch is
deleted, so `git fetch origin refs/pull/119/head` still returns the user's signed commit.

**How to apply:** `git fetch origin && git rebase origin/main` as the last step before
merging, force-push with `--force-with-lease`, wait for CI, then merge. When a branch has
several unrelated commits, first ask whether it should have been two PRs; reach for
rebase-and-merge only when the answer is genuinely no. Related:
[[when-a-pull-conflicts]], [[git-identity-never-write-config-local]].
