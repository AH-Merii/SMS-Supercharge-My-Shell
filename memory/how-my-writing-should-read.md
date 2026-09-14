---
name: how-my-writing-should-read
description: "Read before writing prose the user will read: a PR body or review comment, a GitHub issue, a reply reporting a decision, or a memory file. The voice layer over pr-description-guidelines and pr-review-comment-guidelines: first person, a topic sentence before the context, every referent named, and the user's own register"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 729541b5-93a7-433a-8023-12f62068b0c2
  modified: 2026-09-10
---

Everything below exists to fix one failure. Optimising for brevity cuts context along
with fluff, because the two look alike when length is the only metric. What survives
reads like a changelog entry: verbless, authorless, full of definite articles pointing at
things the reader was never told about.

Covers PR bodies, inline review comments, issues, replies in session, and these memory
files. Not commit messages, since conventional-commit subjects are verbless and authorless
by design and none of this was derived from them. Rules 1 and 2 govern _prose about your
own work_, so they do not apply to rule statements, templates, or checklists.

## Rules

1. **First person, owning the call.** "I opted to…", "I checked whether…", "I couldn't…",
   "I still need to check whether…" is a person reporting a decision, not a fact that
   materialised on its own. Tense follows the decision rather than a rule: past for a call
   already made, present for one still open. An open call is still owned:

   > I still need to check whether this is the most idiomatic approach, however I'm
   > leaving this as is for now, since it works. This is something we can look into later.

   (The prefix still applies, see [[pr-review-comment-guidelines]] for which one and what
   it obliges you to add.)

   Ownership matters most where the decision went against what the user asked for. Say
   what was asked, then what was done instead, rather than attributing the alternative
   back to them.

   Owning a call is not licence to supply reasoning you did not have. Where the decision
   was never weighed, "this is how it came out, I didn't weigh it" is a legitimate thing
   to write and the honest one.

2. **Open with one short sentence saying what you did or what you claim.** "I opted to use
   cmd instead of powershell." "The order here actually matters." Name both sides of a
   choice so the reader can decide at a glance whether to keep reading. Context comes
   second, once they know what it is contextualising, then the alternatives you rejected
   and what the choice costs. The worst case is no topic sentence at all: "compared after a
   key-sorted round trip through jq" never tells the reader what its subject is, in any
   order. Bold labels and headings are exempt, since they are not prose.
3. **Then say what the thing is for.** Purpose is what the code is for, which the diff
   cannot show: "the function needs that path to find settings.json from inside WSL". It
   lands in the context slot, straight after the topic sentence. Describing what the code
   does, step by step, is a separate question and belongs only to PR bodies, where
   [[pr-description-guidelines]] cuts it. In a comment the mechanics are often the cause,
   so state them.
4. **Name every project-specific referent, in the same paragraph.** Functions, files,
   steps, tools, versions. GitHub will do the pointing for you: quote a line or another
   comment with `>`, link a permalink to a line or a range, reference a file, or cite
   another PR or issue by number. Use those rather than describing a location in prose,
   since "the two quirks handled on the next line" tells the reader nothing they can
   follow. An unfamiliar tool gets half a clause: "wslvar, which reads a Windows env var
   from inside WSL". Ordinary
   definite articles ("the reader", "the diff") are fine, since this is about nouns only
   someone inside your head could resolve.
5. **Never manufacture a referent to satisfy rule 4.** If a name, version, path, cause,
   cost or frequency was not actually checked, say so in the sentence, in plain words:

   > two quirks I haven't looked into yet

   > This was working, I'm not sure when it broke, I can probably look into it if need be.

   A confident wrong referent is worse than the vague original, because the reader cannot
   tell it was invented.

6. **Break the paragraph when the second idea starts.** One sentence is a complete comment
   when one sentence is the whole cause, so do not pad to reach a second paragraph. The
   user has said the split makes it easier to read.
7. **Length is not the metric.** Cut restatement, and cut inventories of work already
   done. Never cut context. The line between them: a check you ran is context when its
   result changes the decision or bounds the claim, and an inventory when the decision
   holds either way. A
   longer passage that parses on the first read beats a short one that needs two, and a
   plain word is worth the extra word or two it costs: "I haven't looked into it" over
   "unenumerated", "I'm not sure when it broke" over "I haven't pinned which".
8. **Keep the hedges that inform, cut the ones that protect.** "I checked winget and it
   doesn't seem to be there" tells the reader how firm the finding is, and stays. "It
   seems that this may perhaps" protects the writer, and goes.
9. **End with the reader's next move**, where there is one: how to flip the decision, how
   to test the thing you couldn't.
10. **Playfulness only where you admit a limit or concede a call**, at most once per
    comment, and never
    in a sentence carrying a technical claim. "life's too short XD" earns its place because
    it sits on an admission.
