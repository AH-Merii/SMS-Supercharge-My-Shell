---
name: worktree-from-fresh-origin
description: "When creating a worktree or branch for a task, fetch first and base it on the remote tip of the branch the work will merge into: origin/main by default, origin/<feature> while the task targets a long-lived feature branch; then enter it with EnterWorktree path="
metadata:
  node_type: memory
  type: feedback
  originSessionId: 3b0b5be8-62d6-4aac-b353-c8376eadb248
  modified: 2026-09-25
---

A new worktree starts from the remote tip of the branch it will merge into, fetched at
that moment. By default that is `origin/main`. When the task says it merges into a
long-lived feature branch (`nix-main` while the Nix migration, #123, is open), it is
`origin/<feature>` instead, and the feature branch is what gets fetched. Never the local
`main`, never whatever commit the current checkout happens to be sitting on.

**Why:** the primary checkout's local `main` goes stale, because work happens in
worktrees and nobody pulls there. A branch cut from a stale base carries old code, its
diff against the real target is padded with changes that already landed, and it meets a
rebase or a conflict at PR time that a fresh base would have avoided. Parallel jobs make
it worse, since several may have merged since the last pull. The cached `origin/*` refs
have the same problem in miniature: they are only as new as the last fetch.

**How to apply:** decide the target branch first, from the task or the ticket. Then,
from any checkout of the repo:

```
git fetch origin <target>
git worktree add "$(git rev-parse --path-format=absolute --git-common-dir)/../.claude/worktrees/<name>" \
  -b <branch> --no-track origin/<target>
```

The path is anchored on the primary checkout because a bare `.claude/worktrees/<name>`
is relative to the working directory, and run from inside a worktree it nests the new
one under it, where a forced removal of the outer one takes it along. `--no-track`, or
the branch's upstream would be the trunk and a `git pull` would merge it in. Then
`EnterWorktree` with `path=` set to that directory, so the session moves there and the
worktree is tracked for removal on exit. `EnterWorktree` on its own creates from
`origin/<default-branch>` with no per-call base, and worktrunk's `wt switch --create`
bases on the local default branch with no fetch; neither takes a feature branch, so
create by hand as above, and with `wt` fetch first and pass `--base origin/<target>`.
Before the PR, confirm the base is current: after a fetch, `git log --oneline
HEAD..origin/<target>` shows nothing, and `git log --oneline origin/<target>..HEAD` shows
only the task's own commits.
