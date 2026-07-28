# Changelog

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).
Версии — [Semantic Versioning](https://semver.org/lang/ru/).

«Модель v2» / AGENTS.md-модель — это архитектурное поколение каркаса, не номер
релиза. Релизный semver живёт в константе `VERSION` / `$ToolVersion` трёх скриптов.

## [1.0.0] — 2026-07-28

### Added

- SemVer `1.0.0` как продуктная версия кита.
- Флаги `--version` (Bash/Python) и `-Version` (PowerShell).
- `CHANGELOG.md`.

### Changed

- Подпись в генерируемых `AGENTS.md` и `.ai/README.md`: `init-ai-tooling 1.0.0`
  вместо `init-ai-tooling v2`.
- Сообщение об успехе и справка скриптов показывают semver.
- `tests/compare-trees.py` нормализует подписи по semver.
