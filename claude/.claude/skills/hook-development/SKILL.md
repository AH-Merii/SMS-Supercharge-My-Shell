---
description: Claude Code hook development reference -- event types, I/O contracts, exit codes, JSON schemas, security patterns, and known pitfalls
autoActivateWhen: user discusses writing hooks, hook development, creating hooks, debugging hooks, auditing hooks, PreToolUse hooks, PostToolUse hooks, hook scripts, or hook-related configuration
---

# Hook Development Reference

## Architecture

- Hooks are shell commands, LLM prompts, or subagents that execute at lifecycle points
- **Hooks run OUTSIDE the sandbox** -- full filesystem and network access, no restrictions
- All matching hooks within an event run **in parallel** -- never assume ordering
- Identical handlers are deduplicated automatically
- Hook config is **snapshot at startup** -- mid-session edits require `/hooks` menu review
- Three hook types: `command` (shell), `prompt` (single-turn LLM), `agent` (multi-turn LLM with Read/Grep/Glob, up to 50 turns)

## 14 Event Types

| Event                  | When It Fires                   | Matcher Field                             | Can Block?                 | `additionalContext`? |
| ---------------------- | ------------------------------- | ----------------------------------------- | -------------------------- | -------------------- |
| **SessionStart**       | Session begins/resumes          | source: `startup\|resume\|clear\|compact` | No                         | Yes                  |
| **UserPromptSubmit**   | User sends prompt               | No matcher (always fires)                 | Yes                        | Yes                  |
| **PreToolUse**         | Before tool executes            | tool_name regex                           | Yes (`permissionDecision`) | Yes                  |
| **PermissionRequest**  | Permission dialog about to show | tool_name regex                           | Yes (`decision.behavior`)  | No                   |
| **PostToolUse**        | After tool succeeds             | tool_name regex                           | No (already ran)           | Yes                  |
| **PostToolUseFailure** | After tool fails                | tool_name regex                           | No                         | Yes                  |
| **Notification**       | Claude needs input              | notification_type                         | No                         | Yes                  |
| **SubagentStart**      | Subagent spawned                | agent_type                                | No                         | Yes (to subagent)    |
| **SubagentStop**       | Subagent finishes               | agent_type                                | Yes (`decision: "block"`)  | No                   |
| **Stop**               | Main agent finishes             | No matcher (always fires)                 | Yes (`decision: "block"`)  | No                   |
| **TeammateIdle**       | Teammate about to idle          | No matcher                                | Yes (exit 2 only)          | No                   |
| **TaskCompleted**      | Task marked completed           | No matcher                                | Yes (exit 2 only)          | No                   |
| **PreCompact**         | Before context compaction       | trigger: `manual\|auto`                   | No                         | No                   |
| **SessionEnd**         | Session terminates              | reason: `clear\|logout\|...`              | No                         | No                   |

Tool name matchers: `Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Task`, `WebFetch`, `WebSearch`, `mcp__<server>__<tool>`.

## Exit Code Contract

This is the single most important rule in hook development:

| Exit      | Meaning                           | stdout                       | stderr                 |
| --------- | --------------------------------- | ---------------------------- | ---------------------- |
| **0**     | Success                           | Parsed as JSON for decisions | Ignored                |
| **2**     | Blocking error                    | **IGNORED** (no JSON parsed) | Fed to Claude as error |
| **Other** | **FAIL-OPEN** (silently ignored!) | Ignored                      | Verbose mode only      |

**Critical**: Exit 1 does NOT block. A crashing hook does NOT block. Only exit 0 with JSON deny or exit 2 can block.

**You must pick one approach per hook**: exit codes alone, OR exit 0 + JSON. Never mix.

## JSON Output Schemas

### Common fields (all events, exit 0)

```json
{
  "continue": true, // false = halt Claude entirely (nuclear option)
  "stopReason": "...", // shown to user when continue=false
  "suppressOutput": false, // hide from verbose mode
  "systemMessage": "..." // warning shown to user
}
```

### PreToolUse (the richest -- can allow, deny, ask, modify input, inject context)

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "permissionDecisionReason": "shown to Claude on deny, shown to user on allow/ask",
    "updatedInput": { "command": "modified command" },
    "additionalContext": "injected into Claude's context"
  }
}
```

### PostToolUse / Stop / SubagentStop / UserPromptSubmit

```json
{
  "decision": "block",
  "reason": "shown to Claude (required when blocking)",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "injected into Claude's context"
  }
}
```

### PermissionRequest

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow|deny",
      "updatedInput": {},
      "updatedPermissions": [{ "type": "toolAlwaysAllow", "tool": "Bash" }],
      "message": "shown to Claude on deny",
      "interrupt": false
    }
  }
}
```

## Stdin Schemas (What Hooks Receive)

### Common fields (all events)

`session_id`, `transcript_path`, `cwd`, `permission_mode`, `hook_event_name`

### Key event-specific fields

