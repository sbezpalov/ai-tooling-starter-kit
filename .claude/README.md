# .claude/ — Claude Code configuration

Source of truth — [`../AGENTS.md`](../AGENTS.md).

- `commands/` — slash commands; `agents/` — subagents. Artifacts go in `../.ai/artifacts/`.
- `settings.json` — team settings; `settings.local.json` — personal (do not commit).

## What `settings.json` does NOT protect
The `deny` list is a best-effort guardrail, not a security boundary:
- `Bash(...)` rules match command prefixes: `rm -r -f`, `find . -delete`, or a script
  that deletes files are not caught.
- Without the sandbox, `Read(...)` rules cover Claude's file tools, not `cat .env` run through Bash.

For real isolation use Claude Code's sandbox, a container/devcontainer, or a `PreToolUse` hook.
