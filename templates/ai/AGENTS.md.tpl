# AGENTS.md — __NAME__

> Shared instructions for AI coding agents and humans. Codex, Cursor, Google Antigravity/Gemini,
> and other AGENTS-compatible tools read this file natively; Claude Code imports it from `CLAUDE.md`.
> Keep it short: write down only what an agent cannot infer from the code.

## Project
__DESC__

<!-- TODO: 1–3 sentences — what it is, who uses it, what matters most. -->

## Commands
<!-- TODO: exact commands an agent should run, e.g. install, test, lint, build. -->

## Conventions
<!-- TODO: only non-obvious rules — module boundaries, generated code not to edit, naming. -->

## Never
- Commit or print secrets (`.env`, keys, tokens); only `*.example` files belong in the repo.
- Run destructive operations on production data without explicit confirmation.
- <!-- TODO: project-specific bans (e.g. do not touch `vendor/`). -->

## Done means
Tests and lint pass for the change. <!-- TODO: add project-specific checks. -->

## Artifacts
Plans, research, and other durable session results from every tool go in `.ai/artifacts/`.
Codex reads this file natively and uses the shared artifacts directory.

<!-- Initialized by init-ai-tooling __VERSION__ (__DATE__). -->
