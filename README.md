# AI Tooling Starter Kit (v2 — AGENTS.md-модель)

[![CI](https://github.com/sbezpalov/ai-tooling-starter-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/sbezpalov/ai-tooling-starter-kit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Русский** · [English](README.en.md)

Единый каркас конфигов для базового набора AI-инструментов — **Claude, Cursor,
Antigravity/Gemini, Perplexity** — который разворачивается одной командой в любом
новом проекте. Экономит время и токены: контекст проекта описывается один раз.

## Модель (v2)

**`AGENTS.md` = единый источник истины.** Его читают нативно Cursor, Google
Antigravity/Gemini и другие AGENTS-совместимые инструменты — поэтому контекст не нужно
дублировать и не нужен «файл-указатель, который никто не открывает». Остальные файлы —
тонкие редиректы/специфика в корне.

| Файл | Инструмент | Роль |
|------|-----------|------|
| `AGENTS.md` | все агенты | ★ проект, стек, правила, DoD, безопасность |
| `.cursorrules` + `.cursor/rules/*.mdc` + `.cursorignore` | Cursor | редирект + правила (`000-project`, `010-safety`) |
| `CLAUDE.md` + `.claude/` | Claude Code / Cowork | редирект + `commands/`, `agents/`, `settings.json` |
| `GEMINI.md` | Antigravity / Gemini | агент-специфика (приоритет при конфликте) |
| `PERPLEXITY.md` | Perplexity | вставляемый бриф (роль/границы/формат) |
| `.ai/README.md` + `.ai/artifacts/` | — | карта раскладки + кросс-инструментальные артефакты |

Артефакты у каждого инструмента: `.claude/artifacts/`, `.cursor/artifacts/`,
`.antigravity/artifacts/`, `.perplexity/artifacts/`, плюс общий `.ai/artifacts/`.

> Почему AGENTS.md, а не `.ai/shared-context.md` (как в v1): AGENTS — растущий кросс-
> инструментальный стандарт, читается инструментами напрямую → меньше косвенности.

## Три версии — один результат

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
(cd /tmp/a && /path/to/init-ai-tooling.sh --name demo --desc "Тест")
(cd /tmp/b && python3 /path/to/init_ai_tooling.py --name demo --desc "Тест")
python3 tests/compare-trees.py /tmp/a /tmp/b
```

## Использование

```bash
# macOS / Linux (Bash)
/path/to/init-ai-tooling.sh --name my-project --desc "Что это за проект"

# Windows 11 / 10 (PowerShell)
.\init-ai-tooling.ps1 -Name my-project -Desc "Что это за проект"
# Если запуск скриптов заблокирован политикой безопасности Windows:
powershell -ExecutionPolicy Bypass -File .\init-ai-tooling.ps1 -Name my-project

# Любая ОС (Python 3, без зависимостей)
python3 /path/to/init_ai_tooling.py --name my-project --desc "Что это за проект"
```

| Опция (Bash/Python) | Опция (PowerShell) | Значение |
|---------------------|--------------------|----------|
| `--name ИМЯ` | `-Name ИМЯ` | Имя проекта (по умолчанию — имя папки) |
| `--desc "ТЕКСТ"` | `-Desc "ТЕКСТ"` | Короткое описание (одна строка) |
| `--force` | `-Force` | Перезаписывать существующие файлы |
| `--dry-run` | `-DryRun` | Показать план, ничего не писать |
| `--no-gitignore` | `-NoGitignore` | Не трогать `.gitignore` |
| `-h`, `--help` | `-?`, `Get-Help` | Справка |

Идемпотентен: без `--force` не трогает существующее, безопасно запускать повторно.

## Глобальная установка

```bash
install -m755 init-ai-tooling.sh ~/bin/ai-init      # если ~/bin в PATH
# либо алиас:
alias ai-init="/path/to/ai-tooling-starter-kit/init-ai-tooling.sh"
```

## После запуска

1. Заполни `TODO` в **`AGENTS.md`** (стек, структура, статус, безопасность) — все инструменты берут контекст оттуда.
2. При необходимости — доменные правила в `.cursor/rules/*.mdc` и роль в `PERPLEXITY.md`.
3. Коммит: `git add -A && git commit -m "chore: scaffold AI tooling (AGENTS.md model)"`.

## Проекты с уже готовой конвенцией

Скрипт идемпотентен и **не перезаписывает** чужие файлы, но на проекте с собственной
раскладкой (свои `.cursor/rules/*.mdc`, `AGENTS.md`, скиллы) может создать частичное
дублирование (напр. свой `00-project.mdc` рядом с генерик `000-project.mdc`). Такие
проекты стоит свести вручную: сделать их контент основой `AGENTS.md`, убрать дубли.

## Миграция v1 → v2

Если проект был развёрнут по v1 (`.ai/shared-context.md` как хаб): удалить v1-хвосты
и накатить v2 с `--force`:

```bash
rm -f .ai/shared-context.md .cursor/README.md .perplexity/context.md \
      .perplexity/artifacts/README.md .antigravity/rules/000-workspace.md \
      .antigravity/rules/.gitkeep .cursor/rules/.gitkeep
rmdir .antigravity/rules 2>/dev/null || true
init-ai-tooling.sh --name PROJECT --desc "..." --force
```

## Как помочь проекту

Issues и pull request'ы приветствуются — см. [CONTRIBUTING.md](CONTRIBUTING.md).
Главное правило: правку логики нужно вносить **во все три скрипта сразу**, иначе CI
поймает расхождение. О проблемах безопасности — [SECURITY.md](SECURITY.md).

## Лицензия

Распространяется под свободной лицензией [MIT License](LICENSE). Вы можете свободно использовать, модифицировать и встраивать данный стартер-кит в любые коммерческие и открытые проекты.

---
*v2 проверяется в CI: dry-run, реальный прогон, идемпотентность и побайтовое совпадение
результата трёх реализаций (ubuntu + windows-latest, PowerShell 5.1 и 7).*
