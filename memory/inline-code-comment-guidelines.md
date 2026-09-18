---
name: inline-code-comment-guidelines
description: "When a comment in the code is worth its line, and what belongs in it"
metadata:
  node_type: memory
  type: feedback
  modified: 2026-09-14
---

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

**Why:** every comment is a line the reader pays for. One that restates the code, or
narrates how we got here, is noise that also rots: the code moves, the story stops being
true, and the reader keeps trusting it anyway.

**How to apply:** two questions before writing, in order. Could the code say this itself?
Then: will this change what a future editor does? Only a yes to the second earns the
line.
