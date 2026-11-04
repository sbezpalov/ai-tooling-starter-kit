# AI Tooling Starter Kit

[![CI](https://github.com/sbezpalov/ai-tooling-starter-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/sbezpalov/ai-tooling-starter-kit/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[English](README.md) · **Русский**

Единый каркас конфигов для базового набора AI-инструментов — **Claude, Codex, Cursor,
Gemini/Antigravity** — который разворачивается одной командой в любом
новом проекте. Экономит время и токены: контекст проекта описывается один раз.

Текущий релиз: **2.1.0** (см. [CHANGELOG.md](CHANGELOG.md) / [CHANGELOG.ru.md](CHANGELOG.ru.md)).
«Модель v2» ниже — название архитектурного поколения (AGENTS.md), не semver.
Шаблоны каркаса и вывод CLI по умолчанию на **английском**; русские документы — в `*.ru.md`.

## Модель (v2 — AGENTS.md)

**`AGENTS.md` = единый источник истины.** Его читают нативно Codex, Cursor, Google
Antigravity/Gemini и другие AGENTS-совместимые инструменты — поэтому контекст не нужно
дублировать и не нужен «файл-указатель, который никто не открывает». Claude Code и
Gemini CLI получают его через импорт `@AGENTS.md`; остальные файлы — специфика инструментов.

| Файл | Инструмент | Роль |
|------|-----------|------|
| `AGENTS.md` | Codex (CLI / IDE / приложение), все агенты | ★ нумерованные разделы: проект, стек, структура, статус, как вносить изменения, список «никогда», критерии готовности, раскладка инструментов |
| `.cursor/rules/*.mdc` + `.cursorignore` | Cursor | правила (`000-project`, `010-safety`); `AGENTS.md` Cursor читает нативно |
| `CLAUDE.md` + `.claude/` | Claude Code / Cowork | импорт `@AGENTS.md` + `commands/`, `agents/`, `settings.json` |
| `GEMINI.md` | Gemini CLI / Antigravity | импорт `@./AGENTS.md` + специфика Gemini; Antigravity читает `AGENTS.md` нативно |
| `.ai/README.md` + `.ai/artifacts/` | — | карта раскладки + артефакты всех инструментов |
| `.ai/manifest.json` | — | версия кита + список файлов кита (для будущих обновлений) |

Планы, исследования и другие долговечные результаты сессий всех инструментов лежат в
одном месте — `.ai/artifacts/`.

Codex не нужен файл-редирект: он нативно находит `AGENTS.md`. Кит намеренно оставляет
`.codex/config.toml` опциональным — модель, разрешения и интеграции стоит настраивать,
только когда у конкретного репозитория есть такая потребность.

> Почему AGENTS.md, а не `.ai/shared-context.md` (как в v1): AGENTS — растущий кросс-
> инструментальный стандарт, читается инструментами напрямую → меньше косвенности.

## Три реализации — один результат

В ките три эквивалентных скрипта: **байт-в-байт одинаковый результат**, одинаковый stdout,
те же флаги, LF-переводы строк на любой ОС.

| Скрипт | Среда |
|--------|-------|
| `init-ai-tooling.sh` | Bash (macOS/Linux) |
| `init_ai_tooling.py` | Python 3.6+, чистый stdlib (кросс-ОС) |
| `init-ai-tooling.ps1` | Windows PowerShell 5.1 / PowerShell 7+ (Windows 10/11, без зависимостей) |

PowerShell-версия проверена вручную на Windows 10/11 под встроенным Windows PowerShell 5.1
и под PowerShell 7, и проверяется в CI на каждый push. Скрипт ничего не удаляет, без
`-Force` не перезаписывает существующие файлы, а `-DryRun` показывает план, ничего не
записывая, — с него удобно начинать.

Эквивалентность реализаций проверяется скриптом `tests/compare-trees.py` — он сравнивает
развёрнутые деревья побайтово (переводы строк намеренно не нормализуются). Запустить локально:

```bash
mkdir -p /tmp/a /tmp/b
(cd /tmp/a && /path/to/init-ai-tooling.sh --name demo --desc "Test")
(cd /tmp/b && python3 /path/to/init_ai_tooling.py --name demo --desc "Test")
python3 tests/compare-trees.py /tmp/a /tmp/b
```

**Один источник шаблонов.** Генерируемый текст хранится один раз — в
`templates/<семейство>/*.tpl` плюс `layout.json` (порядок записи, каталоги с `.gitkeep`,
строки `.gitignore`) и корневой файл `VERSION`. `tools/sync-templates.py` встраивает его
во все шесть скриптов, так что каждый скрипт по-прежнему работает сам по себе, куда бы его
ни скопировали; CI падает, если встроенная копия устарела.

## Companion: repo bootstrap (B+)

AI-каркас остаётся узким. Community/git stubs — в **отдельном** companion-семействе с тем же
тройным паритетом:

| Скрипт | Среда |
|--------|-------|
| `init-repo-bootstrap.sh` | Bash (macOS/Linux) |
| `init_repo_bootstrap.py` | Python 3.6+, только stdlib |
| `init-repo-bootstrap.ps1` | Windows PowerShell 5.1 / PowerShell 7+ |

Профили:

| Профиль | Что пишет |
|---------|-----------|
| `core` (по умолчанию для companion) | заглушка `LICENSE` (не настоящая лицензия), `SECURITY.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `.gitattributes` (LF), `.editorconfig` |
| `github` | core + `.github/CODEOWNERS`, шаблоны issue/PR |
| `full` | github + заглушка `.github/dependabot.yml`, `docs/README.md` (карта документации), `docs/adr/README.md` (реестр ADR) |

ADR называются `docs/adr/ПРЕФИКС-NNNN-тема.md`, ссылка — `ADR ПРЕФИКС-0001`, чтобы номера
не путались между репозиториями. Префикс задаёт `--adr-prefix API` (`-AdrPrefix`; буква и
до 9 букв или цифр). По умолчанию — первое ASCII-слово имени проекта заглавными
(`web-portal` → `WEB`); если такого нет — `PROJ`. `--also-repo` берёт значение по умолчанию.

Запуск отдельно:

```bash
/path/to/init-repo-bootstrap.sh --name my-project --desc "..." --profile github
python3 /path/to/init_repo_bootstrap.py --name my-project --profile full --adr-prefix API
.\init-repo-bootstrap.ps1 -Name my-project -Profile full -AdrPrefix API
```

| Опция (Bash/Python) | Опция (PowerShell) | Значение |
|---------------------|--------------------|----------|
| `--name NAME` | `-Name NAME` | Имя проекта (по умолчанию — имя папки) |
| `--desc "TEXT"` | `-Desc "TEXT"` | Описание в одну строку |
| `--profile P` | `-Profile P` | `core` (по умолчанию), `github` или `full` |
| `--adr-prefix PREFIX` | `-AdrPrefix PREFIX` | Префикс ADR для `docs/adr/` (профиль `full`) |
| `--force` | `-Force` | Перезаписать существующие файлы |
| `--dry-run` | `-DryRun` | Показать план, ничего не писать |
| `--version` | `-Version` | Показать версию скрипта и выйти |

Один вызов из AI-init (профиль по умолчанию для этого пути — `full`):

```bash
init-ai-tooling.sh --name my-project --desc "..." --also-repo
# или
python3 init_ai_tooling.py --name my-project --desc "..." --also-repo --repo-profile core
```

PowerShell: `-AlsoRepo` и `-RepoProfile`. Без флага AI-скрипт печатает подсказку про
companion. Файл LICENSE — **инертная заглушка**: настоящую лицензию нужно выбрать и вставить
самостоятельно.

## Использование

```bash
# macOS / Linux (Bash)
/path/to/init-ai-tooling.sh --name my-project --desc "What this project is"

# Windows 11 / 10 (PowerShell)
.\init-ai-tooling.ps1 -Name my-project -Desc "What this project is"
# Если запуск скриптов заблокирован политикой безопасности Windows:
powershell -ExecutionPolicy Bypass -File .\init-ai-tooling.ps1 -Name my-project

# Любая ОС (Python 3, без зависимостей)
python3 /path/to/init_ai_tooling.py --name my-project --desc "What this project is"
```

| Опция (Bash/Python) | Опция (PowerShell) | Значение |
|---------------------|--------------------|----------|
| `--name NAME` | `-Name NAME` | Имя проекта (по умолчанию — имя папки) |
| `--desc "TEXT"` | `-Desc "TEXT"` | Короткое описание (одна строка) |
| `--force` | `-Force` | Перезаписывать существующие файлы |
| `--dry-run` | `-DryRun` | Показать план, ничего не писать |
| `--no-gitignore` | `-NoGitignore` | Не трогать `.gitignore` |
| `--also-repo` | `-AlsoRepo` | Заодно запустить companion repo-bootstrap |
| `--repo-profile P` | `-RepoProfile P` | Профиль для `--also-repo` (`core`/`github`/`full`, по умолчанию `full`) |
| `--prune-legacy` | `-PruneLegacy` | Показать остатки старых версий кита и выйти (ничего не удаляет) |
| `--version` | `-Version` | Показать версию скрипта и выйти |
| `-h`, `--help` | `-?`, `Get-Help` | Справка |

Идемпотентен: без `--force` не трогает существующее, безопасно запускать повторно.

## Глобальная установка

```bash
ln -s /path/to/ai-tooling-starter-kit/init-ai-tooling.sh ~/bin/ai-init   # если ~/bin в PATH
# либо алиас:
alias ai-init="/path/to/ai-tooling-starter-kit/init-ai-tooling.sh"
```

Ссылка или алиас, а не копия: `--also-repo` запускает `init-repo-bootstrap.sh`, который должен
лежать рядом с настоящим скриптом. По символической ссылке скрипт его находит; у скопированного
файла второго скрипта рядом нет, и `--also-repo` остановится с ошибкой. Если всё же копируете —
копируйте оба скрипта в один каталог.

## После запуска

1. Заполни `TODO` в **`AGENTS.md`** (проект, стек, структура, статус, команды, запреты) — все инструменты
   берут контекст оттуда. Быстрее всего поручить это агенту: *«Прочитай код и заполни TODO
   в AGENTS.md. Коротко — только то, что нельзя понять из кода»*. Проверь результат перед
   коммитом.
2. При необходимости — доменные правила в `.cursor/rules/*.mdc` и специфика Gemini в `GEMINI.md`.
3. Коммит: `git add -A && git commit -m "chore: scaffold AI tooling (AGENTS.md model)"`.

## Что `.claude/settings.json` защищает, а что нет

Сгенерированный список `deny` закрывает очевидные ошибки (чтение `.env` и ключей
файловыми инструментами Claude, `rm -rf`, `git push --force`). Это **страховка, а не
граница безопасности**:

- правила `Bash(...)` сравнивают префикс команды — `rm -r -f`, `find . -delete` или скрипт,
  который удаляет файлы, пройдут;
- без песочницы Claude Code правила `Read(...)` действуют на файловые инструменты Claude,
  но не на `cat .env`, запущенный через Bash.

Для настоящей изоляции включите песочницу Claude Code, запускайте агента в контейнере
или devcontainer, либо добавьте хук `PreToolUse`. Те же ограничения описаны в
сгенерированном `.claude/README.md`.

## Проекты с уже готовой конвенцией

Скрипт идемпотентен и **не перезаписывает** чужие файлы, но на проекте с собственной
раскладкой (свои `.cursor/rules/*.mdc`, `AGENTS.md`, скиллы) может создать частичное
дублирование (напр. свой `00-project.mdc` рядом с генерик `000-project.mdc`). Такие
проекты стоит свести вручную: сделать их контент основой `AGENTS.md`, убрать дубли.

## Обновление с предыдущей версии

2.0 больше не создаёт `.cursorrules`, `PERPLEXITY.md`, `.perplexity/`, `.antigravity/` и
отдельные папки `artifacts/` инструментов (`.claude/`, `.cursor/`); все инструменты теперь
используют `.ai/artifacts/`. Чтобы почистить проект, развёрнутый версией 1.x (или моделью v1):

1. Получите список остатков — скрипт только сообщает и никогда не удаляет:

   ```bash
   init-ai-tooling.sh --prune-legacy        # PowerShell: -PruneLegacy
   ```

2. Перенесите всё, что отчёт помечает как *saved item(s)*, в `.ai/artifacts/`, затем
   удалите перечисленные пути, например `git rm -r .cursorrules PERPLEXITY.md .perplexity .antigravity`.
3. Запустите скрипт ещё раз **без** `--force`, чтобы добавить новые файлы вроде
   `.ai/manifest.json`. Существующие файлы останутся. Чтобы взять новые `CLAUDE.md` /
   `GEMINI.md` (импорт `@AGENTS.md`), не трогая заполненный `AGENTS.md`, разверните каркас
   в пустой папке и скопируйте эти два файла.

## Порядок в репозитории: навык `repo-tidy`

[`skills/repo-tidy/`](skills/repo-tidy/SKILL.md) — навык агента для той же традиции
раскладки, которую генерирует кит, — для уже существующих или «расползшихся» репозиториев:
разделы `AGENTS.md`, один корень `docs/` с картой, реестр ADR с префиксом репозитория,
датированные артефакты, честные статусы, закрытые секреты, git-гигиена. Правила — в
[`reference/standard.ru.md`](skills/repo-tidy/reference/standard.ru.md); проверку делают два
скрипта (Python 3.9+, без зависимостей):

```bash
python3 skills/repo-tidy/scripts/check_layout.py /path/to/repo   # ✗ ошибки, ! предупреждения
python3 skills/repo-tidy/scripts/md_links.py /path/to/repo --fix # починка относительных ссылок
```

Чтобы навык был доступен Claude Code во всех проектах, сделайте ссылку в каталог навыков —
тогда обновления кита приходят через `git pull`:

```bash
ln -s "$PWD/skills/repo-tidy" ~/.claude/skills/repo-tidy
```

Дальше попросите агента «приведи репозиторий в порядок». CI прогоняет сверщик на этом
репозитории и на свежем скаффолде.

## Как помочь проекту

Issues и pull request'ы приветствуются — см. [CONTRIBUTING.md](CONTRIBUTING.md)
([Русский](CONTRIBUTING.ru.md)). Главное правило: правку логики нужно вносить
**во все три скрипта сразу**, иначе CI поймает расхождение. О проблемах безопасности —
[SECURITY.md](SECURITY.md) ([Русский](SECURITY.ru.md)).

## Лицензия

Распространяется под свободной лицензией [MIT License](LICENSE). Вы можете свободно
использовать, модифицировать и встраивать данный стартер-кит в любые коммерческие и
открытые проекты.

---
*Релиз 2.1.0 проверяется в CI: dry-run, реальный прогон, идемпотентность и побайтовое
совпадение результата трёх реализаций (ubuntu + windows-latest, PowerShell 5.1 и 7).*
