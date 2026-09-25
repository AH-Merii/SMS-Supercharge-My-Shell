---
name: inline-code-comment-guidelines
description: "DO NOT IGNORE: a code comment is ONE LINE, only when the code is unclear or an obvious attempt fails; all reasoning goes in a PR inline comment"
metadata:
  node_type: memory
  type: feedback
  modified: 2026-09-25
---

**DO NOT IGNORE THIS MEMORY. READ IT BEFORE WRITING ANY COMMENT IN CODE.** On 2026-09-25 it
was in the index, it was read, and paragraph-long comments were written anyway; the user
had to say it three times. ONE LINE. ONLY WHEN THE CODE IS UNCLEAR OR AN OBVIOUS ATTEMPT
FAILS. EVERYTHING ELSE GOES ON THE PR.

Comments are for humans. Everything below follows from that: write for the next person to
open the file, who is often me in six months, and give them the intent, the context and
the quirks. Not a second rendering of what the code already says.

A comment has to earn its line. Before writing one, ask whether the code could carry the
point instead: a clearer name, a smaller function, a different structure.
Self-documenting code comes first, and a comment is what is left when the code genuinely
cannot say it.

What it is for is the why, never the what. The code already shows what happens, so
`int age = 10; // age holds the age` costs the reader attention and returns nothing.
Explain the decision instead, and most of all where it is not the obvious one: why this
approach, why this value, why not the thing a reader would reach for.

Quirks and workarounds are the clearest case for a comment. A hack, a shape forced by
some tool's behaviour, an ordering that matters: say so where it sits, or the next reader
tidies it away.

Dead code gets deleted, not commented out. Git remembers it.

Stay consistent. Match the density, voice and placement of the comments already in the
file, so a reader is not reading two authors at once.

A comment is not a transcript. It does not need the journey that reached the conclusion,
and it does not need the context of the conversation that produced it. The test is
whether a future reader needs it to change this code correctly; if some part of that
conversation does bear on a future edit, that part goes in and the rest stays out.

Keep it short (user, 2026-09-25, twice). A comment is one line, two at most, and exists
for two reasons only: the code is hard to read (a regex, a bit of arithmetic) and needs a
what, or the obvious alternative does not work and the reader must be stopped from trying
it (`makepkg -i` prompts again). Not every why needs saying; a clear name or a note in the
plan output usually carries it. Everything else, the investigation, the alternatives, the
distro quirk, the history, is a PR inline comment or PR comment: that is the record the
team refers back to, and it lives with the PR, not the file.

**Why:** every comment is a line the reader pays for. One that restates the code, or
narrates how we got here, is noise that also rots: the code moves, the story stops being
true, and the reader keeps trusting it anyway.

**How to apply:** two questions before writing, in order. Could the code say this itself?
Then: will this change what a future editor does? Only a yes to the second earns the
line, one line, and only when the code cannot be made clear or the reader would try
something obvious that fails. The context goes on the PR.
