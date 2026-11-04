# Changelog

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).
Версии — [Semantic Versioning](https://semver.org/lang/ru/).

English: [CHANGELOG.md](CHANGELOG.md).

«Модель v2» / AGENTS.md-модель — архитектурное поколение каркаса, не номер релиза.
Релизный semver живёт в корневом файле `VERSION`; `tools/sync-templates.py` переносит его в скрипты.

## [Unreleased]

### Добавлено

- `skills/repo-tidy/`: навык агента для традиции раскладки, которую генерирует кит, —
  `SKILL.md`, `reference/standard.md` (+ `standard.ru.md`), `scripts/check_layout.py`
  (сообщения на английском) и `scripts/md_links.py`. README → «Порядок в репозитории».
- CI прогоняет сверщик и проверку ссылок на репозитории и на свежем скаффолде AI +
  repo-bootstrap.
- `check_layout.py` и `md_links.py` завершаются с кодом 2 и однострочным сообщением, если
  путь не существует или не является рабочим деревом git (раньше — трейсбек Python).

### Изменено

- Примеры ADR-префикса в справке и README нейтральные (`API`, `web-portal` → `WEB`).
- Стандарт `repo-tidy` (+ `.ru`) совпадает с тем, что генерирует кит: без `PERPLEXITY.md` /
  `.cursorrules` (кит считает их устаревшими), полный генерируемый deny-список и строки
  `.gitignore` (без `_to_delete/`), генерируемая строка «Раскладка инструментов».
- README: запуск repo-bootstrap отдельно с таблицей опций (`--profile`, `--adr-prefix`);
  русский раздел companion теперь говорит то же, что английский.
- CONTRIBUTING: проверки repo-tidy в «Проверить локально» и правило, что изменение раскладки
  обновляет стандарт и сверщик навыка в том же изменении.
- Действия CI: `actions/checkout` v5 → v7, `actions/upload-artifact` v5 → v7,
  `actions/download-artifact` v5 → v8.

## [2.1.0] — 2026-11-04

Генерируемая раскладка теперь следует традиции repo-tidy (см.
`.ai/artifacts/2026-11-04-generator-vs-repo-tidy-tradition.md`).

### Добавлено

- repo-bootstrap `core` пишет `.gitattributes` (LF везде, CRLF для `.bat`/`.cmd`, типовые
  бинарники) и `.editorconfig`.
- repo-bootstrap `full` пишет `docs/README.md` (карта документации) и `docs/adr/README.md`
  (реестр ADR с таблицей префиксов и правилами: `docs/adr/ПРЕФИКС-NNNN-тема.md`, ссылка —
  `ADR ПРЕФИКС-0001`).
- `--adr-prefix` / `-AdrPrefix` задаёт этот префикс (буква и до 9 букв или цифр). По
  умолчанию — первое ASCII-слово имени проекта заглавными, не длиннее 10 символов; `PROJ`,
  если такого слова нет. Одинаково в bash, Python и PowerShell; недопустимое значение —
  код выхода 2, ничего не записывается.
- `tests/compare-trees.py` падает на незаменённом `__ПЛЕЙСХОЛДЕРЕ__` в любом записанном файле
  и требует `.gitattributes` / `.editorconfig` в деревьях repo-семейства.

### Изменено

- Генерируемый `AGENTS.md` разбит на нумерованные разделы: `1. Project`, `2. Stack`,
  `3. Structure`, `4. Status / current priority`, `5. How to make changes (agent)`,
  `6. Security (NEVER)`, `7. Definition of Done`, `Tool layout`. Команды и соглашения слиты
  в раздел 5; Stack, Structure и Status — новые однострочные TODO.
- Генерируемый `.ai/README.md` заканчивается строкой-пометкой, ниже которой пишется
  специфика репозитория (индекс артефактов, команды, субагенты).
- В строки генерируемого `.gitignore` добавлен `.claude/worktrees/`.

### Исправлено

- Генерируемый `.claude/settings.json` запрещает `Read(**/*.pem)` / `Read(**/*.key)` вместо
  `Read(**.pem)` / `Read(**.key)`: однозначный glob в стиле gitignore на любой глубине.

### Репозиторий (генерируемый вывод не меняется)

- Приведён в порядок сверщиком раскладки `repo-tidy`. Собственный `AGENTS.md` репозитория
  разбит на нумерованные разделы (Project, Stack, Structure, Status / current priority,
  How to make changes, Security, Definition of Done, Tool layout); сами правила не менялись.
- `.claude/settings.json` запрещает `Read(**/*.pem)` / `Read(**/*.key)` вместо `**.pem` /
  `**.key`; в `.gitignore` добавлены `.claude/worktrees/` и `_to_delete/`; новый
  `.editorconfig` в согласии с `.gitattributes`.
- В `.ai/README.md` появился раздел специфики репозитория с индексом артефактов.
- `.ai/artifacts/2026-11-04-generator-vs-repo-tidy-tradition.md` перечисляет, где
  генерируемая раскладка расходилась с этой традицией и что из этого принято.

### Исправлено

- **Перевод строки в `--desc` или `--name` ломал bash-скрипты.** Значение подставлялось прямо в
  команду sed, а «голый» перевод строки её обрывает: запуск падал с кодом 1, оставив пустой
  (0 байт) `AGENTS.md` или `LICENSE` и не записав остального. Переводы строк теперь
  экранируются; многострочное описание даёт одинаковый результат в bash, Python и PowerShell.
  Касается `init-ai-tooling.sh` и `init-repo-bootstrap.sh`.
- **`--also-repo` не работал при запуске по символической ссылке.** `init-ai-tooling.sh` и
  `init-ai-tooling.ps1` искали второй скрипт рядом со ссылкой, а не рядом с настоящим скриптом.
  Теперь ссылки разрешаются (PowerShell 7.3+; Windows PowerShell 5.1 по-прежнему берёт каталог
  самого скрипта). README больше не предлагает `install` (у копии второго скрипта нет) и прямо
  об этом говорит; сообщение об ошибке — тоже.
- **`init-ai-tooling.ps1 -AlsoRepo` при сбое второго скрипта всегда выходил с кодом 1.** Теперь
  передаёт его настоящий код выхода, как версии на bash и Python.

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
