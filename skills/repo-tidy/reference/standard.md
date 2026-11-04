# Repository layout tradition

Russian: [standard.ru.md](standard.ru.md).

Documentation and AI-layout rules for any project. `ai-tooling-starter-kit` generates a layout
that follows this tradition; `scripts/check_layout.py` checks a repository against it.

## Principles

1. **One source of truth — `AGENTS.md`.** Other tool files import it or are thin redirects:
   the project changes → edit `AGENTS.md`; tool specifics → that tool's file.
2. **One documentation root — `docs/`**, mapped by `docs/README.md`.
3. **Honest status.** "Ready", "Done", test counts and the "next priority" are checked against
   the code and a real run. A stale document is worse than a missing one.
4. **An artifact is a dated snapshot.** It is not rewritten later; the current state lives in
   `AGENTS.md` §4.
5. **Links resolve.** Relative links work; an ADR number always carries the repository prefix.
6. **Secrets are closed twice:** against commits (`.gitignore`) and against agent reads
   (`.claude/settings.json`).
7. **Service files use the project's language.** A public
   project may keep them in English with `*.ru.md` translations; the pairs say the same thing,
   and `AGENTS.md` section headings are English with the same numbering (`## 1. Project` …).

## Layout

```text
AGENTS.md                  source of truth (sections below)
CLAUDE.md GEMINI.md        @AGENTS.md import (or a thin redirect) + tool specifics
.cursorignore              (.cursorrules only if the project keeps it; Cursor reads AGENTS.md itself)
PERPLEXITY.md              as needed: paste-in brief Role / Purpose / Boundaries / Output format
README.md                  human entry point: what it is, quick start, structure
CHANGELOG.md               "## Unreleased" section
LICENSE SECURITY.md        copyright holder — the project's real owner
.gitignore .gitattributes .editorconfig
.ai/README.md              tool map; below the marker — repository specifics and artifact index
.ai/artifacts/             artifacts from every tool  YYYY-MM-DD-topic.md
.claude/settings.json      allow ["Read","Edit"] + baseline deny list
.claude/{agents,commands}/
.cursor/rules/000-project.mdc 010-safety.mdc
.<tool>/artifacts/         optional: only if the project splits artifacts per tool
.agents/skills/            portable agent skills
docs/README.md             documentation map
docs/adr/README.md         ADR registry with a prefix table
docs/adr/PREFIX-NNNN-topic.md
docs/runbooks/             procedures
docs/<other>/              architecture/, prd/, test-plans/, reviews/, releases/ … as needed
```

An empty directory is kept with a `.gitkeep` file.

## `AGENTS.md`

The first line is `# AGENTS.md — <repository>`. Required sections, in order:

1. `## 1. Project` — what and why, who the users are, key requirements.
2. `## 2. Stack`
3. `## 3. Structure` — a "directory → purpose" table; every top-level directory is in it.
4. `## 4. Status / current priority` — what is done, the test count (from a run), **what
   blocks** the next step, and the next step itself.
5. `## 5. How to make changes (agent)`
6. `## 6. Security (NEVER)`
7. `## 7. Definition of Done`
8. `## Tool layout` — starts with the line
   ``Artifacts — in `.ai/artifacts/` (shared) and `.<tool>/artifacts/`. Details — `.ai/README.md`.``
   (without per-tool folders: ``Artifacts — in `.ai/artifacts/`. Details — `.ai/README.md`.``).

In Russian-language repositories the headings are `## 1. Проект` … `## Раскладка инструментов`;
the checker accepts both. Extra sections may sit between the required ones; a clarification
after a heading is fine too.

## Redirects

`CLAUDE.md`: an `@AGENTS.md` import line (Claude Code loads the file itself; `GEMINI.md` uses
`@./AGENTS.md` for Gemini CLI) or a prose redirect "The source of truth is `AGENTS.md`. Read it
first." The import is more reliable: a redirect depends on the model choosing to open the file.
After that, only Claude specifics (`.claude/` directories, settings). Do not duplicate project
rules. More than ~40 lines is a sign that shared rules leaked out of `AGENTS.md`.

