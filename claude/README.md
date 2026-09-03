# Claude Code Configuration

Global settings, managed via [GNU Stow](https://www.gnu.org/software/stow/) from
`~/SMS-Supercharge-My-Shell/claude/`.

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

`CLAUDE_CONFIG_DIR` is set to `$XDG_CONFIG_HOME/claude` by both
`fish/.config/fish/conf.d/00-env.fish` and `zsh/.zshenv`, so `~/.config/claude/` is the
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

`statusLine` runs `ccstatusline`, a pinned global npm package (`ccstatusline@2.2.28`,
declared in `install/common.sh` as `NPM_GLOBAL_PACKAGES`). Its widget layout lives in a
separate stow package — see `../ccstatusline/README.md`.

Both the package and the binary are required for the status line to render:

```bash
bun install -g ccstatusline@2.2.28
cd ~/SMS-Supercharge-My-Shell && stow claude ccstatusline
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

`plugins/` carries a `.stow-local-ignore` containing `.*` (the same trick `install/` uses),
so `stow */` never tries to link it into `~/`. The plugin works straight from the repo with
no stow step.

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
- **`stow` only reads `.stow-local-ignore` from inside a package**, never from the stow
  root. The repo-root `.stow-local-ignore` does not apply to `claude/`, `ccstatusline/`,
  or any other package — those fall back to stow's built-in default list. To exclude a
  top-level directory from `stow */`, give it its own `.stow-local-ignore` containing `.*`.

## Validating Changes

After editing `settings.json`, check it against the published schema:

```bash
curl -sL https://www.schemastore.org/claude-code-settings.json -o /tmp/cc-schema.json

jq empty claude/.config/claude/settings.json          # valid JSON?

jq -r 'keys[]' claude/.config/claude/settings.json |
  while read -r k; do
    jq -e --arg k "$k" '.properties[$k]' /tmp/cc-schema.json >/dev/null ||
      echo "INVALID KEY: $k"
  done

jq -r '.env | keys[]' claude/.config/claude/settings.json |
  while read -r k; do
    jq -e --arg k "$k" '.properties.env.properties[$k]' /tmp/cc-schema.json >/dev/null ||
      echo "UNDOCUMENTED ENV: $k"
  done
```

To preview what stow will link without touching the filesystem:

```bash
stow -n -v --no-folding --target=/tmp/stowtest claude
```
