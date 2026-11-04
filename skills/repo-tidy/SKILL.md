---
name: repo-tidy
description: "Brings any repository in line with the layout tradition that ai-tooling-starter-kit generates: AGENTS.md as the single source of truth, @AGENTS.md imports or thin redirects for Claude/Gemini, one docs/ root with a map, an ADR registry with a repository prefix, runbooks in docs/runbooks, dated artifacts, honest statuses, secrets closed off, git hygiene. Ships a layout checker and a link fixer. Use when the user asks to tidy a repo, bring docs and artifacts in order, «приведи в порядок», «наведи порядок в документации», «по нашей традиции», onboard a repo to the standard, after a big restructure, or when docs drift from code."
---

# repo-tidy — bring a repository in order

Goal: a person or any AI agent opens the repository and understands within a minute what it
is, where the truth lives, what is done and what comes next. The tradition's rules are in
[`reference/standard.md`](reference/standard.md) (Russian: [`reference/standard.ru.md`](reference/standard.ru.md));
read it before you start.

This skill lives in `ai-tooling-starter-kit` (`skills/repo-tidy/`); the kit generates a
layout that already follows the tradition. Write in the repository's own language: Russian
repositories get Russian service files, English ones English with `*.ru.md` pairs.

Tools (paths relative to the skill directory):

| Script | What it does |
|---|---|
| `scripts/check_layout.py <repo>` | Checks against the tradition: ✗ errors, ! warnings; exit 1 on errors |
| `scripts/md_links.py <repo> [--fix]` | Broken and "detour" relative links in Markdown; `--fix` repairs by unique basename / path tail |

Both need Python 3.9+ and only inspect git-tracked files.

## Workflow

### 1. Reconnaissance (read only)

1. Read `AGENTS.md`, `README.md`, `.ai/README.md`, `git log --oneline -20`, `git status`.
2. Run `check_layout.py` and `md_links.py` — that is the starting list of gaps.
3. Find a reference: a fresh scaffold of `ai-tooling-starter-kit` in a temporary directory, or a
   sibling repository the user names that already follows the tradition. Compare redirect files
   (`cmp`) with it.
4. **Check statuses against reality** — what the checker cannot see:
   - the test count in `AGENTS.md` §4 — run the tests and take the number from the output;
   - "Ready / Done / Accepted" statuses in document and runbook headers — confirmed by code?
   - the "next priority" — still current? what blocks it?
   - "current status" pointers do not lead to a dated artifact.

### 2. Decisions (ask only what cannot be inferred)

- **ADR prefix** — the repository's short name in capitals (`API-`, `WEB-`). Ask if unclear.
- **Copyright holder** in `LICENSE` and copyright lines — the project's real owner. Never copy a
  holder from another repository.
- **What to move:** a second documentation root (`specs/`, `documentation/`) → `docs/`; ADRs from
  anywhere → `docs/adr/`; runbooks → `docs/runbooks/`. Show the user the move plan before `git mv`
  if it touches more than a couple of directories.

### 3. Moves

1. `git mv` only — history survives.
2. Rewrite path mentions in all tracked text files (code, scripts, `.github/` templates, skills
   in `.agents/skills/` — project lines only). Bare `ADR-001` → `ADR API-0001`.
3. `md_links.py <repo> --fix`, then without `--fix` — it must report 0. Fix what remains
   (missing / ambiguous) by hand.

### 4. Indexes and honesty

- `docs/README.md` — the map: section → what is inside → when to open it; conventions.
- `docs/adr/README.md` — prefix table, rules, "ADR | Status | Topic" registry.
- `AGENTS.md` §3 — every top-level directory; §4 — done / tests / **what blocks** / next step.
- `.ai/README.md` — below the marker line, the artifact index.
- Document headers: status = reality (`Blocked` with a reason beats a false `Ready`).
- A reconnaissance result or advice that outlives the session — a dated artifact.
- Do not invent content: no empty SRS, no requirements nobody wrote.

### 5. AI layer and hygiene

- `.claude/settings.json`: the baseline deny list + the repository's secrets (`config.yaml`, `compose.env` …).
- `.gitignore`: the baseline list; `.gitattributes` / `.editorconfig` — from the reference; after
  changing `.gitattributes` — `git add --renormalize .`.
- Junk under git (`.DS_Store`, `*.egg-info`, caches) — `git rm --cached`, add to `.gitignore`.
- Empty required directories — `.gitkeep`.

### 6. Verify and commit

1. `check_layout.py` — 0 errors; list the remaining warnings to the user with the reason.
2. `md_links.py` — 0. The project's tests are green (moves may have touched paths in code).
3. `CHANGELOG.md` → `## Unreleased` → an entry about the reorganization.
4. A `docs: …` commit (Conventional Commits) on the current branch unless the user asked
   otherwise; do not push unless asked.

## Do not

- Rewrite the content of dated artifacts (except mechanical link repair).
- Delete documents or change the meaning of operational texts without explicit consent.
- Touch vendored skills or third-party code beyond lines that reference this project.
- Carry one project's specifics (copyright holder, ADR prefix registry, private tooling) into another.
- Mix a documentation reorganization with code changes in one commit.