11. **Write in the user's register.** Including product names
    ("windows terminal", "powershell"), contractions, plain connectives, the occasional
    trailing "..". Sounding like the user costs nothing on a review comment, since the
    prefix is what marks the comment as the assistant's. Basically try to sound more human.
12. **No em dashes.** A comma, a full stop, or brackets. This applies to everything,
    including these memory files.

The `btw:` / `coinflip:` / `nope:` openers on the examples below come from a closed
vocabulary of eight prefixes, defined with the rules for choosing between them in
[[pr-review-comment-guidelines]].

## How to apply

The audience differs by surface. For a PR body, review comment or issue, read it as
someone who has not seen the rest of the diff and was not in the conversation. For a reply
in session, the user _was_ in the conversation and just asked the question, so do not
re-explain their own request back to them. Rule 4 still applies, the cold-reader test does
not.

Related: [[pr-review-comment-guidelines]], [[pr-description-guidelines]],
[[github-issue-guidelines]]

## Worked examples

From PR #117 on SMS-Supercharge-My-Shell, 2026-09-10. `Posted:` is what the assistant
actually wrote and `Rewritten:` is the user's own correction, with the font names put
right so the content is safe to copy along with the shape. Every other name in these
examples is real.

**Owning the call.**

> Posted: `coinflip: Cascadia Code NF rather than the CaskaydiaCove Nerd Font you asked
for. Same cursive italic and ligatures, but it is Microsoft's own build and ships
inside Windows Terminal, so nothing gets installed on Windows. CaskaydiaCove is not in
winget, so it would be a manual download per machine. One string here flips it back.`

> Rewritten: `coinflip: I opted to use cascadia code nf instead of caskaydia cove nf (the
community nerd fonts patch) since the former ships with windows terminal and the latter
does not.`
>
> `I also checked if we could use winget to install it easily and it doesn't seem to be
the case. So it's a trade-off really, but we could go either or, pretty sure I can
figure out a way to get caskaydia installed if we really wanted to.`

The posted version has a verbless opener, no "I", and "you asked for" puts the deviation
on the user's side. The rewrite owns it, reports the winget check as something _I_ went
and did, and leaves the door open instead of closing with a terse "one string flips it
back". Take the ownership and the open door, but keep the posted version's consequence
("so nothing gets installed on Windows"), which the rewrite drops and which is the reason
the choice matters.

**Naming the referent.**

> Posted: `btw: after tools, not next to deps, because the render needs jq and jq arrives
with the tools step.`

> Rewritten: `btw: the order here actually matters, (the render) needs jq as a dependency
and jq is installed as part of the tools step.`

The user bracketed `(the render)` to show they had no idea what it referred to, so the
brackets are the complaint and not the fix. "The render" was a phrase from the assistant's
head, not from the diff. What should have been posted:

> `btw: the order here actually matters. mise run winterm renders settings.json with jq,
since jq is a prerequisite we need to make sure to install it prior to running the winterm step.`

**A topic sentence, then the context.** The user started this one and stopped partway,
so it is a fragment rather than a full rewrite, kept because the opener is the whole point:

> Posted: `nope: PowerShell for %LOCALAPPDATA% takes about a second to start, and wslvar
is not on every distro. cmd.exe answers instantly, at the cost of the two quirks handled
on the next line.`

> The user's opener: `nope: I opted to use cmd instead of powershell. While it's not
immediately obvious powershell takes about a second to ... etc..`

Eight words tell the reader what the comment is about and name both sides of the choice.
The posted version opens on a fragment with no subject, alludes to "the two quirks handled
on the next line" without saying what they are, and drops `wslvar` in with no gloss. The
user's instruction alongside it: summarise what the function was doing and why. Written
out in full, by the assistant rather than quoted from the user, in the same register:

> `nope: I opted to use cmd.exe instead of powershell for reading %LOCALAPPDATA%.`
>
> `the function needs that path to find windows terminal's settings.json from inside wsl,
and I wanted it without adding a visible pause to every run. powershell.exe is the
obvious pick since reading a windows env var is exactly what it's for, but it takes
about a second to start and we'd pay that on every call. wslvar is instant, but it
ships in a separate package (wslu) rather than with wsl itself, so a bare ubuntu image
would silently get an empty path.`
>
> `cmd.exe answers immediately and exists wherever wsl does, so I went with it. the
trailing CR and the UNC warning are the price, and the next line strips both.`

**Purpose before technique.** No rewrite for this one. The user narrated their own
confusion instead, thought by thought as they read it, which is the more useful record.

> Posted: `btw: compared after a key-sorted round trip through jq rather than byte for
byte. Windows Terminal rewrites the file in its own layout whenever the settings UI
saves, so a byte comparison would report a change and back the file up on every run.`

Reading it live: _what are you even talking about??_ → _okay so maybe this is the context_
→ _so we want to avoid a byte comparison because it would report the change on every run …
which is not what we want?? because??_ and by then the opening was forgotten. The purpose
is never stated anywhere in the comment. It should have led with it: back up only when the
user actually changed something.
