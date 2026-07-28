# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/).

Russian translation: [CHANGELOG.ru.md](CHANGELOG.ru.md).

“Model v2” / AGENTS.md model names the architectural generation of the scaffold, not the
release number. Product semver lives in the `VERSION` / `$ToolVersion` constant of the
three scripts.

## [Unreleased]

### Changed

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
