# .ai/ — AI tooling layout

**Source of truth — [`../AGENTS.md`](../AGENTS.md)** (read natively by Codex, Cursor,
Antigravity/Gemini, and others). Everything else is a thin redirect or tool-specific detail.

| Tool | File | Artifacts |
|---|---|---|
| All agents | `AGENTS.md` | `.ai/artifacts/` |
| Codex (CLI / IDE / app) | `AGENTS.md` (native); optional `.codex/config.toml` | `.ai/artifacts/` |
| Cursor | `.cursorrules` → AGENTS.md; `.cursor/rules/*.mdc`; `.cursorignore` | `.cursor/artifacts/` |
| Claude (Code / Cowork) | `CLAUDE.md` → AGENTS.md; `.claude/` | `.claude/artifacts/` |
| Antigravity / Gemini | `GEMINI.md` (+ AGENTS.md) | `.antigravity/artifacts/` |
| Perplexity | `PERPLEXITY.md` (paste-in brief) | `.perplexity/artifacts/` |

## Rule
Project changes → edit **`AGENTS.md`**. Tool-specific detail → that tool's file.
Codex needs no redirect file; add `.codex/config.toml` only for concrete repository-specific
settings. An artifact is a durable session result (plan, research, diff, task list).

<!-- Initialized by init-ai-tooling 1.1.0 (2026-07-30). -->
