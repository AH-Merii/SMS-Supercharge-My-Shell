---
name: pr-description-guidelines
description: "PR/issue descriptions carry only what neither the diff nor an inline comment can say: the cause, its consequence, and the constraint that shaped the fix; what counts as the cause shifts by PR type"
metadata:
  node_type: memory
  type: feedback
  originSessionId: dcbb0b42-7add-4235-834a-ec4ddee33004
  modified: 2026-09-09
---

A PR body answers one question: why does this change exist, and what shaped it. Its
length follows from the answer, not from a rule: a one-line fix can be one sentence, a PR
with three independent causes gets a why for each. No "What/How/Testing" sections, no
testing logs, no options recap. Link any related issue you know of; when the PR resolves
one, end with `Closes #N` so it closes on merge, and do not restate the issue, add what it
did not know.

The test for every sentence is where else the reader could learn it:

- **The diff would tell them.** Cut. Any sentence whose subject is the code and whose verb
  is what the code does ("renders X into Y", "sends Z at startup", "writes through
  /mnt/c") is describing the diff. Paths, sequences and tool names in the body are the
  usual sign.
- **An inline comment would tell them.** Cut, and make sure the comment exists. Each
  callout under [[pr-review-comment-guidelines]] has a home on its hunk: a choice made without asking
  is a `coinflip:`, a rejected approach a `nope:`, an untested path a `yolo:`, a workaround
  an `iou:`. The review line already tells the reader those exist, so repeating them in the
  body means meeting each point twice.
- **Neither would.** Keep. This is the cause (what is broken or missing, and what made it
  so), the consequence (what it does to the system), and the constraint that shaped the
  fix when there is one ("closed from the theme file, so the palette still lives in one
  place"). The constraint is design, not mechanics: what the solution had to respect, not
  how it does so. Abstract when the abstraction is clear ("the build breaks on macOS");
  add an example when it is not ("colours degrade" needs "black numbers in bat, blue diffs
  in delta").

What counts as the cause shifts with the PR type, and naming it tells you what the first
sentence must contain:

- **feat:** a want or a gap: what could not be done, or an assumption that stopped holding.
  The constraint is usually the interesting part, since a feature has many possible shapes.
- **fix:** a mechanism: what the code did, under which input. The consequence is the
  symptom. Most likely to carry `Closes #N`.
- **perf:** a measurement: where the time went and how it was found; the consequence is what
  was felt. The one type where a number in the body is the point, since nothing else in the
  PR carries it.
- **refactor:** a friction: what change the old shape made hard or risky. Say behaviour is
  unchanged, since that is the reader's first question; where it is not, that is a
  `coinflip:` on the hunk.
- **chore:** usually external: upstream moved, a pin went stale, a tool grew a flag. "Why
  now" is the whole body; a bump can be one sentence.
- **docs:** a reader who got it wrong or could not find it, and what they did as a result.
  "Updated the README" has no cause.
- **revert:** the new evidence: what broke after the original landed, with a link to it. The
  original's why is already there.
- **test, style:** rarely more than a sentence: the bug a test would have caught, or the gap
  it closes. Style is a chore.

Citing a rule ("the README says so") is not a reason; say what the rule protects against.
Same standard for issue bodies, commit bodies, and subagent prompts that create PRs.

**Why:** The code already shows how; a reviewer can glance at a small diff in two minutes,
and what the diff cannot show is the cause. Essay-length bodies got skimmed (2026-09-08).
#117's first body (2026-09-09) passed the old "a few sentences of why" rule and was still
wrong: it drifted into mechanics through `/mnt/c` and OSC 4, then restated its own
coinflip and yolo comments in prose, and ran to nine lines that got skimmed like an essay.
A per-sentence test catches that; a length limit does not, and the user does not want
discrete limits, since PRs differ.

**How to apply:** Draft, then read each sentence against the three cases above and cut
what has a better home. When the body feels long, the reason is almost always a sentence
about what the code does, or a callout that belongs on a hunk, not a need for fewer words.
