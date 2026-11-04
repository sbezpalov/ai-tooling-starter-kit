# Generated layout vs the repo-tidy tradition

| Status | Date | Related |
|---|---|---|
| Decided — all items adopted (see Decision) | 2026-11-04 | `AGENTS.md` §4, `templates/ai/`, `templates/repo/` |

## Context

The repository was tidied with the `repo-tidy` skill (layout checker `check_layout.py`,
tradition `reference/standard.md`). A fresh scaffold of
`init-ai-tooling` 2.0.0 gets **the same 11 checker errors** the repository had before the
tidy-up, because the repository is the kit's own output. The repository itself was fixed;
the generator was **not** changed — doing that changes the product and its version.

## Differences and proposals

| # | Area | Kit 2.0.0 generates | Tradition expects | Proposal | Version impact |
|---|---|---|---|---|---|
| 1 | `AGENTS.md` sections | `Project / Commands / Conventions / Never / Done means / Artifacts` | `## 1.`…`## 7.` (Project, Stack, Structure, Status/priority with blocker, How to change, Security NEVER, DoD) + `## Tool layout` | Numbered English headings with TODO placeholders; add Stack, Structure, Status. Keeps the 1.3.0 "short file" goal if placeholders stay one line each | minor (generated text changes) |
| 2 | `.claude/settings.json` deny | `Read(**.pem)`, `Read(**.key)` | `Read(**/*.pem)`, `Read(**/*.key)` | Switch to `**/*.pem` / `**/*.key` — unambiguous gitignore-style glob at any depth | patch (fix) |
| 3 | `.gitignore` lines | `.env`, `.env.*`, `!.env.example`, `*.local`, `.claude/settings.local.json`, `.DS_Store` | + `.claude/worktrees/` (`_to_delete/` is a personal convention) | Add `.claude/worktrees/` to `layout.json` `gitignore` | patch |
| 4 | `.ai/README.md` | Generic map only | Generic map, then `<!-- marker -->` and repo-specific notes / artifact index below it | Add an English marker line (e.g. `<!-- Below: repository-specific notes. -->`) so later edits have a fixed place | minor |
| 5 | Per-tool `.claude/artifacts/` | Not generated (removed in 2.0.0; `--prune-legacy` flags it) | Required by the checker | **Keep the kit as is**; update the tradition and `check_layout.py` to accept a single `.ai/artifacts/` | none for the kit |
| 6 | Redirect files | `CLAUDE.md` / `GEMINI.md` as `@AGENTS.md` imports; no `.cursorrules`, `PERPLEXITY.md`, `.antigravity/`, `.perplexity/` | Lists them in the layout | **Keep the kit**; the import is stronger than a "read AGENTS.md first" redirect. Update the tradition | none |
| 7 | `docs/`, `docs/adr/` | Nothing | `docs/README.md` map, `docs/adr/README.md` registry, `PREFIX-NNNN-topic.md` | Optional in repo-bootstrap `full` profile: `docs/README.md` + `docs/adr/README.md` with a prefix from `--adr-prefix` (default: uppercased `--name`) | minor (new option, three scripts) |
| 8 | `.gitattributes` / `.editorconfig` | Neither (repo-bootstrap) | Both | Add to repo-bootstrap `core`: `* text=auto eol=lf` and a neutral `.editorconfig` | minor |
| 9 | Language | English, `*.ru.md` translations | "Project language" | No change: the tradition's own rule is "language of the project" | none |

## Residual checker findings in this repository (deliberate)

- ✗ `.claude/artifacts/` missing — see #5; adding it would contradict 2.0.0 and be
  reported by the kit's own `--prune-legacy`.
- ! no `docs/` — the public docs are the GitHub-standard root files (`README`,
  `CONTRIBUTING`, `SECURITY`, `CHANGELOG`, each with a `.ru.md` pair); no ADRs exist.

## Decision (2026-11-04)

The owner asked to apply everything. Items 1–4, 7 and 8 changed the generator (Unreleased
in `CHANGELOG.md`). Items 5 and 6 changed the `repo-tidy` skill instead: its standard and
`check_layout.py` now treat per-tool `artifacts/` folders and `.cursorrules` /
`PERPLEXITY.md` as optional and accept the `@AGENTS.md` import. With that, this repository
passes the checker with 0 errors.
