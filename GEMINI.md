# GEMINI.md — Google Antigravity / Gemini

> Antigravity reads both `AGENTS.md` and `GEMINI.md`; on conflict, `GEMINI.md` wins.
> **Project source of truth — `AGENTS.md`; read it first.** Here — Antigravity/Gemini specifics.

## Agent mode
- Work from a plan (task/plan): break the task down and show steps before executing.
- Human-in-the-loop: for production-data/core edits — stop and ask for confirmation.
- Produce artifacts (diff, file list, rollback plan) before applying; save them in `.antigravity/artifacts/`.
- Do not run shell commands against a production server/DB.
- Keep changes atomic, with an explanation of WHAT and WHY.
