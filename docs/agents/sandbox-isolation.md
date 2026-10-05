# Sandbox isolation

Rules for testing on a live machine without touching its real state. Learnt on a multi-agent
job (Neovim 0.13 migration, 2026-10-05). Each rule is general; the "e.g." shows the incident it
came from.

- **Isolating config dirs is not a sandbox.** The process still shares PATH, home, network,
  processes and kernel limits. Use a container or VM when real isolation matters.
- **Typical leaks** (all four happened):
  1. **Inherited PATH.** The live tool dirs on PATH make missing sandbox tools fall back to the
     live ones. That writes into live state and makes green results invalid.
  2. **Copied installs.** State seeded from the live setup keeps absolute paths in wrappers,
     shebangs and env vars that point back at live binaries.
  3. **Global tool config with side effects.** E.g. a global `core.fsmonitor=true` left a git
     daemon for every git command in every throwaway repo. 900 daemons used up the per-user
     inotify limit, and unrelated apps on the desktop failed.
  4. **Child processes that outlive their parent.** E.g. a language server's plugin
     subprocess re-parented to init.
- **Every launcher must:**
  - point the config, data, state and cache dirs at the sandbox, and strip live tool dirs from
    PATH;
  - switch off global tool settings with side effects by env, never by editing the user's
    config. For git: `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.fsmonitor
    GIT_CONFIG_VALUE_0=false`;
  - run each case in its own process group, then report and kill any survivor. A case that
    leaks a process fails.
- **Seed from a copy, then scrub it.** Reflink-copy (`cp -a --reflink=auto`) instead of
  downloading, then grep the copy for live absolute paths and repoint or reinstall what it
  finds.
- **After a run, assert:**
  - nothing under the live dirs changed (`find -newer <stamp>`);
  - shared kernel resources are back to baseline;
  - no daemon was left running.
- **Once isolation is fixed, re-run every check that passed before.** A pass that relied on a
  leaked live tool proves nothing.
- **Run GUI checks in a separate window with its own identity.**
  - Use a unique window class and no single-instance reuse.
  - Drive the app over its remote socket and capture the window by id.
  - Close the window afterwards.
  - Never touch the live session's own services.
