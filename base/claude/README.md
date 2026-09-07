# Claude Code Configuration

Global settings, managed via [GNU Stow](https://www.gnu.org/software/stow/) from
`~/SMS-Supercharge-My-Shell/base/claude/`.

Apply changes:

```bash
cd ~/SMS-Supercharge-My-Shell && stow claude
```

## Directory Structure

```
claude/
└── .config/claude/
    └── settings.json    # the entire config -- one file
```

`CLAUDE_CONFIG_DIR` is set to `$XDG_CONFIG_HOME/claude` by
`base/fish/.config/fish/conf.d/01-env.fish`, so `~/.config/claude/` is the
active config root.

That export only exists inside a fish shell. A Claude Code process that is not a child of
fish -- a desktop launcher entry, a systemd user unit, an IDE started from the session
rather than from a terminal -- never sees `CLAUDE_CONFIG_DIR` and falls back to the default
`~/.claude/`, where none of this config lives. If that becomes a problem, export the
variable at session level (for example `~/.config/environment.d/*.conf` on a
systemd-managed session) rather than duplicating the settings.

There is deliberately **no `.claude/` half** to this package. Files placed at `~/.claude/`
would sit outside `CLAUDE_CONFIG_DIR` and never be read. This package previously carried a
`.claude/` tree (CLAUDE.md, agents, commands, skills) that was inert for exactly this reason.

## What's Configured

| Group | Settings |
|-------|----------|
| Privacy | `DISABLE_TELEMETRY`, `DISABLE_ERROR_REPORTING`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, `feedbackSurveyRate: 0` |
| Context | `cleanupPeriodDays: 365` — a year of transcript history vs. the 30-day default |
| Updates | `autoUpdatesChannel: stable` — ~1 week behind `latest`, skips major regressions |
| Token limits | `CLAUDE_CODE_MAX_OUTPUT_TOKENS`, `MAX_MCP_OUTPUT_TOKENS` |
| Permissions | `defaultMode: auto`, a git allow list, an `ask` list for git commands that can discard work, path-anchored deny rules for secrets |
| Git | `attribution: { commit: "", pr: "" }` — no assistant byline in commits or PRs |
| Ergonomics | `editorMode: vim`, `theme: dark`, `tui: fullscreen`, `agentPushNotifEnabled` |
| Spinner | `spinnerVerbs` — 45 custom verbs, `replace` mode |
| Status line | `ccstatusline` (see below) |
| Plugins | `terminal-icons` via the local marketplace (see below) |

### Permissions

`defaultMode: auto` auto-approves tool calls with background safety checks that verify
actions align with the request. Rules are evaluated deny, then ask, then allow; the first
match wins.

- `allow` pre-approves the everyday git commands. Most are read-only, but `git add`,
  `git commit`, `git branch`, `git switch`, `git fetch`, `git pull`, `git tag`, `git remote`
  and `git worktree` write to the repository -- the list means "safe to run without
  asking", not "read-only". `ls`, `which` and `mkdir` round it out. There are deliberately
  no wildcard entries for interpreters or package managers (`node *`, `npm *`, `pnpm *`):
  they pre-approve arbitrary code (`node -e`, `npx <pkg>`, `npm run`) and so bypass every
  deny rule below. Auto mode drops such rules on entry anyway, so they only ever took
  effect after switching to `default`/`acceptEdits` -- exactly when they should not.
  Add exact commands (`Bash(npm test)`) if a workflow needs them. Built-in read-only
  commands such as `cat`, `head`, `grep` and `ls` never need an allow rule.
- `ask` forces a prompt, even in auto mode, for `git checkout`, `git restore` and
  `git stash`, which can discard uncommitted work.
- `deny` blocks reads of secrets wherever they live: `.env` and `.env.*` anywhere on the
  filesystem (`Read(//**/.env)` -- the `//` prefix anchors at the filesystem root; a bare
  `Read(.env*)` only matches under the current directory), `*.pem`, and the whole of
  `~/.ssh`, `~/.aws` and `~/.config/op` (`~/` anchors at the home directory). A `Read`
  deny also hides the files from Grep/Glob, blocks Edit/Write on them, and covers the
  readers Claude Code recognises in Bash (`cat`, `head`, `tail`, `sed`) plus redirections,
  which is why there are no separate `Bash(cat *.env*)`-style rules: those matched only
  the literal spelling and gave false coverage.

Deny rules are **not a hard security boundary** -- they reduce accidents, not determined
access (`python3 -c 'print(open(...).read())'` is not caught). There is intentionally no
`sandbox` block; adding one is self-contained and touches nothing else.

### Status Line

`statusLine` runs `ccstatusline`, pinned as `npm:ccstatusline = "2.2.28"` in the global
mise config (`../mise/.config/mise/config.toml`). The command uses the absolute shim path
because Claude Code launched from a desktop launcher has no shell-activated `PATH`. Its
widget layout lives in a separate stow package — see `../ccstatusline/README.md`.

Both packages and the binary are required for the status line to render:

```bash
cd ~/SMS-Supercharge-My-Shell && stow mise claude ccstatusline && mise install
```

### Plugins

The `terminal-icons` plugin lives at the repo root in `plugins/`, **not** inside this
package. `~/.config/claude/plugins/` is a directory Claude Code owns and writes to itself
(`known_marketplaces.json`, `marketplaces/`), so stowing into it invites conflicts.

Instead, `extraKnownMarketplaces` points at the repo path directly:

```json
"extraKnownMarketplaces": {
  "local-plugins": {
    "source": { "source": "directory", "path": "~/SMS-Supercharge-My-Shell/plugins" }
  }
}
```

`plugins/` sits at the repo root, outside the stow layers, so it is never linked into `~/`.
The plugin works straight from the repo with no stow step.

The `~` in that `path` is a convenience for reading the file, not something the docs
promise to expand: every documented `directory` source uses an absolute path. It works on
this machine because the marketplace was registered once with
`/plugin marketplace add /home/<user>/SMS-Supercharge-My-Shell/plugins`, and Claude Code
stores the resolved absolute path in `~/.config/claude/plugins/known_marketplaces.json`
(a runtime file, not stowed). On a fresh machine run that command once with the absolute
path before expecting `enabledPlugins` to resolve. The `~` in `statusLine.command` is
fine: that string runs through a shell, which expands it.

## Gotchas

Things that cost time here before, worth not rediscovering:

- **Unknown keys are silently ignored.** There is no warning and no error -- the setting
  just does nothing. The previous config carried dead keys for months:
  `pluginMarketplaces` (the real key is `extraKnownMarketplaces`) and
  `skipAutoPermissionPrompt`. Validate after editing.
- **`modelSettings` and `model` are live keys that Claude Code writes itself.** `/effort`
  saves a per-model `effortLevel` under `modelSettings`, and `/model` saves `model`. An
  earlier version of this README listed `modelSettings` as dead; it is not, and stripping
  it discards a saved effort level. Because the stowed `settings.json` is a symlink into
  this repo, those keys show up as uncommitted edits in the working tree; whether to commit
  them is a separate decision.
- **Some env limits are no-ops or worse.** `MAX_THINKING_TOKENS` is ignored on adaptive
  reasoning models (Opus 4.7+, Fable 5) unless `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING` is
  set, so it was removed. `TASK_MAX_OUTPUT_LENGTH` defaults to 32000 characters; the old
  value of 20000 was silently *reducing* retained background-task output, so it was
  removed rather than raised.
- **Wildcard allow rules are dropped in auto mode.** `Bash(npm *)`, `Bash(python*)`,
  `Bash(*)` and similar are ignored on entering auto mode and restored on leaving it, so an
  allow rule that looks harmless under `auto` is fully live under `default`.
- **`includeCoAuthoredBy` is deprecated.** Use the `attribution` object instead; it can
  strip the commit trailer and the PR footer independently.
- **The env var for suppressing non-essential model calls is
  `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`.** Plausible-looking alternatives like
  `DISABLE_NON_ESSENTIAL_MODEL_CALLS` are not real and fail silently.
- **`stow` only reads `.stow-local-ignore` from inside a package**, never from the stow
  root, and a package-local list *replaces* the built-in defaults. This repo has none:
  the root `.stowrc` sets `--no-folding`, so runtime files written next to a config never
  land in the repo, and anything that must not be stowed lives outside the layers.

## Validating Changes

After editing `settings.json`, check it against the published schema:

```bash
curl -sL https://www.schemastore.org/claude-code-settings.json -o /tmp/cc-schema.json

jq empty base/claude/.config/claude/settings.json          # valid JSON?

jq -r 'keys[]' base/claude/.config/claude/settings.json |
  while read -r k; do
    jq -e --arg k "$k" '.properties[$k]' /tmp/cc-schema.json >/dev/null ||
      echo "INVALID KEY: $k"
  done

jq -r '.env | keys[]' base/claude/.config/claude/settings.json |
  while read -r k; do
    jq -e --arg k "$k" '.properties.env.properties[$k]' /tmp/cc-schema.json >/dev/null ||
      echo "UNDOCUMENTED ENV: $k"
  done
```

To preview what stow will link without touching the filesystem:

```bash
stow -n -v --target=/tmp/stowtest claude
```
