# AI Tooling Starter Kit (v2 — AGENTS.md-модель)

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

## Две версии — один результат

В ките два эквивалентных скрипта (идентичный вывод, те же флаги, LF-переводы строк):

- `init-ai-tooling.sh` — bash (macOS/Linux).
- `init_ai_tooling.py` — Python 3.6+, чистый stdlib (кросс-ОС, в т.ч. **Windows**).

## Использование

```bash
# macOS / Linux
/path/to/init-ai-tooling.sh --name my-project --desc "Что это за проект"

# Любая ОС (Windows/macOS/Linux), Python без зависимостей
python3 /path/to/init_ai_tooling.py --name my-project --desc "Что это за проект"
#   Windows PowerShell:  python .\init_ai_tooling.py --name my-project --desc "..."
```

| Опция | Значение |
|-------|----------|
| `--name ИМЯ` | Имя проекта (по умолчанию — имя папки) |
| `--desc "ТЕКСТ"` | Короткое описание (одна строка) |
| `--force` | Перезаписывать существующие файлы |
| `--dry-run` | Показать план, ничего не писать |
| `--no-gitignore` | Не трогать `.gitignore` |
| `-h`, `--help` | Справка |

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

---
*v2 проверено: dry-run, реальный прогон, идемпотентность.*
