# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/).

Russian translation: [CHANGELOG.ru.md](CHANGELOG.ru.md).

“Model v2” / AGENTS.md model names the architectural generation of the scaffold, not the
release number. Product semver lives in the `VERSION` / `$ToolVersion` constant of the
three scripts.

## [Unreleased]

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
