# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/).

Russian translation: [CHANGELOG.ru.md](CHANGELOG.ru.md).

“Model v2” / AGENTS.md model names the architectural generation of the scaffold, not the
release number. Product semver lives in the root `VERSION` file; `tools/sync-templates.py`
copies it into the scripts.

## [Unreleased]

## [2.1.0] — 2026-11-04

The generated layout now follows the repo-tidy tradition (see
`.ai/artifacts/2026-11-04-generator-vs-repo-tidy-tradition.md`).

### Added

- repo-bootstrap `core` writes `.gitattributes` (LF everywhere, CRLF for `.bat`/`.cmd`,
  common binaries) and `.editorconfig`.
- repo-bootstrap `full` writes `docs/README.md` (documentation map) and `docs/adr/README.md`
  (ADR registry with a prefix table and rules: `docs/adr/PREFIX-NNNN-topic.md`,
  references as `ADR PREFIX-0001`).
- `--adr-prefix` / `-AdrPrefix` sets that prefix (a letter, then up to 9 letters or digits).
  Default: the first ASCII word of the project name, upper-cased, at most 10 characters;
  `PROJ` when the name has none. Identical in bash, Python and PowerShell; an invalid
  value exits with code 2 and writes nothing.
- `tests/compare-trees.py` fails on an unrendered `__PLACEHOLDER__` in any written file and
  requires `.gitattributes` / `.editorconfig` in repo-family trees.

### Changed

- Generated `AGENTS.md` uses numbered sections: `1. Project`, `2. Stack`, `3. Structure`,
  `4. Status / current priority`, `5. How to make changes (agent)`, `6. Security (NEVER)`,
  `7. Definition of Done`, `Tool layout`. Commands and conventions merge into section 5;
  Stack, Structure and Status are new one-line TODOs.
- Generated `.ai/README.md` ends with a marker line below which repository-specific notes
  (artifact index, commands, subagents) go.
- Generated `.gitignore` lines include `.claude/worktrees/`.

### Fixed

- Generated `.claude/settings.json` denies `Read(**/*.pem)` / `Read(**/*.key)` instead of
  `Read(**.pem)` / `Read(**.key)`: an unambiguous gitignore-style glob at any depth.

### Repository (no change to generated output)

- Tidied with the `repo-tidy` layout checker. The repository's own `AGENTS.md` now uses
  numbered sections (Project, Stack, Structure, Status / current priority, How to make
  changes, Security, Definition of Done, Tool layout); the rules themselves are unchanged.
- `.claude/settings.json` denies `Read(**/*.pem)` / `Read(**/*.key)` instead of `**.pem` /
  `**.key`; `.gitignore` adds `.claude/worktrees/` and `_to_delete/`; new `.editorconfig`
  matching `.gitattributes`.
- `.ai/README.md` gets a repository-specific section with an artifact index.
- `.ai/artifacts/2026-11-04-generator-vs-repo-tidy-tradition.md` lists where the generated
  layout differed from that tradition and what was adopted.

### Fixed

- **A line break in `--desc` or `--name` broke the bash scripts.** The value went straight
  into a sed command, where a raw newline ends the command: the run aborted with exit code 1
  after leaving a 0-byte `AGENTS.md` (or `LICENSE`) behind and writing nothing else. Line
  breaks are now escaped; a multi-line description renders the same in bash, Python and
  PowerShell. Applies to `init-ai-tooling.sh` and `init-repo-bootstrap.sh`.
