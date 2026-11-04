# AGENTS.md — ai-tooling-starter-kit

> Shared instructions for AI coding agents and humans. Codex, Cursor, Google Antigravity/Gemini,
> and other AGENTS-compatible tools read this file natively; Claude Code imports it from `CLAUDE.md`.
> Keep it short: write down only what an agent cannot infer from the code.

## 1. Project
Starter kit that scaffolds a consistent AI-tooling layout (Claude, Codex, Cursor,
Gemini/Antigravity) from three equivalent scripts (Bash / Python / PowerShell),
plus a repo-bootstrap companion family. Public, MIT. English is the default language
for scaffolds and primary docs; `*.ru.md` are translations and must say the same thing.

## 2. Stack
Bash, Python 3.6+ (stdlib only), PowerShell 5.1 and 7+. CI — GitHub Actions
(`.github/workflows/ci.yml`: Ubuntu + Windows, PS 5.1 and 7).

## 3. Structure
| Path | Purpose |
|---|---|
| `init-ai-tooling.{sh,ps1}`, `init_ai_tooling.py` | AI-layout family: `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.claude/`, `.cursor/`, `.ai/` |
| `init-repo-bootstrap.{sh,ps1}`, `init_repo_bootstrap.py` | Repo-bootstrap family: `LICENSE`, `CHANGELOG.md`, `SECURITY.md`, `.gitattributes`, `.editorconfig`, `.github/` templates, `docs/` + ADR registry |
| `templates/ai/`, `templates/repo/` | Source of truth for generated text (`*.tpl` + `layout.json`) |
| `VERSION` | Release number, copied into the scripts by `tools/sync-templates.py` |
| `tools/` | `sync-templates.py` — embeds `templates/` + `VERSION` into the six scripts |
| `tests/` | `compare-trees.py` (byte-for-byte parity), `legacy-fixture.py` (`--prune-legacy` fixture) |
| `.github/` | CI workflow |
| `.ai/`, `.claude/`, `.cursor/` | This repository's own AI layout, scaffolded by the kit (dogfood) |

## 4. Status / current priority
- Release **2.1.0** (2026-11-04): the generated layout follows the repo-tidy tradition
  (numbered `AGENTS.md` sections, deny-list globs, `.gitignore`, `docs/adr/`,
  `.gitattributes`, `.editorconfig`, `--adr-prefix`) — see
  `.ai/artifacts/2026-11-04-generator-vs-repo-tidy-tradition.md`; plus the `--desc`
  line-break, `--also-repo` symlink and `-AlsoRepo` exit-code fixes.
- Tests: no unit suite — the check is the CI parity matrix. Locally: `sync-templates --check`,
  `shellcheck`, and bash = Python = PowerShell trees for both families pass (2026-11-04).
- Blocked: nothing. Next: push and confirm CI is green (incl. Windows PS 5.1), then tag `v2.1.0`.

## 5. How to make changes (agent)
```bash
python3 tools/sync-templates.py            # after editing templates/ or VERSION
python3 tools/sync-templates.py --check    # CI gate: generated blocks are current
shellcheck init-ai-tooling.sh init-repo-bootstrap.sh
python3 tests/compare-trees.py DIR_A DIR_B # byte-for-byte parity of two scaffolded trees
```
The full parity matrix (dry-run, AI / repo / `--also-repo` trees, idempotency, hostile
names, PS 5.1 + 7) lives in `.github/workflows/ci.yml`.

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

## 6. Security (NEVER)
- Commit or print secrets (`.env`, keys, tokens); only `*.example` files belong in the repo.
- Make a script delete or overwrite user files without `--force` / `-Force`.
- Add runtime dependencies to the scripts (stdlib Python 3.6+, Bash, PowerShell 5.1 only).

## 7. Definition of Done
`tools/sync-templates.py --check`, `shellcheck`, and the three-way parity check pass;
behaviour changes are reflected in both READMEs and both CHANGELOGs.

## Tool layout
Artifacts — in `.ai/artifacts/` (shared by every tool; 2.0.0 dropped per-tool `artifacts/`
folders). Details — `.ai/README.md`.
Plans, research, and other durable session results from every tool go there, named
`YYYY-MM-DD-topic.md`. Codex reads this file natively and uses the shared artifacts directory.