| Event                  | Key Fields                                                       |
| ---------------------- | ---------------------------------------------------------------- |
| **PreToolUse**         | `tool_name`, `tool_input` (varies by tool), `tool_use_id`        |
| **PostToolUse**        | `tool_name`, `tool_input`, `tool_response`, `tool_use_id`        |
| **PostToolUseFailure** | `tool_name`, `tool_input`, `error`, `is_interrupt`               |
| **UserPromptSubmit**   | `prompt`                                                         |
| **Stop**               | `stop_hook_active` (boolean -- check to prevent infinite loops!) |
| **PermissionRequest**  | `tool_name`, `tool_input`, `permission_suggestions`              |
| **Notification**       | `message`, `title`, `notification_type`                          |
| **SubagentStart/Stop** | `agent_id`, `agent_type`                                         |
| **TeammateIdle**       | `teammate_name`, `team_name`                                     |
| **TaskCompleted**      | `task_id`, `task_subject`, `teammate_name`, `team_name`          |

### Tool input schemas (PreToolUse/PostToolUse)

| Tool      | `tool_input` fields                                         |
| --------- | ----------------------------------------------------------- |
| **Bash**  | `command`, `description?`, `timeout?`, `run_in_background?` |
| **Write** | `file_path`, `content`                                      |
| **Edit**  | `file_path`, `old_string`, `new_string`, `replace_all?`     |
| **Read**  | `file_path`, `offset?`, `limit?`                            |
| **Glob**  | `pattern`, `path?`                                          |
| **Grep**  | `pattern`, `path?`, `glob?`, `output_mode?`                 |

## Settings.json Registration

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.config/claude/hooks/my-hook.sh",
            "timeout": 10,
            "async": false,
            "statusMessage": "Running check..."
          }
        ]
      }
    ]
  }
}
```

- `timeout`: seconds (defaults: 600 command, 30 prompt, 60 agent; max ~612s)
- `async: true`: runs in background, cannot return decisions (good for notifications/logging)
- `once: true`: runs once per session then removed (skills only)
- Matchers are **regex**: `Bash`, `Edit|Write`, `mcp__memory__.*`
- Empty matcher `""` or `"*"` = match all

## Security Patterns

1. **Always use `jq`** to parse stdin JSON -- never grep/sed on JSON
2. **Always use `jq -n`** or `cat <<'EOF'` (single-quoted heredoc) to construct JSON output -- never string interpolation with untrusted data
3. **Always quote variables**: `"$VAR"` not `$VAR`
4. **Never `eval`** tool_input data -- it's AI-generated and may be influenced by prompt injection
5. **Never use relative paths** in hook commands -- use `$CLAUDE_PROJECT_DIR` or absolute paths (relative paths + `cd` = unrecoverable deadlock)
6. **Validate before using** in commands: `tool_input.command` and `tool_input.file_path` are untrusted
7. **Default-deny for security hooks**: explicitly `exit 0` for known-safe patterns, `exit 2` for everything else

## Critical Pitfalls

1. **Exit 1 = fail-open** -- the hook silently does nothing. Use exit 2 for blocking or JSON `permissionDecision: "deny"`
2. **PreToolUse exit 2 doesn't reliably block Write/Edit** -- use JSON `permissionDecision: "deny"` instead (GitHub #13744, #21988)
3. **Hooks die after ~2.5 hours** -- `~/.claude/hooks.log` can grow to ~48GB (GitHub #16047). Monitor and rotate
4. **Relative paths + `cd` = deadlock** -- hook can't find script, Claude can't run any tools (GitHub #5176)
5. **UserPromptSubmit stdout may error** -- use JSON `additionalContext` instead of plain text stdout (GitHub #13912)
6. **Matcher fires for wrong tools** -- PostToolUse `"Bash"` can fire for Read/Glob (GitHub #20334). Always validate `tool_name` inside the script
7. **Settings cached at startup** -- edits during session have no effect without restart or `/hooks` review
8. **Stop hook infinite loops** -- always check `stop_hook_active` before blocking in Stop hooks
9. **100% CPU with parallel instances** -- running 2+ Claude sessions with hooks on v2.1.23+ (GitHub #22172)
10. **Context window pollution** -- every hook injection eats tokens. Keep output minimal. Community consensus: format on commit, not on every edit
11. **Shell profile noise** -- if your shell profile prints text on startup, it corrupts JSON parsing. Hook stdout must be ONLY JSON

## Environment Variables

| Variable                | Scope             | Description                                               |
| ----------------------- | ----------------- | --------------------------------------------------------- |
| `$CLAUDE_PROJECT_DIR`   | All hooks         | Project root -- **always use for paths**                  |
| `${CLAUDE_PLUGIN_ROOT}` | Plugin hooks      | Plugin's root directory                                   |
| `$CLAUDE_ENV_FILE`      | SessionStart only | Write `export` statements to persist env vars for session |
| `$CLAUDE_CODE_REMOTE`   | All hooks         | `"true"` in remote web environments                       |

## Local Conventions

- Hook scripts: `~/SMS-Supercharge-My-Shell/claude/.config/claude/hooks/`
- Registration: `~/SMS-Supercharge-My-Shell/claude/.config/claude/settings.json` → `hooks` object
- After changes: `cd ~/SMS-Supercharge-My-Shell && stow claude`
- Pattern: `INPUT=$(cat)` → `jq -r '.field // empty'` → early exit on empty → core logic → JSON output via heredoc
- Two-tier enforcement: Deny (blocks via `permissionDecision: "deny"`) + Nudge (injects `additionalContext` suggesting better approach)
- Always `exit 0` on non-applicable cases and the happy path
