#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""init_ai_tooling.py (1.0.0, AGENTS.md model) — cross-OS counterpart to init-ai-tooling.sh.

Scaffolds an AI tooling layout (Claude, Cursor, Antigravity/Gemini, Perplexity)
in the current repository. Model: AGENTS.md = single source of truth; thin
redirects at the root (.cursorrules, CLAUDE.md, GEMINI.md, PERPLEXITY.md); .ai/
is for artifacts only.

Pure stdlib (Python 3.6+), no dependencies. Idempotent (without --force does not
touch existing files). Writes LF line endings on every OS. Output matches the
bash version.

Usage:
    python3 init_ai_tooling.py [--name NAME] [--desc "DESC"] [--force] [--dry-run] [--no-gitignore]
"""
import argparse
import datetime
import os
from pathlib import Path
import sys

VERSION = "1.0.0"

# ---------------------------------------------------------------------------
# Artifact directories (each gets a .gitkeep)
# ---------------------------------------------------------------------------
GITKEEP_DIRS = [
    ".ai/artifacts",
    ".claude/commands",
    ".claude/agents",
    ".claude/artifacts",
    ".cursor/artifacts",
    ".antigravity/artifacts",
    ".perplexity/artifacts",
]

# ---------------------------------------------------------------------------
# File templates (placeholders __NAME__ / __DESC__ / __DATE__ / __VERSION__).
# Order = write order (matches the bash version).
# ---------------------------------------------------------------------------
FILES = []  # list of (path, content) tuples


def _add(path, content):
    FILES.append((path, content))


_add("AGENTS.md", """\
# AGENTS.md — __NAME__

> **Single source of truth for all AI tools and humans in this repository.**
> Cursor, Google Antigravity/Gemini, and other AGENTS-compatible tools read this file
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
Artifacts live in `.ai/artifacts/` (cross-tool) and `.<tool>/artifacts/`. Details — `.ai/README.md`.

<!-- Initialized by init-ai-tooling __VERSION__ (__DATE__). -->
""")

_add(".cursorrules", """\
# Cursor reads this file for compatibility. SOURCE OF TRUTH — ./AGENTS.md.
# Detailed rules — ./.cursor/rules/*.mdc. Read AGENTS.md before any work.
See AGENTS.md
""")

_add(".cursor/rules/000-project.mdc", """\
---
description: Base project context for __NAME__ — points to AGENTS.md
alwaysApply: true
---

# __NAME__

Source of truth — `../../AGENTS.md` (read it fully). This file and sibling `*.mdc`
files hold Cursor-specific and detailed topical rules only.
""")

_add(".cursor/rules/010-safety.mdc", """\
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
""")

_add(".cursorignore", """\
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
""")

_add("CLAUDE.md", """\
# CLAUDE.md — __NAME__

**Source of truth — [`AGENTS.md`](AGENTS.md). Read it first.** Below — Claude-specific only.

## Claude directories
- `.claude/commands/` — slash commands; `.claude/agents/` — subagents; `.claude/artifacts/` — artifacts.
- Team settings — `.claude/settings.json`; personal — `.claude/settings.local.json` (do not commit).
""")

_add(".claude/README.md", """\
# .claude/ — Claude Code configuration

Source of truth — [`../AGENTS.md`](../AGENTS.md).

- `commands/` — slash commands; `agents/` — subagents; `artifacts/` — Claude artifacts.
- `settings.json` — team settings; `settings.local.json` — personal (do not commit).
""")

_add(".claude/settings.json", """\
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
""")

_add("GEMINI.md", """\
# GEMINI.md — Google Antigravity / Gemini

> Antigravity reads both `AGENTS.md` and `GEMINI.md`; on conflict, `GEMINI.md` wins.
> **Project source of truth — `AGENTS.md`; read it first.** Here — Antigravity/Gemini specifics.

## Agent mode
- Work from a plan (task/plan): break the task down and show steps before executing.
- Human-in-the-loop: for production-data/core edits — stop and ask for confirmation.
- Produce artifacts (diff, file list, rollback plan) before applying; save them in `.antigravity/artifacts/`.
- Do not run shell commands against a production server/DB.
- Keep changes atomic, with an explanation of WHAT and WHY.
""")

_add(".antigravity/README.md", """\
# .antigravity/ — Google Antigravity workspace

Rules — in [`../GEMINI.md`](../GEMINI.md); source of truth — [`../AGENTS.md`](../AGENTS.md).
`artifacts/` — plans, task lists, walkthroughs, browser recordings.
""")

_add("PERPLEXITY.md", """\
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
""")

_add(".perplexity/README.md", """\
# .perplexity/ — Perplexity / research

Paste-in brief — [`../PERPLEXITY.md`](../PERPLEXITY.md); context — [`../AGENTS.md`](../AGENTS.md).
`artifacts/` — saved research reports (`YYYY-MM-DD-topic.md`; end with sources for verification).
""")

_add(".ai/README.md", """\
# .ai/ — AI tooling layout

**Source of truth — [`../AGENTS.md`](../AGENTS.md)** (read natively by Cursor,
Antigravity/Gemini, and others). Everything else is a thin redirect or tool-specific detail.

