# AGENTS.md — ai-tooling-starter-kit

> **Single source of truth for all AI tools and humans in this repository.**
> Cursor, Google Antigravity/Gemini, and other AGENTS-compatible tools read this file
> natively. Thin redirects (`.cursorrules`, `CLAUDE.md`, `GEMINI.md`, `PERPLEXITY.md`)
> add detail but do not override these rules. **Read this file fully before working.**

## 1. Project
Starter kit that scaffolds a consistent AI-tooling layout (Claude, Cursor,
Antigravity/Gemini, Perplexity) from three equivalent scripts (Bash / Python / PowerShell).

<!-- TODO: 2–4 sentences — purpose, users, value. -->

## 2. Stack
<!-- TODO: languages, frameworks, DB, infrastructure. -->
- Bash, Python 3.6+ (stdlib), PowerShell 5.1 / 7+
- GitHub Actions CI

## 3. Structure
<!-- TODO: table of "directory → purpose". -->
| Path | Purpose |
|------|---------|
| `init-ai-tooling.sh` / `init_ai_tooling.py` / `init-ai-tooling.ps1` | Equivalent scaffolders |
| `tests/compare-trees.py` | Byte-for-byte tree equivalence |
| `README.md` / `README.ru.md` | Docs (EN default, RU alternate) |

## 4. Status / current priority
<!-- TODO: where the project is now and what to focus on. -->
Release **1.0.0**. English is the default language for scaffolds and primary docs.

## 5. How to change things (agent)
- Work from a plan: break the task down and show steps BEFORE executing.
- Human-in-the-loop: for irreversible operations and production-data edits — stop and ask.
- Produce artifacts (diff, list of changed files, rollback plan) before applying.
- Keep changes atomic; explain WHAT and WHY.
- New code ships with tests; the task is not "done" if tests/lint are failing.
- Behaviour changes must land in **all three** init scripts at once.

## 6. Security (NEVER)
- Do not edit production directly <!-- TODO: delivery path, e.g. local → staging → prod via git -->.
- Secrets (passwords, keys, tokens, `.env`, local configs) — never commit or print them;
  the repo may only contain `*.example` files.
- Destructive operations on production data/DB — only with explicit confirmation and a dry run on a copy.
- <!-- TODO: project-specific bans (do not touch core/…). -->

## 7. Definition of Done
- [ ] Change is local; secrets did not land in code/commit.
- [ ] Tests/lint are green; verified on staging if needed.
- [ ] Diff is reviewed; a rollback plan exists.

## Tool layout
Artifacts live in `.ai/artifacts/` (cross-tool) and `.<tool>/artifacts/`. Details — `.ai/README.md`.

<!-- Initialized by init-ai-tooling 1.0.0 (2026-07-28). -->