## `.ai/README.md`

The shared part is a "tool → file → artifacts" table and the rule "the project changes → edit
`AGENTS.md`". Repository specifics go below a marker line (`<!-- Ниже — специфика репозитория. -->`
in Russian, `<!-- Below: repository-specific notes … -->` in English): the artifact index and
executable conventions (`/commands`, subagents).

## Artifacts

- Name `YYYY-MM-DD-topic.md` (a folder with attachments — `YYYY-MM-DD-topic/`).
- Where: by default everything goes in `.ai/artifacts/`. Separate `.<tool>/artifacts/` only if
  the project splits them; then a single tool's result goes there.
- What: plan, research, audit, council, pilot protocol — anything that outlives the session.
- A snapshot is not edited for content. Mechanical link repair when files move is allowed.
- A "current status" pointer leads to `AGENTS.md` §4, not to a dated artifact.

## ADR

- Directory `docs/adr/`, name `PREFIX-NNNN-topic.md` (the prefix is the repository's short
  name in capitals: `API-`, `WEB-`; the topic in Latin letters with hyphens).
- Reference in text, code and comments: `ADR API-0001`. A bare `ADR-001` is forbidden: a number
  without a prefix becomes unresolvable as soon as a neighbour has its own "ADR-001".
- Registry `docs/adr/README.md`: a prefix table (its own row marked "(this)"), rules, and an
  "ADR | Status | Topic" table.
- Numbering is historical; a cancelled one gets `Superseded by PREFIX-NNNN` and is not deleted.
- Header: `Status | Date | Context | Related`; sections: Context → Options → Decision →
  Consequences.

## Documents

- Header — a `Status | Date | Related` table. Status reflects reality: `Draft`, `Blocked`
  (with the reason), `Ready`, `Accepted`, `Superseded`.
- Runbook: when to apply, prerequisites and access, numbered idempotent steps, abort criteria,
  rollback, escalation.
- Requirements (SRS/PRD) — a separate document, only if they are actually written. Do not create
  an empty "SRS" index for the checkbox: the map in `docs/README.md` is more honest.
- Reviews and audits — dated artifacts (or `docs/reviews/YYYY-MM-DD-topic.md` if they are part
  of the product documentation).

## `.claude/settings.json`

```json
{
  "permissions": {
    "allow": ["Read", "Edit"],
    "deny": ["Read(.env)", "Read(.env.*)", "Read(**/*.pem)", "Read(**/*.key)",
             "Read(**/.ssh/**)", "Read(**/.aws/**)", "Read(**/.kube/**)",
             "Bash(rm -rf:*)", "Bash(git push --force:*)"]
  }
}
```

Plus the repository's own secrets (`Read(config.yaml)`, `Read(deploy/x/compose.env)` …).
A bare name applies at any depth; an extension at any depth — `**/*.pem`. Deny rules live in the
committed file, not in `settings.local.json`: otherwise a fresh clone does not have them.

## `.gitignore`

Minimum: `.env`, `.env.*` + `!.env.example`, `.DS_Store`, `.claude/settings.local.json`,
`.claude/worktrees/`, `_to_delete/`, language caches. If a `config.example` / `*.example` sits
next to it, the working file is ignored too.

## Git hygiene

- Moves — only `git mv` (history and `git log --follow` survive).
- No junk under git: `.DS_Store`, `__pycache__`, `*.egg-info`, `.pytest_cache`, `node_modules`, `.env`.
- `.gitattributes` pins LF (`* text=auto eol=lf`, binaries — `binary`); after changing it —
  `git add --renormalize .`.
- Commits — Conventional Commits (`docs:`, `chore:`, `fix:` …), one logical change per commit.
