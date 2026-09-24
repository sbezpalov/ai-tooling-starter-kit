# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/).

Russian translation: [CHANGELOG.ru.md](CHANGELOG.ru.md).

“Model v2” / AGENTS.md model names the architectural generation of the scaffold, not the
release number. Product semver lives in the `VERSION` / `$ToolVersion` constant of the
three scripts.

## [Unreleased]

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
