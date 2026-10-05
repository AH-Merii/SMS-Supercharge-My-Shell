# Orchestrating agents

Rules for a main thread that runs background agents. Learnt on a multi-agent job (Neovim 0.13
migration, 2026-10-05). Each rule is general; the "e.g." shows the incident it came from.

- **The main thread orchestrates and does no hands-on work.**
  - It splits the work, writes briefs, reviews diffs and evidence, integrates, and reports.
  - Investigations, reproductions and fixes go to agents, even small ones. A new open item
    gets its brief and its agent at once.
  - It reads code only to write a brief or to review a result.
  - E.g. the orchestrator began reproducing a bug itself while four agents ran, and the user
    stopped it twice.
- **A brief is a contract:**
  - **Inputs:** the task, a worktree from the feature tip, the agent's own sandbox, and the
    shared suite. Create the suite and its format before the first agent starts; see
    [test-suites.md](test-suites.md).
  - **Owns / Must not touch:** the files the agent may change, and the files it must leave
    alone.
  - **Process:** signed atomic commits, the time limit, and the waiting, overrun and context
    rules below, written out in full.
  - **Outputs:** the commits, a report in the given format, and the handoff path if it reaches
    the handoff point.
  - **Audit:** the pass conditions on each target, met before the agent reports done.
- **Keep an agent table: id, role, worktree, sandbox.**
  - Agent ids are opaque and easy to swap. E.g. a design change meant for the suite agent went
    to the leak investigator.
- **Serialise agents that touch the same files.**
  - Land A, then B rebases or cherry-picks onto the tip.
  - A finished agent waiting for its turn costs nothing, and it can be resumed later.
- **Integrate by cherry-pick.**
  - Review the diff, check the signature, and skip commits already landed under another hash.
  - Never bypass signing.
- **Cap agent context, about 250k tokens.**
  - Big outputs go to files and are read with grep or tail. Bulk sweeps go to subagents.
  - An agent's state lives in files, not in its context. It and its helpers write results and
    what is left to a file the next agent reads, so any of them can stop at the cap without
    losing work.
  - Past about 200k, the agent writes a handoff covering: task, decisions, commits, what
    failed, what was skipped, what is left, how to verify, and doubts. Then it stops.
  - The orchestrator enforces the cap, because an agent cannot see its own context size.
    E.g. with the cap written only in their briefs, several agents ran to 250-370k.
    - Measure each agent's context from the last usage record in its transcript: input +
      cache-read + cache-creation tokens.
    - Agents spawn their own subagents, so measure every transcript being written, not only
      those of the agents you launched.
    - The watchdog trips a little before the handoff point (e.g. 180k for a 200k handoff), so
      there is room to write the handoff. Then tell the agent to write it and stop.
- **A fresh critique agent continues from the handoff.**
  - It critiques fairly: real defects only, not critique for its own sake. Then it fixes and
    carries on with the task.
  - E.g. two critiques found five real defects that the original agents had missed.
- **Push a newly found sandbox hazard to every running agent at once,** not only into your own
  scripts.
  - E.g. the orchestrator's launcher was already fixed, but the agents' launchers kept the
    leak for hours.
- **Investigate the moment something runs past its expected time.** The orchestrator owns
  agent health, and an agent stops to find out why when its own step overruns.
  - The threshold is whatever is normal for that step, not a fixed number.
  - E.g. a "slow language server" was a host-wide resource exhaustion that had been building
    for hours, found only when the user asked why it was slow.
- **Run a watchdog.** It is a background command that exits on the first anomaly, which wakes
  the orchestrator.
  - Signals: no transcript write for N minutes, tool timeouts, long-running or orphaned
    sandbox processes, shared kernel resources (inotify, fds), daemons started from sandboxes,
    disk growth, agent context (see the cap above).
  - Match tool timeouts on the transcript's structured shape, not on plain text. E.g. a text
    grep fired when an agent read the watchdog script itself.
  - Follow symlinks when checking a file's age.
  - Acknowledge known waits, and reap known leaks under investigation so they don't trip again.
  - An idle agent writes nothing to its transcript, so check for a live background job before
    calling it stuck. Resume a stopped agent with SendMessage.
  - After a trip, handle the cause (fix it, or brief an agent), then restart the watchdog.
- **Wait on callbacks, never on fixed sleeps.**
  - Start runs longer than about 30s in the background, each with a timeout cap.
  - Meanwhile do other independent work, or end the turn with a one-line status. Tested: a
    subagent idle with a live background job is not treated as finished, and the job's exit
    woke it 3 seconds later.
  - E.g. a 9-minute sleep on a 4-minute run, foreground calls hitting the tool timeout, and
    runs backgrounded and then slept on anyway.
- **Surface classifier denials and decisions that belong to the user.** Never route around a
  block, and never act before approval on anything marked "ask first".
- **Status updates are short:** per-agent progress, what is left, what is blocking, and
  whether anything needs the user.

See also [sandbox-isolation.md](sandbox-isolation.md) and [test-suites.md](test-suites.md).
