# CLAUDE.md — __NAME__

Project rules live in `AGENTS.md`; the import below loads it into every Claude Code session.

@AGENTS.md

## Claude-specific
- `.claude/commands/` — slash commands; `.claude/agents/` — subagents; `.claude/artifacts/` — artifacts.
- Team settings — `.claude/settings.json`; personal — `.claude/settings.local.json` (do not commit).
- `settings.json` deny rules are guardrails, not a sandbox — see `.claude/README.md`.
