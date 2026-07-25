#!/usr/bin/env bash
# init-ai-tooling.sh (v2, AGENTS.md-модель) — разворачивает каркас AI-инструментов
# (Claude, Cursor, Antigravity/Gemini, Perplexity) в текущем репозитории.
#
# Модель: AGENTS.md = единый источник истины (его читают нативно Cursor,
# Antigravity/Gemini и др.). Остальное — тонкие файлы-редиректы/специфика в корне
# (.cursorrules, CLAUDE.md, GEMINI.md, PERPLEXITY.md). `.ai/` — только под артефакты.
#
# Идемпотентен (без --force не трогает существующее). Самодостаточен (шаблоны внутри).
set -euo pipefail

NAME=""; DESC=""; FORCE=0; DRYRUN=0; NO_GITIGNORE=0

usage() {
  cat <<'USAGE'
init-ai-tooling.sh (v2) — каркас AI-инструментов (AGENTS.md-модель).

Использование:
  init-ai-tooling.sh [--name ИМЯ] [--desc "ОПИСАНИЕ"] [--force] [--dry-run] [--no-gitignore]

Опции:
  --name ИМЯ        Имя проекта (по умолчанию — имя папки).
  --desc ТЕКСТ      Короткое описание (одна строка).
  --force           Перезаписывать существующие файлы.
  --dry-run         Показать план, ничего не писать.
  --no-gitignore    Не трогать .gitignore.
  -h, --help        Справка.

Создаёт:
  AGENTS.md                ★ источник истины (проект + правила для агентов)
  .cursorrules             редирект → AGENTS.md (legacy Cursor)
  .cursor/rules/*.mdc      детальные правила (000-project, 010-safety) + .cursorignore
  CLAUDE.md                редирект → AGENTS.md (Claude Code / Cowork)
  GEMINI.md                Antigravity/Gemini-специфика (приоритет при конфликте)
  PERPLEXITY.md            вставляемый бриф для Perplexity / research-агентов
  .ai/                     карта раскладки + кросс-инструментальные артефакты
  .claude/ .cursor/ .antigravity/ .perplexity/  — папки artifacts/ каждого инструмента
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --name) NAME="${2:-}"; shift 2 ;;
    --desc) DESC="${2:-}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRYRUN=1; shift ;;
    --no-gitignore) NO_GITIGNORE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Неизвестная опция: $1" >&2; usage; exit 2 ;;
  esac
done

[ -n "$NAME" ] || NAME="$(basename "$(pwd)")"
[ -n "$DESC" ] || DESC="TODO: короткое описание проекта"
DATE="$(date +%Y-%m-%d)"

say() { printf '%s\n' "$*"; }
ensure_dir() { [ "$DRYRUN" = "1" ] && { say "mkdir  $1"; return 0; }; mkdir -p "$1"; }
gitkeep() {
  ensure_dir "$1"; local f="$1/.gitkeep"
  [ -e "$f" ] && [ "$FORCE" != "1" ] && return 0
  [ "$DRYRUN" = "1" ] && { say "touch  $f"; return 0; }
  : > "$f"
}
write_file() {
  local path="$1"
  if [ -e "$path" ] && [ "$FORCE" != "1" ]; then say "skip   $path (уже есть)"; cat >/dev/null; return 0; fi
  if [ "$DRYRUN" = "1" ]; then say "write  $path"; cat >/dev/null; return 0; fi
  mkdir -p "$(dirname "$path")"; cat > "$path"; say "write  $path"
}
escape_sed() {
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}
render() {
  local safe_name safe_desc safe_date
  safe_name="$(escape_sed "$NAME")"
  safe_desc="$(escape_sed "$DESC")"
  safe_date="$(escape_sed "$DATE")"
  sed -e "s|__NAME__|${safe_name}|g" -e "s|__DESC__|${safe_desc}|g" -e "s|__DATE__|${safe_date}|g"
}

# ---------- каталоги artifacts + .gitkeep ----------
for d in .ai/artifacts .claude/commands .claude/agents .claude/artifacts \
         .cursor/artifacts .antigravity/artifacts .perplexity/artifacts; do
  gitkeep "$d"
done

# ======================================================================
# AGENTS.md — ИСТОЧНИК ИСТИНЫ
# ======================================================================
render <<'TPL' | write_file "AGENTS.md"
# AGENTS.md — __NAME__

> **Источник истины для всех AI-инструментов и людей в этом репозитории.**
> Файл читают нативно Cursor, Google Antigravity/Gemini и другие AGENTS-совместимые
> инструменты. Тонкие редиректы (`.cursorrules`, `CLAUDE.md`, `GEMINI.md`,
> `PERPLEXITY.md`) дополняют, но не отменяют эти правила. **Прочитай целиком перед работой.**

## 1. Проект
__DESC__

<!-- TODO: 2–4 предложения — назначение, пользователи, ценность. -->

## 2. Стек
<!-- TODO: языки, фреймворки, БД, инфраструктура. -->

## 3. Структура
<!-- TODO: таблица «каталог → назначение». -->

## 4. Статус / текущий приоритет
<!-- TODO: где сейчас проект, на чём фокус. -->

## 5. Как вносить изменения (агент)
- Работай через план: декомпозируй задачу и покажи шаги ДО исполнения.
- Human-in-the-loop: для необратимых операций и правок прод-данных — остановись и спроси.
- Формируй артефакты (diff, список изменённых файлов, план отката) до применения.
- Изменения атомарные; объясняй ЧТО и ПОЧЕМУ.
- Новый код — с тестами; задача не «done» при падающих тестах/линте.

## 6. Безопасность (NEVER)
- Прод не редактируется напрямую <!-- TODO: маршрут доставки, напр. local → staging → prod через git -->.
- Секреты (пароли, ключи, токены, `.env`, локальные конфиги) — не коммитить и не выводить;
  в репозитории только `*.example`.
- Деструктивные операции над боевыми данными/БД — только с явным подтверждением и прогоном на копии.
- <!-- TODO: проектные запреты (не трогать ядро/…). -->

## 7. Definition of Done
- [ ] Изменение локально; секреты не попали в код/коммит.
- [ ] Тесты/линт зелёные; при необходимости проверено на staging.
- [ ] Diff отревьюен, есть план отката.

## Раскладка инструментов
Артефакты — в `.ai/artifacts/` (кросс) и `.<инструмент>/artifacts/`. Детали — `.ai/README.md`.

<!-- Инициализировано init-ai-tooling.sh v2 (__DATE__). -->
TPL

# ======================================================================
# .cursorrules — редирект
# ======================================================================
render <<'TPL' | write_file ".cursorrules"
# Cursor читает этот файл для совместимости. ИСТОЧНИК ИСТИНЫ — ./AGENTS.md.
# Детальные правила — в ./.cursor/rules/*.mdc. Прочитай AGENTS.md перед любой работой.
См. AGENTS.md
TPL

# .cursor/rules/000-project.mdc
render <<'TPL' | write_file ".cursor/rules/000-project.mdc"
---
description: Базовый контекст проекта __NAME__ — указывает на AGENTS.md
alwaysApply: true
---

# __NAME__

Источник истины — `../../AGENTS.md` (прочитай целиком). Здесь и в соседних `*.mdc` —
только Cursor-специфика и детальные тематические правила.
TPL

# .cursor/rules/010-safety.mdc
render <<'TPL' | write_file ".cursor/rules/010-safety.mdc"
---
description: Безопасность, секреты, работа с продом
alwaysApply: true
---

# Безопасность

- Секреты (пароли, ключи, токены, `.env`, локальные конфиги) — не в код, коммиты или контекст.
- Прод не редактируется напрямую; деструктивные операции над боевыми данными — только
  с явным подтверждением и прогоном на копии.
- Перед рискованной правкой — покажи diff и план отката, спроси подтверждение.
- Полные правила — в `../../AGENTS.md`.
TPL

# .cursorignore
render <<'TPL' | write_file ".cursorignore"
# Секреты и локальный конфиг
.env
*.local

# Артефакты сборки и данные
dist/
build/
*.egg-info/

# Окружения и кэши
.venv/
venv/
node_modules/
__pycache__/
*.py[cod]
.pytest_cache/
.mypy_cache/
.ruff_cache/

.DS_Store
TPL

# ======================================================================
# CLAUDE.md — редирект + Claude-специфика
# ======================================================================
render <<'TPL' | write_file "CLAUDE.md"
# CLAUDE.md — __NAME__

**Источник истины — [`AGENTS.md`](AGENTS.md). Прочитай его первым.** Ниже — только Claude-специфика.

## Директории Claude
- `.claude/commands/` — slash-команды; `.claude/agents/` — субагенты; `.claude/artifacts/` — артефакты.
- Командные настройки — `.claude/settings.json`; личные — `.claude/settings.local.json` (не коммить).
TPL

# .claude/README.md
render <<'TPL' | write_file ".claude/README.md"
# .claude/ — конфигурация Claude Code

Источник истины — [`../AGENTS.md`](../AGENTS.md).

- `commands/` — slash-команды; `agents/` — субагенты; `artifacts/` — артефакты Claude.
- `settings.json` — командные настройки; `settings.local.json` — личные (не коммить).
TPL

# .claude/settings.json
render <<'TPL' | write_file ".claude/settings.json"
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "//": "Командные настройки Claude Code для __NAME__. Личные оверрайды — в settings.local.json (не коммитить).",
  "permissions": { "allow": ["Read", "Edit"], "deny": [] }
}
TPL

# ======================================================================
# GEMINI.md — Antigravity/Gemini
# ======================================================================
render <<'TPL' | write_file "GEMINI.md"
# GEMINI.md — Google Antigravity / Gemini

> Antigravity читает и `AGENTS.md`, и `GEMINI.md`; при конфликте приоритет у `GEMINI.md`.
> **Источник истины по проекту — `AGENTS.md`, прочитай первым.** Здесь — Antigravity/Gemini-специфика.

## Агентный режим
- Работай через план (task/plan): декомпозируй задачу и покажи шаги до исполнения.
- Human-in-the-loop: для правок прод-данных/ядра — остановись и запроси подтверждение.
- Формируй артефакты (diff, список файлов, план отката) до применения; сохраняй в `.antigravity/artifacts/`.
- Не выполняй shell-команды против боевого сервера/БД.
- Изменения атомарные, с объяснением ЧТО и ПОЧЕМУ.
TPL

render <<'TPL' | write_file ".antigravity/README.md"
# .antigravity/ — рабочая область Google Antigravity

Правила — в [`../GEMINI.md`](../GEMINI.md); источник истины — [`../AGENTS.md`](../AGENTS.md).
`artifacts/` — планы, task-list, walkthrough, записи браузера.
TPL

# ======================================================================
# PERPLEXITY.md — бриф
# ======================================================================
render <<'TPL' | write_file "PERPLEXITY.md"
# PERPLEXITY.md — бриф для Perplexity / research-агентов

> У Perplexity нет нативного конфига репозитория. Этот файл — **брифинг**: вставь его в
> промпт / Space (или Comet), чтобы задать роль, контекст и границы. Контекст проекта — из `AGENTS.md`.

## Роль
Исследовательский/контент-ассистент проекта __NAME__.
<!-- TODO: уточни роль; пишет ли код; есть ли доступ к данным. -->

## Для чего использовать
<!-- TODO: ресёрч, факт-чек, черновики, конкурентный анализ. -->

## Границы
- Указывай источники для фактов; не выдумывай — помечай «уточнить».
- <!-- TODO: доменные ограничения (реклама/медицина/юр. и т.п.). -->

## Формат выдачи
Структурированно (Markdown/таблица), удобно для переноса. Сохраняй как артефакт в `.perplexity/artifacts/`.
TPL

render <<'TPL' | write_file ".perplexity/README.md"
# .perplexity/ — Perplexity / research

Бриф для вставки — [`../PERPLEXITY.md`](../PERPLEXITY.md); контекст — [`../AGENTS.md`](../AGENTS.md).
`artifacts/` — сохранённые ресёрч-отчёты (`YYYY-MM-DD-тема.md`; в конце — источники для верификации).
TPL

# ======================================================================
# .ai/README.md — карта раскладки
# ======================================================================
render <<'TPL' | write_file ".ai/README.md"
# .ai/ — раскладка AI-инструментов

**Источник истины — [`../AGENTS.md`](../AGENTS.md)** (читается нативно Cursor,
Antigravity/Gemini и др.). Остальные файлы — тонкие редиректы/специфика.

| Инструмент | Файл | Артефакты |
|---|---|---|
| Все агенты | `AGENTS.md` | `.ai/artifacts/` |
| Cursor | `.cursorrules` → AGENTS.md; `.cursor/rules/*.mdc`; `.cursorignore` | `.cursor/artifacts/` |
| Claude (Code / Cowork) | `CLAUDE.md` → AGENTS.md; `.claude/` | `.claude/artifacts/` |
| Antigravity / Gemini | `GEMINI.md` (+ AGENTS.md) | `.antigravity/artifacts/` |
| Perplexity | `PERPLEXITY.md` (вставляемый бриф) | `.perplexity/artifacts/` |

## Правило
Меняется проект → правь **`AGENTS.md`**. Инструмент-специфика — в файле инструмента.
Артефакт — сохраняемый результат, переживающий сессию (план, ресёрч, diff, task-list).

<!-- Инициализировано init-ai-tooling.sh v2 (__DATE__). -->
TPL

# ---------- .gitignore ----------
if [ "$NO_GITIGNORE" != "1" ]; then
  ensure_add_ignore() {
    local line="$1"
    [ "$DRYRUN" = "1" ] && { say "gitignore += $line"; return 0; }
    touch .gitignore
    if ! grep -qxF "$line" .gitignore; then
      if [ -s .gitignore ] && [ -n "$(tail -c1 .gitignore 2>/dev/null)" ]; then
        printf '\n' >> .gitignore
      fi
      printf '%s\n' "$line" >> .gitignore
    fi
  }
  ensure_add_ignore ".claude/settings.local.json"
  ensure_add_ignore ".DS_Store"
fi

say ""
say "Готово (v2): каркас AGENTS.md-модели развёрнут для «${NAME}»."
say "Дальше: заполни TODO в AGENTS.md — все инструменты берут контекст оттуда."
[ "$DRYRUN" = "1" ] && say "(dry-run: ничего не записано)"
exit 0
