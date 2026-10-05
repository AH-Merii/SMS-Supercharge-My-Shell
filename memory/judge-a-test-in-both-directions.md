---
name: judge-a-test-in-both-directions
description: "Tests exist for complex behaviour with edge cases that are hard to verify by reading, never for configuration state or preferences; a test must fail on a real violation and stay green on any legitimate change of mind"
metadata:
  type: feedback
---

Recorded 2026-09-25, reviewing the nix-main flake checks. The user's rule: a test is for
complex behaviour whose edge cases are hard to verify by reading (the linker's selection and
refusals, an activation step that must cope with a missing file, a dangling link, content it
must not overwrite). It is never for state: which programs are installed, which runtimes
exist, that mise declares no global tools, which font ghostty names, what the session PATH
is. Those are decisions the user may reverse, and a test that pins them breaks on a change of
mind. Removing a program (say worktrunk) must not break any test.

I got this wrong twice. First I graded `runtimes-and-pins` as "solid" because it went red on
every mutation, though half those reds were legitimate changes (deleting `programs/go`).
Then I proposed "program-specific checks that ask the real tool" (fontconfig, niri validate,
mise ls) for fonts, cursor, PATH and mise; the user rejected those as the same mistake,
because they still verify a configuration the user may change.

**Why:** a mutation kill only counts when the thing broken was a bug. Counting reds rewards
snapshot tests and restatements. A comment or PR saying a hard-coded list is "the point" is
the author's intent, not evidence the test is good.

Settings do get one kind of test: validity. "The config parses", "the program's own
validator accepts it", "it is formatted" pass for any valid config, so they never pin a
choice; they only fail on a broken file.

**How to apply:** for every test, reviewed or proposed, ask first whether it tests our logic,
the validity of a config, or a config's values. Values get no test, not even a consistency
check between two of them; validity and logic do.
For logic, ask both: (1) what legitimate change turns this red (removing a program, renaming
an internal attribute, changing a preference): any yes is a defect; (2) what real violation
leaves it green. Test logic on fixtures with hand-written answers, not on the real tree. See
[[change-only-what-was-asked]].
