# AGENTS.md — __NAME__

> Shared instructions for AI coding agents and humans. Codex, Cursor, Google Antigravity/Gemini,
> and other AGENTS-compatible tools read this file natively; Claude Code imports it from `CLAUDE.md`.
> Keep it short: write down only what an agent cannot infer from the code.

## 1. Project
__DESC__

<!-- TODO: 1–3 sentences — what it is, who uses it, what matters most. -->

## 2. Stack
<!-- TODO: languages, frameworks, runtime versions, where it runs. -->

## 3. Structure
<!-- TODO: one row per top-level directory: | Path | Purpose |. -->

## 4. Status / current priority
<!-- TODO: what is done, test count (from a real run), what blocks the next step, the next step. -->

## 5. How to make changes (agent)
<!-- TODO: exact commands (install, test, lint, build) and non-obvious rules — module boundaries, generated code not to edit, naming. -->

## 6. Security (NEVER)
- Commit or print secrets (`.env`, keys, tokens); only `*.example` files belong in the repo.
- Run destructive operations on production data without explicit confirmation.
- <!-- TODO: project-specific bans (e.g. do not touch `vendor/`). -->

## 7. Definition of Done
Tests and lint pass for the change. <!-- TODO: add project-specific checks. -->

## Tool layout
Artifacts — in `.ai/artifacts/` (shared by every tool). Details — `.ai/README.md`.
Plans, research, and other durable session results go there, named `YYYY-MM-DD-topic.md`.
Codex reads this file natively and uses the shared artifacts directory.

<!-- Initialized by init-ai-tooling __VERSION__ (__DATE__). -->