- **`--also-repo` did not work from a symlink.** `init-ai-tooling.sh` and
  `init-ai-tooling.ps1` looked for the companion script next to the link, not next to the
  real script. Symlinks are now followed (PowerShell 7.3+; Windows PowerShell 5.1 keeps the
  script's own directory). The README no longer suggests `install` (a copy has no companion)
  and says so; the error message does too.
- **`init-ai-tooling.ps1 -AlsoRepo` always exited with 1 when the companion failed.** It now
  passes the companion's own exit code on, as the bash and Python versions do.

## [2.0.0] — 2026-09-24

Breaking: the generated layout shrinks. Codex, Cursor, and Antigravity read `AGENTS.md`
natively and Claude Code / Gemini CLI import it, so redirect files and per-tool artifact
folders no longer earn their keep. See README → "Upgrading from an earlier version".

### Added

- `--prune-legacy` / `-PruneLegacy`: lists leftovers from 1.x and the v1 model (redirect
  files, per-tool `artifacts/` folders, v1 hub files) and exits. It never deletes; legacy
  artifact folders that hold user files are flagged "move them to .ai/artifacts/ first".
- `tests/legacy-fixture.py` and CI steps (bash, Python, PowerShell 5.1 and 7) proving the
  report is identical across implementations and deletes nothing.

### Changed

- `GEMINI.md` is now an `@./AGENTS.md` import for Gemini CLI plus an optional Gemini section;
  the generic process rules are gone.
- All tools share `.ai/artifacts/`; `.ai/README.md`, `CLAUDE.md`, and `.claude/README.md`
  say so.
- Legacy paths live in `templates/ai/layout.json` (`legacy_files`, `legacy_artifact_dirs`).

### Removed

- Generated files: `.cursorrules`, `PERPLEXITY.md`, `.perplexity/README.md`,
  `.antigravity/README.md`, and the `.claude/`, `.cursor/`, `.antigravity/`, `.perplexity/`
  `artifacts/` folders. `tests/compare-trees.py` fails if a scaffold writes them again.
- README's manual v1 → v2 `rm` recipe, replaced by `--prune-legacy`.

## [1.3.0] — 2026-09-24

### Added

- `templates/<family>/*.tpl` + `layout.json` and a root `VERSION` file as the single source
  of truth for generated text and the release number.
- `tools/sync-templates.py` embeds them into a marked block in all six scripts (scripts stay
  self-contained); CI runs `--check` and fails on a stale script.
- `.ai/manifest.json` records the kit version, creation date, and the kit-owned files and
  directories, so later releases can tell generated files from user files.

### Changed

- Shorter generated `AGENTS.md` (47 → 30 lines): Project, Commands, Conventions, Never,
  Done means, Artifacts. Removed generic process rules ("show steps BEFORE executing",
  rollback-plan checklist) that cost tokens and slow down autonomous agents.
- README suggests letting an agent fill in the `AGENTS.md` TODOs from the codebase.
- The repository's own `AGENTS.md` follows the new format.

### Tests

- `tests/compare-trees.py` checks that `.ai/manifest.json` is valid JSON and lists only
  files that were actually written.

## [1.2.1] — 2026-09-24

### Changed

- Generated `CLAUDE.md` now imports `AGENTS.md` with an `@AGENTS.md` line, so Claude Code
  loads the rules deterministically instead of relying on a prose redirect.
- `.claude/settings.json` also denies `rm -fr` and `git push -f`, and its comment states
  that deny rules are guardrails, not a sandbox.
- Generated `.claude/README.md` and the README document what the deny list does not cover
  (other flag orders, `find -delete`, `cat .env` through Bash without the sandbox).

### Fixed

- CI: the BOM check could not run under PowerShell (`$script:` parsed as a scope
  modifier), which masked that `init-ai-tooling.ps1` had lost its UTF-8 BOM.
  The BOM is restored; Windows PowerShell 5.1 reads the script correctly again.
- CI: GitHub Actions bumped to v5 (Node 20 deprecation).
- Removed committed `__pycache__/*.pyc` files and ignored them.

### Tests

- `tests/compare-trees.py` enforces the Claude contract: `CLAUDE.md` must contain an
  `@AGENTS.md` import line.

## [1.2.0] — 2026-09-24

### Added

- Companion family `init-repo-bootstrap.{sh,py,ps1}` for inert community/git stubs
  (LICENSE placeholder, SECURITY, CHANGELOG, CONTRIBUTING) with profiles
  `core` | `github` | `full`.
- B+ orchestration: `--also-repo` / `-AlsoRepo` on the AI init scripts invokes the
  sibling companion (`--repo-profile` / `-RepoProfile`, default `full`).
- Discoverability tip when AI init runs without `--also-repo`.
- CI coverage for repo-bootstrap parity and `--also-repo` combined trees.

### Changed

- Product version bumped to **1.2.0** across both script families.
- `tests/compare-trees.py` normalizes both generator signatures and applies a
  repo-stub contract when `AGENTS.md` is absent.

## [1.1.0] — 2026-07-30

### Added

- Explicit support for Codex CLI, IDE, and app through the existing native
  `AGENTS.md` model.
- A scaffold contract check that verifies the generated Codex guidance.

### Changed

- Support tables, generator help, and generated instructions now name Codex.
- Codex uses the shared `.ai/artifacts/` directory; no redundant `CODEX.md`,
  default `.codex/config.toml`, or unwritable `.codex/artifacts/` is scaffolded.
- Default language is **English** for scaffolds, CLI messages/comments, and primary docs.
- Russian docs moved to `*.ru.md` (`README.ru.md`, `CONTRIBUTING.ru.md`, `SECURITY.ru.md`,
  `CHANGELOG.ru.md`). `README.en.md` removed in favor of `README.md` as the English default.

## [1.0.0] — 2026-07-28

### Added

- SemVer `1.0.0` as the product version of the kit.
- `--version` (Bash/Python) and `-Version` (PowerShell) flags.
- `CHANGELOG.md`.

### Changed

- Generator signature in `AGENTS.md` / `.ai/README.md`: `init-ai-tooling 1.0.0`
  instead of `init-ai-tooling v2`.
- Success message and script help show semver.
- `tests/compare-trees.py` normalizes signatures by semver.
