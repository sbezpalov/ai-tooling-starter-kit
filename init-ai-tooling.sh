#!/usr/bin/env bash
# init-ai-tooling.sh (1.1.0, AGENTS.md model) — deploys an AI tooling scaffold
# (Claude, Codex, Cursor, Antigravity/Gemini, Perplexity) in the current repository.
#
# Model: AGENTS.md = single source of truth (read natively by Codex, Cursor,
# Antigravity/Gemini, and others). Everything else — thin redirect/specific files
# at the root (.cursorrules, CLAUDE.md, GEMINI.md, PERPLEXITY.md). `.ai/` — artifacts only.
#
# Idempotent (without --force does not touch existing files). Self-contained (templates inside).
set -euo pipefail

VERSION="1.1.0"
NAME=""; DESC=""; FORCE=0; DRYRUN=0; NO_GITIGNORE=0

usage() {
  cat <<USAGE
init-ai-tooling.sh (${VERSION}) — AI tooling scaffold (AGENTS.md model).

Usage:
  init-ai-tooling.sh [--name NAME] [--desc "DESC"] [--force] [--dry-run] [--no-gitignore]

Options:
  --name NAME       Project name (defaults to the folder name).
  --desc TEXT       Short one-line description.
  --force           Overwrite existing files.
  --dry-run         Print the plan, write nothing.
  --no-gitignore    Leave .gitignore alone.
  --version         Print version and exit.
  -h, --help        Show this help.

Creates:
  AGENTS.md                ★ source of truth (native Codex + all agent rules)
  .cursorrules             redirect → AGENTS.md (legacy Cursor)
  .cursor/rules/*.mdc      detailed rules (000-project, 010-safety) + .cursorignore
  CLAUDE.md                redirect → AGENTS.md (Claude Code / Cowork)
  GEMINI.md                Antigravity/Gemini specifics (wins on conflict)
  PERPLEXITY.md            paste-in brief for Perplexity / research agents
  .ai/                     layout map + shared/Codex artifacts
  .claude/ .cursor/ .antigravity/ .perplexity/  — tool-specific artifacts
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --name) NAME="${2:-}"; shift 2 ;;
    --desc) DESC="${2:-}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRYRUN=1; shift ;;
    --no-gitignore) NO_GITIGNORE=1; shift ;;
    --version) printf '%s\n' "init-ai-tooling.sh ${VERSION}"; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

[ -n "$NAME" ] || NAME="$(basename "$(pwd)")"
[ -n "$DESC" ] || DESC="TODO: short project description"
DATE="$(date +%Y-%m-%d)"

say() { printf '%s\n' "$*"; }
ensure_dir() { [ "$DRYRUN" = "1" ] && { say "mkdir  $1"; return 0; }; mkdir -p "$1"; }
gitkeep() {
  ensure_dir "$1"; local f="$1/.gitkeep"
  [ -e "$f" ] && [ "$FORCE" != "1" ] && return 0
  [ "$DRYRUN" = "1" ] && { say "touch  $f"; return 0; }
  : > "$f"
}
write_file() {
  local path="$1"
  if [ -e "$path" ] && [ "$FORCE" != "1" ]; then say "skip   $path (already exists)"; cat >/dev/null; return 0; fi
  if [ "$DRYRUN" = "1" ]; then say "write  $path"; cat >/dev/null; return 0; fi
  mkdir -p "$(dirname "$path")"; cat > "$path"; say "write  $path"
}
escape_sed() {
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}
# Escape for JSON substitution: quotes and backslashes in the project name
# would otherwise invalidate .claude/settings.json.
escape_json() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}
render() {
  local safe_name safe_desc safe_date safe_name_json safe_version
  safe_name="$(escape_sed "$NAME")"
  safe_desc="$(escape_sed "$DESC")"
  safe_date="$(escape_sed "$DATE")"
  safe_version="$(escape_sed "$VERSION")"
  safe_name_json="$(escape_sed "$(escape_json "$NAME")")"
  sed -e "s|__NAME_JSON__|${safe_name_json}|g" -e "s|__NAME__|${safe_name}|g" \
      -e "s|__DESC__|${safe_desc}|g" -e "s|__DATE__|${safe_date}|g" \
      -e "s|__VERSION__|${safe_version}|g"
}

# ---------- artifact directories + .gitkeep ----------
for d in .ai/artifacts .claude/commands .claude/agents .claude/artifacts \
         .cursor/artifacts .antigravity/artifacts .perplexity/artifacts; do
  gitkeep "$d"
done

# ======================================================================
# AGENTS.md — SOURCE OF TRUTH
# ======================================================================
render <<'TPL' | write_file "AGENTS.md"
# AGENTS.md — __NAME__

> **Single source of truth for all AI tools and humans in this repository.**
> Codex, Cursor, Google Antigravity/Gemini, and other AGENTS-compatible tools read this file
> natively. Thin redirects (`.cursorrules`, `CLAUDE.md`, `GEMINI.md`, `PERPLEXITY.md`)
> add detail but do not override these rules. **Read this file fully before working.**

## 1. Project
__DESC__

<!-- TODO: 2–4 sentences — purpose, users, value. -->

## 2. Stack
<!-- TODO: languages, frameworks, DB, infrastructure. -->

## 3. Structure
<!-- TODO: table of "directory → purpose". -->

## 4. Status / current priority
<!-- TODO: where the project is now and what to focus on. -->

## 5. How to change things (agent)
- Work from a plan: break the task down and show steps BEFORE executing.
- Human-in-the-loop: for irreversible operations and production-data edits — stop and ask.
- Produce artifacts (diff, list of changed files, rollback plan) before applying.
- Keep changes atomic; explain WHAT and WHY.
- New code ships with tests; the task is not "done" if tests/lint are failing.

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
Shared artifacts live in `.ai/artifacts/`; tool-specific artifact folders are listed in
`.ai/README.md`. Codex reads this file natively and uses the shared artifacts directory.

<!-- Initialized by init-ai-tooling __VERSION__ (__DATE__). -->
TPL

# ======================================================================
# .cursorrules — redirect
# ======================================================================
render <<'TPL' | write_file ".cursorrules"
# Cursor reads this file for compatibility. SOURCE OF TRUTH — ./AGENTS.md.
# Detailed rules — ./.cursor/rules/*.mdc. Read AGENTS.md before any work.
See AGENTS.md
TPL

# .cursor/rules/000-project.mdc
render <<'TPL' | write_file ".cursor/rules/000-project.mdc"
---
description: Base project context for __NAME__ — points to AGENTS.md
alwaysApply: true
---

# __NAME__

Source of truth — `../../AGENTS.md` (read it fully). This file and sibling `*.mdc`
files hold Cursor-specific and detailed topical rules only.
TPL

# .cursor/rules/010-safety.mdc
render <<'TPL' | write_file ".cursor/rules/010-safety.mdc"
---
description: Security, secrets, production work
alwaysApply: true
---

# Security

- Secrets (passwords, keys, tokens, `.env`, local configs) — not in code, commits, or context.
- Do not edit production directly; destructive operations on production data — only
  with explicit confirmation and a dry run on a copy.
- Before a risky change — show a diff and rollback plan, ask for confirmation.
- Full rules — in `../../AGENTS.md`.
TPL

# .cursorignore
render <<'TPL' | write_file ".cursorignore"
# Secrets and local config
.env
*.local

# Build artifacts and data
dist/
build/
*.egg-info/

# Environments and caches
.venv/
venv/
node_modules/
__pycache__/
*.py[cod]
.pytest_cache/
.mypy_cache/
.ruff_cache/

.DS_Store
TPL

# ======================================================================
# CLAUDE.md — redirect + Claude specifics
# ======================================================================
render <<'TPL' | write_file "CLAUDE.md"
# CLAUDE.md — __NAME__

**Source of truth — [`AGENTS.md`](AGENTS.md). Read it first.** Below — Claude-specific only.

## Claude directories
- `.claude/commands/` — slash commands; `.claude/agents/` — subagents; `.claude/artifacts/` — artifacts.
- Team settings — `.claude/settings.json`; personal — `.claude/settings.local.json` (do not commit).
TPL

# .claude/README.md
render <<'TPL' | write_file ".claude/README.md"
# .claude/ — Claude Code configuration

Source of truth — [`../AGENTS.md`](../AGENTS.md).

- `commands/` — slash commands; `agents/` — subagents; `artifacts/` — Claude artifacts.
- `settings.json` — team settings; `settings.local.json` — personal (do not commit).
TPL

# .claude/settings.json
render <<'TPL' | write_file ".claude/settings.json"
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "//": "Team Claude Code settings for __NAME_JSON__. Personal overrides — settings.local.json (do not commit).",
  "permissions": {
    "allow": ["Read", "Edit"],
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(**.pem)",
      "Read(**.key)",
      "Read(**/.ssh/**)",
      "Read(**/.aws/**)",
      "Read(**/.kube/**)",
      "Bash(rm -rf:*)",
      "Bash(git push --force:*)"
    ]
  }
}
TPL

# ======================================================================
# GEMINI.md — Antigravity/Gemini
# ======================================================================
render <<'TPL' | write_file "GEMINI.md"
# GEMINI.md — Google Antigravity / Gemini

> Antigravity reads both `AGENTS.md` and `GEMINI.md`; on conflict, `GEMINI.md` wins.
> **Project source of truth — `AGENTS.md`; read it first.** Here — Antigravity/Gemini specifics.

## Agent mode
- Work from a plan (task/plan): break the task down and show steps before executing.
- Human-in-the-loop: for production-data/core edits — stop and ask for confirmation.
- Produce artifacts (diff, file list, rollback plan) before applying; save them in `.antigravity/artifacts/`.
- Do not run shell commands against a production server/DB.
- Keep changes atomic, with an explanation of WHAT and WHY.
TPL

render <<'TPL' | write_file ".antigravity/README.md"
# .antigravity/ — Google Antigravity workspace

Rules — in [`../GEMINI.md`](../GEMINI.md); source of truth — [`../AGENTS.md`](../AGENTS.md).
`artifacts/` — plans, task lists, walkthroughs, browser recordings.
TPL

# ======================================================================
# PERPLEXITY.md — brief
# ======================================================================
render <<'TPL' | write_file "PERPLEXITY.md"
# PERPLEXITY.md — brief for Perplexity / research agents

> Perplexity has no native repo config. This file is a **brief**: paste it into a
> prompt / Space (or Comet) to set role, context, and boundaries. Project context comes from `AGENTS.md`.

## Role
Research/content assistant for __NAME__.
<!-- TODO: clarify the role; whether it writes code; data access. -->

## What to use it for
<!-- TODO: research, fact-checking, drafts, competitive analysis. -->

## Boundaries
- Cite sources for facts; do not invent — mark unknowns as "needs verification".
- <!-- TODO: domain limits (ads/medicine/legal/etc.). -->

## Output format
Structured (Markdown/table), easy to transfer. Save as an artifact in `.perplexity/artifacts/`.
TPL

render <<'TPL' | write_file ".perplexity/README.md"
# .perplexity/ — Perplexity / research

Paste-in brief — [`../PERPLEXITY.md`](../PERPLEXITY.md); context — [`../AGENTS.md`](../AGENTS.md).
`artifacts/` — saved research reports (`YYYY-MM-DD-topic.md`; end with sources for verification).
TPL

# ======================================================================
# .ai/README.md — layout map
# ======================================================================
render <<'TPL' | write_file ".ai/README.md"
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

<!-- Initialized by init-ai-tooling __VERSION__ (__DATE__). -->
TPL

# ---------- .gitignore ----------
if [ "$NO_GITIGNORE" != "1" ]; then
  ensure_add_ignore() {
    local line="$1"
    [ "$DRYRUN" = "1" ] && { say "gitignore += $line"; return 0; }
    touch .gitignore
    if ! grep -qxF "$line" .gitignore; then
      if [ -s .gitignore ] && [ -n "$(tail -c1 .gitignore 2>/dev/null)" ]; then
        printf '\n' >> .gitignore
      fi
      printf '%s\n' "$line" >> .gitignore
    fi
  }
  ensure_add_ignore ".env"
  ensure_add_ignore ".env.*"
  ensure_add_ignore "!.env.example"
  ensure_add_ignore "*.local"
  ensure_add_ignore ".claude/settings.local.json"
  ensure_add_ignore ".DS_Store"
fi

say ""
say "Done (${VERSION}): AGENTS.md-model scaffold deployed for \"${NAME}\"."
say "Next: fill in the TODOs in AGENTS.md — every tool reads context from there."
[ "$DRYRUN" = "1" ] && say "(dry-run: nothing was written)"
exit 0
