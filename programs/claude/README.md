# Claude Code Configuration

Global settings, linked live into `~` by home-manager from `programs/claude/` in the
checkout. An edit here is seen by the next Claude Code session with no apply step: the
activation links the file, and the file is this one. Claude Code rewrites `settings.json`
itself as preferences change in a session, which is why it is live and not applied.

## Directory Structure

```
claude/
└── .config/claude/
    ├── settings.json    # the whole config -- one file
    └── skills/
        └── tuicr/       # vendored from agavra/tuicr (see Skills)
```

`CLAUDE_CONFIG_DIR` is set to `$XDG_CONFIG_HOME/claude` by
`programs/fish/.config/fish/conf.d/01-env.fish`, so `~/.config/claude/` is the
active config root.

There is deliberately **no `.claude/` half** to this package. Files placed at `~/.claude/`
would sit outside `CLAUDE_CONFIG_DIR` and never be read. This package previously carried a
`.claude/` tree (CLAUDE.md, agents, commands, skills) that was inert for exactly this reason.

## What's Configured

| Group | Settings |
|-------|----------|
| Privacy | `DISABLE_TELEMETRY`, `DISABLE_ERROR_REPORTING`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, `feedbackSurveyRate: 0` |
| Context | `cleanupPeriodDays: 365` — a year of transcript history vs. the 30-day default |
| Updates | `autoUpdatesChannel: stable` — ~1 week behind `latest`, skips major regressions |
| Token limits | `CLAUDE_CODE_MAX_OUTPUT_TOKENS`, `MAX_THINKING_TOKENS`, `MAX_MCP_OUTPUT_TOKENS`, `TASK_MAX_OUTPUT_LENGTH` |
| Permissions | `defaultMode: auto`, a git/npm/node allow list, `.env` deny rules |
| Git | `attribution: { commit: "", pr: "" }` — no assistant byline in commits or PRs |
| Ergonomics | `editorMode: vim`, `theme: dark`, `tui: fullscreen`, `agentPushNotifEnabled` |
| Spinner | `spinnerVerbs` — 45 custom verbs, `replace` mode |
| Status line | `ccstatusline` (see below) |
| Plugins | `terminal-icons` via the local marketplace (see below) |

### Permissions

`defaultMode: auto` auto-approves tool calls with background safety checks that verify
actions align with the request. The `allow` list additionally pre-approves read-only git,
npm/pnpm/node, and common shell inspection commands. `deny` covers `.env` files across
Read, Edit and the usual shell readers.

Deny rules are **not a hard security boundary** — they reduce accidents, not determined
access. This config intentionally runs lean: there is no `sandbox` block and no denials on
credential paths (`~/.ssh`, `~/.aws`, `*.pem`, `op` commands). If you want those back,
adding them to `permissions.deny` is self-contained and touches nothing else.

### Status Line

`statusLine` runs `ccstatusline`, the one program nixpkgs does not carry and the repo
packages itself — see `../ccstatusline/README.md`, which also owns its widget layout. The
command is the bare name: the Nix profile is on the `PATH` of anything the session starts,
including a desktop launcher, so there is no path to write down.

### Plugins

The `terminal-icons` plugin lives at the repo root in `plugins/`, **not** inside this
package. `~/.config/claude/plugins/` is a directory Claude Code owns and writes to itself
(`known_marketplaces.json`, `marketplaces/`), so linking into it invites conflicts.

Instead, `extraKnownMarketplaces` points at the repo path directly:

```json
"extraKnownMarketplaces": {
  "local-plugins": {
    "source": { "source": "directory", "path": "${SMS_CHECKOUT}/plugins" }
  }
}
```

`plugins/` sits at the repo root rather than inside a program, so it is never linked into
`~/`; the plugin works straight from the checkout. `SMS_CHECKOUT` is the session variable
the configuration exports, so the path follows the checkout instead of naming it.

### Skills

`skills/tuicr/` comes from [`agavra/tuicr`](https://github.com/agavra/tuicr), taken from
`skills/tuicr/` at commit `4a9bda23`. It teaches the agent to drive the review TUI: find
or open a session, read the comments back, and add its own.

It is a **trimmed** copy, not a clean vendor. Upstream also ships tmux, Zellij and cmux
wrappers and branches on `$TMUX`, `$ZELLIJ` and `$CMUX_WORKSPACE_ID`; all of that is cut,
leaving `$HERDR_ENV` as the only pane launcher. So a refresh is a re-trim, not an
overwrite: pull the upstream files, then remove the non-Herdr wrappers and every branch
that mentions them (the Start A Session table, the wrapper path list, the timeout note,
the tips section, and two rows of the error table).

```bash
D=programs/claude/.config/claude/skills/tuicr
for f in SKILL.md _tuicr-common.sh tuicr-wrapper-herdr.sh; do
  curl -sfL "https://raw.githubusercontent.com/agavra/tuicr/main/skills/tuicr/$f" -o "$D/$f"
done
```

One deviation is deliberately *not* made here. The skill's "Core Rule" says not to add
agent comments during a user-led review; our standing order is the opposite, comments land
locally by default and the user submits them. That lives in the review-comment memory
instead, which loads every session and wins, so the rule stays where it can be changed
once rather than re-applied on every refresh.

## Gotchas

Things that cost time here before, worth not rediscovering:

- **Unknown keys are silently ignored.** There is no warning and no error — the setting
  just does nothing. The previous config carried three dead keys for months:
  `pluginMarketplaces` (the real key is `extraKnownMarketplaces`),
  `skipAutoPermissionPrompt`, and a `modelSettings` block. Validate after editing.
- **`includeCoAuthoredBy` is deprecated.** Use the `attribution` object instead; it can
  strip the commit trailer and the PR footer independently.
- **The env var for suppressing non-essential model calls is
  `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`.** Plausible-looking alternatives like
  `DISABLE_NON_ESSENTIAL_MODEL_CALLS` are not real and fail silently.
- **Every directory under `~` stays a real directory.** The linker emits one entry per
  file, never per directory, so the runtime files Claude Code writes beside a managed one
  are left alone and never land in the repo.

## Validating Changes

After editing `settings.json`, check it against the published schema:

```bash
curl -sL https://www.schemastore.org/claude-code-settings.json -o /tmp/cc-schema.json

jq empty programs/claude/.config/claude/settings.json          # valid JSON?

jq -r 'keys[]' programs/claude/.config/claude/settings.json |
  while read -r k; do
    jq -e --arg k "$k" '.properties[$k]' /tmp/cc-schema.json >/dev/null ||
      echo "INVALID KEY: $k"
  done

jq -r '.env | keys[]' programs/claude/.config/claude/settings.json |
  while read -r k; do
    jq -e --arg k "$k" '.properties.env.properties[$k]' /tmp/cc-schema.json >/dev/null ||
      echo "UNDOCUMENTED ENV: $k"
  done
```

To see what an activation would link without touching `~`:

```bash
nix build --impure .#homeConfigurations.shell-linux.activationPackage
```
