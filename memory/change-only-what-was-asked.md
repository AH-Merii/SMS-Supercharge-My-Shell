---
name: change-only-what-was-asked
description: "When making a config change the user asked for, change only that: no bundled while-I-am-here tweaks, because they confound the test and alter behaviour without consent"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: cdbe5035-eb49-423b-9f99-5376f8af6614
  modified: 2026-09-04T11:49:33.861Z
---

When the user asks for a specific config change to test a hypothesis, change only that. Don't bundle in adjacent "while I'm here" tweaks (e.g. flipping `cursor-style-blink` while disabling shaders).

**Why:** Extra changes alter visible behavior the user didn't consent to, and they confound the experiment — if the feel changes, you can't tell which variable did it. The user caught this and asked why the unrelated setting moved.

**How to apply:** Make the one requested change, verify it, and *suggest* further levers as a next step rather than applying them. Related: [[dotfiles-layers-and-mise]].
