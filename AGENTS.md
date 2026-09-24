# AGENTS.md — ai-tooling-starter-kit

> Shared instructions for AI coding agents and humans. Codex, Cursor, Google Antigravity/Gemini,
> and other AGENTS-compatible tools read this file natively; Claude Code imports it from `CLAUDE.md`.
> Keep it short: write down only what an agent cannot infer from the code.

## Project
Starter kit that scaffolds a consistent AI-tooling layout (Claude, Codex, Cursor,
Gemini/Antigravity) from three equivalent scripts (Bash / Python / PowerShell),
plus a repo-bootstrap companion family. Release **2.0.0**; English is the default language
for scaffolds and primary docs (`*.ru.md` are translations).

## Commands
```bash
python3 tools/sync-templates.py            # after editing templates/ or VERSION
python3 tools/sync-templates.py --check    # CI gate: generated blocks are current
shellcheck init-ai-tooling.sh init-repo-bootstrap.sh
python3 tests/compare-trees.py DIR_A DIR_B # byte-for-byte parity of two scaffolded trees
```
The full parity matrix (dry-run, AI / repo / `--also-repo` trees, idempotency, hostile
names, PS 5.1 + 7) lives in `.github/workflows/ci.yml`.

## Conventions
- `templates/<family>/*.tpl` + `layout.json` + `VERSION` are the source of truth for
  generated text. Never hand-edit the `BEGIN GENERATED … END GENERATED` block in a script.
- Logic changes land in **all three** scripts of the affected family at once
  (`init-ai-tooling.{sh,ps1}` + `init_ai_tooling.py`, `init-repo-bootstrap.{sh,ps1}` +
  `init_repo_bootstrap.py`).
- Output is LF on every OS; `.ps1` files are UTF-8 **with BOM** and CRLF on disk.
- PowerShell templates are literal here-strings (`@'…'@`); substitution uses `.Replace()`.
- Pitfalls already hit are listed in `CONTRIBUTING.md` — read it before touching `.ps1`.
- Paths the kit no longer generates go in `layout.json` `legacy_files` / `legacy_artifact_dirs`
  so `--prune-legacy` reports them.

## Never
- Commit or print secrets (`.env`, keys, tokens); only `*.example` files belong in the repo.
- Make a script delete or overwrite user files without `--force` / `-Force`.
- Add runtime dependencies to the scripts (stdlib Python 3.6+, Bash, PowerShell 5.1 only).

## Done means
`tools/sync-templates.py --check`, `shellcheck`, and the three-way parity check pass;
behaviour changes are reflected in both READMEs and both CHANGELOGs.

## Artifacts
Plans, research, and other durable session results from every tool go in `.ai/artifacts/`.
Codex reads this file natively and uses the shared artifacts directory.