| Tool | File | Artifacts |
|---|---|---|
| All agents | `AGENTS.md` | `.ai/artifacts/` |
| Cursor | `.cursorrules` → AGENTS.md; `.cursor/rules/*.mdc`; `.cursorignore` | `.cursor/artifacts/` |
| Claude (Code / Cowork) | `CLAUDE.md` → AGENTS.md; `.claude/` | `.claude/artifacts/` |
| Antigravity / Gemini | `GEMINI.md` (+ AGENTS.md) | `.antigravity/artifacts/` |
| Perplexity | `PERPLEXITY.md` (paste-in brief) | `.perplexity/artifacts/` |

## Rule
Project changes → edit **`AGENTS.md`**. Tool-specific detail → that tool's file.
An artifact is a durable session result (plan, research, diff, task list).

<!-- Initialized by init-ai-tooling __VERSION__ (__DATE__). -->
""")

GITIGNORE_LINES = [
    ".env",
    ".env.*",
    "!.env.example",
    "*.local",
    ".claude/settings.local.json",
    ".DS_Store",
]


def say(msg=""):
    print(msg)


def render(text, name, desc, date, version=VERSION):
    # __NAME_JSON__ — name escaped for JSON substitution: quotes and backslashes
    # would otherwise invalidate .claude/settings.json.
    name_json = name.replace("\\", "\\\\").replace('"', '\\"')
    return (text.replace("__NAME_JSON__", name_json)
                .replace("__NAME__", name)
                .replace("__DESC__", desc)
                .replace("__DATE__", date)
                .replace("__VERSION__", version))


def main(argv=None):
    p = argparse.ArgumentParser(
        prog="init_ai_tooling.py",
        description="AI tooling scaffold (AGENTS.md model).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Creates: AGENTS.md (source of truth), .cursorrules + .cursor/rules/*.mdc + "
            ".cursorignore, CLAUDE.md + .claude/, GEMINI.md + .antigravity/, "
            "PERPLEXITY.md + .perplexity/, .ai/ (layout map + artifacts). "
            "Each tool gets an artifacts/ folder."
        ),
    )
    p.add_argument("--name", default="", help="Project name (defaults to the folder name).")
    p.add_argument("--desc", default="", help="One-line description.")
    p.add_argument("--force", action="store_true", help="Overwrite existing files.")
    p.add_argument("--dry-run", action="store_true", help="Print the plan, write nothing.")
    p.add_argument("--no-gitignore", action="store_true", help="Leave .gitignore alone.")
    p.add_argument(
        "--version",
        action="version",
        version="%(prog)s " + VERSION,
        help="Print version and exit.",
    )
    args = p.parse_args(argv)

    name = args.name or os.path.basename(os.getcwd())
    desc = args.desc or "TODO: short project description"
    date = datetime.date.today().isoformat()
    force, dry = args.force, args.dry_run

    def ensure_dir(d: Path):
        if dry:
            say("mkdir  " + str(d).replace(os.sep, "/"))
        else:
            d.mkdir(parents=True, exist_ok=True)

    def gitkeep(d_str: str):
        p = Path(d_str)
        ensure_dir(p)
        f = p / ".gitkeep"
        if f.exists() and not force:
            return
        if dry:
            say("touch  " + str(f).replace(os.sep, "/"))
            return
        try:
            f.touch()
        except OSError as e:
            say("error  failed to create %s: %s" % (f, e))
            sys.exit(1)

    def write_file(path_str: str, content: str):
        p = Path(path_str)
        if p.exists() and not force:
            say("skip   " + path_str + " (already exists)")
            return
        if dry:
            say("write  " + path_str)
            return
        try:
            p.parent.mkdir(parents=True, exist_ok=True)
            # newline="\n" — LF on every OS (including Windows), matching bash
            with open(p, "w", encoding="utf-8", newline="\n") as fh:
                fh.write(content)
            say("write  " + path_str)
        except OSError as e:
            say("error  failed to write %s: %s" % (path_str, e))
            sys.exit(1)

    # 1) artifact directories + .gitkeep
    for d in GITKEEP_DIRS:
        gitkeep(d)

    # 2) files
    for rel, tpl in FILES:
        write_file(rel, render(tpl, name, desc, date))

    # 3) .gitignore
    if not args.no_gitignore:
        gitignore_path = Path(".gitignore")
        existing_lines = []
        if gitignore_path.exists():
            try:
                with open(gitignore_path, "r", encoding="utf-8") as fh:
                    existing_lines = fh.read().splitlines()
            except OSError as e:
                say("warning failed to read .gitignore: %s" % e)

        for line in GITIGNORE_LINES:
            if line not in existing_lines:
                if dry:
                    say("gitignore += " + line)
                    continue
                try:
                    needs_newline = False
                    if gitignore_path.exists() and gitignore_path.stat().st_size > 0:
                        with open(gitignore_path, "rb") as fh:
                            fh.seek(-1, os.SEEK_END)
                            if fh.read(1) != b"\n":
                                needs_newline = True
                    with open(gitignore_path, "a", encoding="utf-8", newline="\n") as fh:
                        if needs_newline:
                            fh.write("\n")
                            needs_newline = False
                        fh.write(line + "\n")
                    existing_lines.append(line)
                except OSError as e:
                    say("warning failed to update .gitignore: %s" % e)

    say("")
    say('Done (%s): AGENTS.md-model scaffold deployed for "%s".' % (VERSION, name))
    say("Next: fill in the TODOs in AGENTS.md — every tool reads context from there.")
    if dry:
        say("(dry-run: nothing was written)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
