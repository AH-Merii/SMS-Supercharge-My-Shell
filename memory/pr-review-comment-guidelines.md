---
name: pr-review-comment-guidelines
description: "How and when to leave inline PR review comments, read before commenting on PRs"
metadata:
  node_type: memory
  type: feedback
  originSessionId: dcbb0b42-7add-4235-834a-ec4ddee33004
  modified: 2026-09-10
---

Agent-written PR reviews are inline comments on hunks, posted as one review. No per-hunk
rule: a comment only where the code and its own comments do not show the why.
Read the code's own comments before writing, since the why is often already there, one
line up.

A comment exists to carry something the reader would be worse off not knowing. Find that
thing, confirm it is true, then look for a prefix. If one fits, use it. If none fits,
that is information rather than a problem to route around: say the thing plainly under
the nearest prefix, or leave the comment unwritten. Never the other way round. A prefix
is a form with a slot in it, `nope:` wants an approach that failed, `yolo:` wants an
untested path, `iou:` wants an exit condition, and starting from the prefix means filling
that slot whether or not anything real goes in it. That is how a small true point grows
into a comment-shaped story.

A claim that something matters needs the context that makes it matter. "slow",
"expensive", "on every call" mean nothing on their own. Say how often and in what
situation, and let that settle whether the cost is real. "twice, in a task you run by
hand when provisioning a machine" kills the argument. "on every keystroke, through a
neovim hook" makes it, with no number anywhere. An exact count is good when you have one,
and the sequence of events is enough when you don't. If you can give neither, the cost is
not a justification, so do not use it as one. The same holds for "fragile" and
"confusing": fragile when what changes, confusing to whom.

An inline comment is for what is anchored to that hunk. A caveat true of the whole PR,
untested everywhere or a constraint that shaped every file, belongs in the PR description
instead. The test: could the reader act on it by looking only at this hunk? How the
comment itself should be worded is [[how-my-writing-should-read]], which applies to every
comment here.

Each comment starts with exactly one lowercase prefix and a colon, which is how the user
tells agent comments from their own (the user never opens a comment with these words):

- `btw:` context not in the code, nothing to do. A non-obvious reason, an interesting
  one, or what someone without this thread's context would need to follow the change.
- `coinflip:` a choice made without asking, with the alternative. Read before merging.
- `nope:` an obvious approach tried or considered, and what broke.
- `hmm:` needs the reviewer's answer.
- `yolo:` shipped without running on the target; say what is untested and how the
  reviewer could test it, and why we couldn't test it. Never an inventory of what was exercised, since that is a testing
  log, which [[pr-description-guidelines]] bans.
- `iou:` a workaround: what it is, why the proper route is not available now, and the
  condition for removing it. A callout, not a scribble: the code should not fill up with
  workarounds, so each one is flagged and the reviewer decides whether it stays.
- `nextpr:` committed followup; must carry an issue number, else it is a maybelater.
- `maybelater:` promising idea, considered, out of scope, unscheduled.

One comment can cover a range of lines in one file (`start_line` + `line`, both on the
same side), but never two files; for a why that spans files, comment once and name the
other file in the body.

Scribbles = btw, nextpr, maybelater. Callouts = coinflip, nope, yolo, iou, hmm. The
review body is one short line built from them. It never announces or describes the
comments themselves (no "why each hunk", no "see the notes/margins"). Count them from
the review file rather than by hand:

    jq '[.comments[].body | capture("^(?<p>[a-z]+):").p]
        | {scribbles: (map(select(IN("btw","nextpr","maybelater"))) | length),
           callouts: (map(select(IN("coinflip","nope","yolo","iou","hmm")))
                      | group_by(.) | map("\(length) \(.[0])") | join(", "))}' review.json

Three forms, in order of preference. Never repeat the previous agent review line, and
avoid the last three where the pool allows; two counted lines in a row is the thing to
avoid most.

- **No callouts:** a plain fixed line. "fyi", "btw", "heads up", "for the record",
  "some context".
- **One callout:** name it in the singular. The plural mood lines below read as a lie
  when there is one comment.
  - coinflip: "one call in there worth a second opinion" / "made one call without asking,
    easy to flip" / "one judgement call inline, not precious about it"
  - nope: "one dead end in here, the hunk says why" / "one approach that didn't survive"
  - yolo: "one untested spot, flagged inline" / "one path in here I couldn't run" /
    "one spot I couldn't run, noted inline"
  - iou: "one workaround, with its exit condition" / "one temporary thing in here"
  - hmm: "one open question inline" / "one thing I need you to decide"
- **Two or more callouts:** the mood of the dominant kind, written for whoever is
  reviewing, not for the user specifically. Two phrasings each so consecutive reviews of
  the same kind do not repeat:
  - coinflip: "made a few calls in there, happy to go either way on any of them" /
    "a couple of judgement calls, none of them precious"
  - nope: "tried the obvious things first, they didn't stick" /
    "the simple version doesn't survive contact, details on the hunks"
  - yolo: "couldn't run a fair bit of this, so read it as untested" /
    "this is unrun on the machine that matters"
  - iou: "more workarounds than I'd like, each one says when it can go" /
    "a couple of temporary things in here, both with an exit condition"
  - hmm: "a lot I'm not sure about here, need some input" /
    "a few open questions before this is right"
  - mixed: "a few things worth a look before this goes in" /
    "worth a read before merging"
- **The counted line** ("nine scribbles and a coinflip") is the exception, not the
  default. It needs four or more scribbles and exactly one callout, and it must not have
  been the previous agent review line. Never with no scribbles: "no scribbles and a
  coinflip" is a sentence about nothing. Numbers as words up to twelve; "a" for the
  callout but "one hmm"; the callout goes last.

Agent reviews and the user's reviews come from the same GitHub account, so the review
body ends with a zero-width space (U+200B, `​` in JSON) as an invisible marker.
The last three agent review lines on the repo, for the rotation (`{owner}` and `{repo}` are filled in by gh from the current checkout):

    gh api graphql -F owner="{owner}" -F name="{repo}" -f query='query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) { pullRequests(last:20) { nodes { number reviews(last:5) { nodes { body createdAt } } } } } }' \
      --jq '[.data.repository.pullRequests.nodes[] | .number as $n | .reviews.nodes[]
             | select(.body | endswith("​")) | {n:$n, body, createdAt}]
            | sort_by(.createdAt) | .[-3:] | .[] | "#\(.n) \(.body)"'

**Why:** a comment on every hunk plus a body announcing them read as noisy and robotic
(2026-09-09). The prefixes make authorship and required action greppable; the sentence
line lets the reviewer decide from the timeline whether to open the diff. Lines that
point at the notes ("the margins say...") sounded like an LLM; lines that just say the
thing do not.

**How to apply:** `gh api -X POST repos/OWNER/REPO/pulls/N/reviews --input review.json`
with `event: COMMENT`, the full commit SHA (a short one is rejected), `body` as the line
above plus the marker, and `comments[]` of `path`, `line`, `body`. A submitted review
cannot be deleted, so get the line right before posting; its comments can be deleted one
by one. Each comment carries cause and consequence, at whatever length the reader needs to
follow it on the first read, per [[how-my-writing-should-read]]. Single-purpose PRs keep
the why in the body.
