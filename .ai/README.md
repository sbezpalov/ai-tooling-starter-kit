# .ai/ — AI tooling layout

**Source of truth — [`../AGENTS.md`](../AGENTS.md)** (read natively by Codex, Cursor,
Antigravity/Gemini, and others). Other files only add tool-specific detail.

| Tool | File | Artifacts |
|---|---|---|
| All agents | `AGENTS.md` | `.ai/artifacts/` |
| Codex (CLI / IDE / app) | `AGENTS.md` (native); optional `.codex/config.toml` | `.ai/artifacts/` |
| Cursor | `AGENTS.md` (native); `.cursor/rules/*.mdc`; `.cursorignore` | `.ai/artifacts/` |
| Claude (Code / Cowork) | `CLAUDE.md` (`@AGENTS.md` import); `.claude/` | `.ai/artifacts/` |
| Gemini CLI / Antigravity | `GEMINI.md` (`@AGENTS.md` import); Antigravity reads `AGENTS.md` | `.ai/artifacts/` |

## Rule
Project changes → edit **`AGENTS.md`**. Tool-specific detail → that tool's file.
Codex needs no redirect file; add `.codex/config.toml` only for concrete repository-specific
settings. An artifact is a durable session result (plan, research, diff, task list).
`manifest.json` lists the files this kit generated; `--prune-legacy` reports leftovers
from older kit versions.

<!-- Initialized by init-ai-tooling 2.0.0 (2026-09-24). -->

<!-- Below: repository-specific notes (artifact index, commands, subagents). -->

## Artifacts in this repository

| Artifact | What |
|---|---|
| [`2026-07-30-codex-support-plan.md`](artifacts/2026-07-30-codex-support-plan.md) | Pre-change plan for Codex support (shipped in 1.1.0) |
| [`2026-11-04-generator-vs-repo-tidy-tradition.md`](artifacts/2026-11-04-generator-vs-repo-tidy-tradition.md) | Where the generated layout differed from the repo-tidy tradition and what was adopted |

This repository is itself scaffolded by the kit (dogfood): `.claude/` and `.cursor/` hold
no repository-specific commands, agents or rules yet.
