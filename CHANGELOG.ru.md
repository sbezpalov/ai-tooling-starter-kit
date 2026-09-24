# Changelog

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).
Версии — [Semantic Versioning](https://semver.org/lang/ru/).

English: [CHANGELOG.md](CHANGELOG.md).

«Модель v2» / AGENTS.md-модель — архитектурное поколение каркаса, не номер релиза.
Релизный semver живёт в корневом файле `VERSION`; `tools/sync-templates.py` переносит его в скрипты.

## [Unreleased]

## [2.0.0] — 2026-09-24

Ломающее изменение: генерируемая раскладка стала меньше. Codex, Cursor и Antigravity
читают `AGENTS.md` нативно, а Claude Code и Gemini CLI импортируют его, поэтому файлы-
редиректы и отдельные папки артефактов инструментов больше не нужны. См. README →
«Обновление с предыдущей версии».

### Добавлено

- `--prune-legacy` / `-PruneLegacy`: показывает остатки 1.x и модели v1 (редиректы,
  папки `artifacts/` инструментов, файлы хаба v1) и выходит. Ничего не удаляет; старые
  папки артефактов с пользовательскими файлами помечаются «move them to .ai/artifacts/ first».
- `tests/legacy-fixture.py` и шаги CI (bash, Python, PowerShell 5.1 и 7): отчёт одинаков
  во всех реализациях и ничего не удаляет.

### Изменено

- `GEMINI.md` теперь импортирует `@./AGENTS.md` для Gemini CLI и содержит необязательный
  раздел для Gemini; общие процессные правила убраны.
- Все инструменты используют `.ai/artifacts/`; это отражено в `.ai/README.md`,
  `CLAUDE.md` и `.claude/README.md`.
- Список устаревших путей хранится в `templates/ai/layout.json` (`legacy_files`,
  `legacy_artifact_dirs`).

### Удалено

- Генерируемые файлы: `.cursorrules`, `PERPLEXITY.md`, `.perplexity/README.md`,
  `.antigravity/README.md` и папки `artifacts/` в `.claude/`, `.cursor/`, `.antigravity/`,
  `.perplexity/`. `tests/compare-trees.py` падает, если каркас снова их создаст.
- Ручной рецепт `rm` для миграции v1 → v2 в README — его заменяет `--prune-legacy`.

## [1.3.0] — 2026-09-24

### Добавлено

- `templates/<семейство>/*.tpl` + `layout.json` и корневой файл `VERSION` — единый
  источник генерируемого текста и номера релиза.
- `tools/sync-templates.py` встраивает их в размеченный блок всех шести скриптов (скрипты
  остаются самодостаточными); CI запускает `--check` и падает на устаревшем скрипте.
- `.ai/manifest.json` фиксирует версию кита, дату создания и файлы/каталоги кита, чтобы
  будущие релизы отличали сгенерированные файлы от пользовательских.

### Изменено

- Сгенерированный `AGENTS.md` короче (47 → 30 строк): Project, Commands, Conventions,
  Never, Done means, Artifacts. Убраны общие процессные правила («показывай шаги ДО
  выполнения», чек-лист с планом отката), которые тратят токены и тормозят автономных агентов.
- README предлагает поручить агенту заполнить TODO в `AGENTS.md` по коду.
- Собственный `AGENTS.md` репозитория переведён на новый формат.

### Тесты

- `tests/compare-trees.py` проверяет, что `.ai/manifest.json` — валидный JSON и
  перечисляет только реально записанные файлы.

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
