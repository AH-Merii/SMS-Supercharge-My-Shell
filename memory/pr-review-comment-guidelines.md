---
name: pr-review-comment-guidelines
description: "How and when to leave inline PR review comments: only where the code does not show the why, one of eight prefixes (btw coinflip nope hmm yolo iou nextpr maybelater), a short human review line built from their counts, and a zero-width marker that tells agent reviews from the user's"
metadata:
  node_type: memory
  type: feedback
  originSessionId: dcbb0b42-7add-4235-834a-ec4ddee33004
  modified: 2026-09-10T09:58:28.600Z
---

Agent-written PR reviews are inline comments on hunks, posted as one review. No per-hunk
rule: a comment only where the code and its own comments do not show the why. Each
comment starts with exactly one lowercase prefix and a colon, which is how the user tells
agent comments from their own (the user never opens a comment with these words):

- `btw:` context not in the code, nothing to do. A non-obvious reason, an interesting
  one, or what someone without this thread's context would need to follow the change.
- `coinflip:` a choice made without asking, with the alternative. Read before merging.
- `nope:` an obvious approach tried or considered, and what broke.
- `hmm:` needs the reviewer's answer.
- `yolo:` shipped without running on the target; say what was verified instead.
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
by one. Keep each comment to a sentence or three of cause and consequence, per
[[pr-description-guidelines]]. Single-purpose PRs keep the why in the body.
