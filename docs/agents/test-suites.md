# Test suites

Rules for building, running and keeping tests across agents. Learnt on a multi-agent job
(Neovim 0.13 migration, 2026-10-05). Each rule is general; the "e.g." shows the incident it
came from.

- **One sandbox, one suite, one entrypoint.**
  - Keep an inventory that marks each check keep, merged or dropped, with the reason.
  - Each agent deletes its own scratch sandbox and run dirs when its work lands.
  - E.g. without this the job ended with 9 sandboxes, 48G and about 260 scripts, and no way to
    re-verify everything.
- **Run tests in tiers.**
  - Scale the check to the change: a one-line config change gets a load-only check, not health
    comparisons and a full suite run.
  - Tag each check with areas, and map changed files to areas so a run picks its own checks.
  - A feature in development iterates on a mini suite of its own checks plus the area it
    touches, on one target unless the behaviour is target-sensitive.
  - When the feature lands, promote its useful checks into the suite.
  - The full suite on every target runs only before a branch lands and in the final
    regression.
- **Fail fast.**
  - Each check has a time budget, and going over it is a failure.
  - Waits are event-driven and short.
  - Stacked fixed caps make every miss expensive. E.g. 90 + 60 + 4 + 60s cost 3.5 minutes per
    missing result; a missing dependency should fail in seconds with a reason.
- **No tautological tests.** What a check may assert is set by
  [judge-a-test-in-both-directions.md](../../memory/judge-a-test-in-both-directions.md).
  - Asserting that something is absent ("this key is unmapped") is not a keeper, because a
    valid future change turns it red.
- **Prove each check both ways.**
  - Run it on the old commit and expect red, then on the fix and expect green.
  - Mutation runs (break the fix on purpose) show which checks are real. Keep the mutation
    lists as a manual reference rather than a framework.
  - Distrust a sub-second check. Run it verbosely once to confirm it asserts what it claims,
    then prove it with a mutation.
- **Assert on every channel an error can reach.** A harness passes the failures it never
  reads.
  - E.g. errors that reached only a UI's message history went unseen, so checks that looked
    green were red.
- **First-run checks use a throwaway copy** of the state that is deleted afterwards.
- **Write the gotchas of the system under test into the suite README** the first time someone
  hits one, so the next agent doesn't rediscover it.

See also [sandbox-isolation.md](sandbox-isolation.md).
