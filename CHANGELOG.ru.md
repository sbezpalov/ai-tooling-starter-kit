# Changelog

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).
Версии — [Semantic Versioning](https://semver.org/lang/ru/).

English: [CHANGELOG.md](CHANGELOG.md).

«Модель v2» / AGENTS.md-модель — архитектурное поколение каркаса, не номер релиза.
Релизный semver живёт в константе `VERSION` / `$ToolVersion` трёх скриптов.

## [Unreleased]

## [1.2.1] — 2026-09-24

### Изменено

- Сгенерированный `CLAUDE.md` импортирует `AGENTS.md` строкой `@AGENTS.md`: Claude Code
  загружает правила гарантированно, а не по текстовому редиректу.
- `.claude/settings.json` дополнительно запрещает `rm -fr` и `git push -f`, а комментарий
  в нём прямо говорит, что deny-правила — страховка, а не песочница.
- Сгенерированный `.claude/README.md` и README описывают, что deny-список не ловит
  (другой порядок флагов, `find -delete`, `cat .env` через Bash без песочницы).

### Исправлено

- CI: проверка BOM не могла выполниться в PowerShell (`$script:` разбиралось как
  модификатор области видимости), и это скрывало, что `init-ai-tooling.ps1` потерял
  UTF-8 BOM. BOM восстановлен; Windows PowerShell 5.1 снова читает скрипт корректно.
- CI: GitHub Actions обновлены до v5 (устаревание Node 20).
- Удалены закоммиченные `__pycache__/*.pyc`, они добавлены в `.gitignore`.

### Тесты

- `tests/compare-trees.py` проверяет контракт Claude: в `CLAUDE.md` должна быть строка
  импорта `@AGENTS.md`.

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
