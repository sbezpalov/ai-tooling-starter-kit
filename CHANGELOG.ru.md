# Changelog

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).
Версии — [Semantic Versioning](https://semver.org/lang/ru/).

English: [CHANGELOG.md](CHANGELOG.md).

«Модель v2» / AGENTS.md-модель — архитектурное поколение каркаса, не номер релиза.
Релизный semver живёт в константе `VERSION` / `$ToolVersion` трёх скриптов.

## [Unreleased]

## [1.2.0] — 2026-09-24

### Добавлено

- Companion-семейство `init-repo-bootstrap.{sh,py,ps1}`: инертные community/git
  stubs (LICENSE-заглушка, SECURITY, CHANGELOG, CONTRIBUTING) с профилями
  `core` | `github` | `full`.
- Оркестрация B+: `--also-repo` / `-AlsoRepo` на AI-init вызывает sibling companion
  (`--repo-profile` / `-RepoProfile`, по умолчанию `full`).
- Tip в конце AI-init, если `--also-repo` не передан.
- CI: паритет repo-bootstrap и комбинированные деревья `--also-repo`.

### Изменено

- Версия продукта **1.2.0** в обоих семействах скриптов.
- `tests/compare-trees.py` нормализует обе сигнатуры генераторов и проверяет
  repo-stub контракт, если нет `AGENTS.md`.

## [1.1.0] — 2026-07-30

### Добавлено

- Явная поддержка Codex CLI, IDE и приложения через существующую нативную
  модель `AGENTS.md`.
- Контрактная проверка Codex-инструкций в сгенерированном каркасе.

### Changed

- Codex теперь явно указан в таблицах поддержки, справке генераторов и
  генерируемых инструкциях.
- Для результатов Codex используется общий каталог `.ai/artifacts/`; лишние
  `CODEX.md`, `.codex/config.toml` по умолчанию и недоступный для записи
  `.codex/artifacts/` не создаются.
- Язык по умолчанию — **английский** для шаблонов, CLI и основных документов.
- Русские документы перенесены в `*.ru.md` (`README.ru.md`, `CONTRIBUTING.ru.md`,
  `SECURITY.ru.md`, `CHANGELOG.ru.md`). `README.en.md` удалён: `README.md` теперь
  английский по умолчанию.

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
