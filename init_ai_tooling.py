#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""init_ai_tooling.py (1.0.0, AGENTS.md-модель) — кросс-ОС аналог init-ai-tooling.sh.

Разворачивает каркас AI-инструментов (Claude, Cursor, Antigravity/Gemini, Perplexity)
в текущем репозитории. Модель: AGENTS.md = единый источник истины; тонкие
файлы-редиректы в корне (.cursorrules, CLAUDE.md, GEMINI.md, PERPLEXITY.md); .ai/ —
только под артефакты.

Чистый stdlib (Python 3.6+), без зависимостей. Идемпотентен (без --force не трогает
существующее). Пишет LF-переводы строк на всех ОС. Вывод совпадает с bash-версией.

Использование:
    python3 init_ai_tooling.py [--name ИМЯ] [--desc "ОПИСАНИЕ"] [--force] [--dry-run] [--no-gitignore]
"""
import argparse
import datetime
import os
from pathlib import Path
import sys

VERSION = "1.0.0"

# ---------------------------------------------------------------------------
# Каталоги под артефакты (в них кладём .gitkeep)
# ---------------------------------------------------------------------------
GITKEEP_DIRS = [
    ".ai/artifacts",
    ".claude/commands",
    ".claude/agents",
    ".claude/artifacts",
    ".cursor/artifacts",
    ".antigravity/artifacts",
    ".perplexity/artifacts",
]

# ---------------------------------------------------------------------------
# Шаблоны файлов (плейсхолдеры __NAME__ / __DESC__ / __DATE__ / __VERSION__).
# Порядок = порядок записи (совпадает с bash-версией).
# ---------------------------------------------------------------------------
FILES = []  # список кортежей (path, content)


def _add(path, content):
    FILES.append((path, content))


_add("AGENTS.md", """\
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

<!-- Инициализировано init-ai-tooling __VERSION__ (__DATE__). -->
""")

_add(".cursorrules", """\
# Cursor читает этот файл для совместимости. ИСТОЧНИК ИСТИНЫ — ./AGENTS.md.
# Детальные правила — в ./.cursor/rules/*.mdc. Прочитай AGENTS.md перед любой работой.
См. AGENTS.md
""")

_add(".cursor/rules/000-project.mdc", """\
---
description: Базовый контекст проекта __NAME__ — указывает на AGENTS.md
alwaysApply: true
---

# __NAME__

Источник истины — `../../AGENTS.md` (прочитай целиком). Здесь и в соседних `*.mdc` —
только Cursor-специфика и детальные тематические правила.
""")

_add(".cursor/rules/010-safety.mdc", """\
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
""")

_add(".cursorignore", """\
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
""")

_add("CLAUDE.md", """\
# CLAUDE.md — __NAME__

**Источник истины — [`AGENTS.md`](AGENTS.md). Прочитай его первым.** Ниже — только Claude-специфика.

## Директории Claude
- `.claude/commands/` — slash-команды; `.claude/agents/` — субагенты; `.claude/artifacts/` — артефакты.
- Командные настройки — `.claude/settings.json`; личные — `.claude/settings.local.json` (не коммить).
""")

_add(".claude/README.md", """\
# .claude/ — конфигурация Claude Code

Источник истины — [`../AGENTS.md`](../AGENTS.md).

- `commands/` — slash-команды; `agents/` — субагенты; `artifacts/` — артефакты Claude.
- `settings.json` — командные настройки; `settings.local.json` — личные (не коммить).
""")

_add(".claude/settings.json", """\
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "//": "Командные настройки Claude Code для __NAME_JSON__. Личные оверрайды — в settings.local.json (не коммитить).",
  "permissions": {
    "allow": ["Read", "Edit"],
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(**.pem)",
      "Read(**.key)",
      "Read(**/.ssh/**)",
      "Read(**/.aws/**)",
      "Read(**/.kube/**)",
      "Bash(rm -rf:*)",
      "Bash(git push --force:*)"
    ]
  }
}
""")

_add("GEMINI.md", """\
# GEMINI.md — Google Antigravity / Gemini

> Antigravity читает и `AGENTS.md`, и `GEMINI.md`; при конфликте приоритет у `GEMINI.md`.
> **Источник истины по проекту — `AGENTS.md`, прочитай первым.** Здесь — Antigravity/Gemini-специфика.

## Агентный режим
- Работай через план (task/plan): декомпозируй задачу и покажи шаги до исполнения.
- Human-in-the-loop: для правок прод-данных/ядра — остановись и запроси подтверждение.
- Формируй артефакты (diff, список файлов, план отката) до применения; сохраняй в `.antigravity/artifacts/`.
- Не выполняй shell-команды против боевого сервера/БД.
- Изменения атомарные, с объяснением ЧТО и ПОЧЕМУ.
""")

_add(".antigravity/README.md", """\
# .antigravity/ — рабочая область Google Antigravity

Правила — в [`../GEMINI.md`](../GEMINI.md); источник истины — [`../AGENTS.md`](../AGENTS.md).
`artifacts/` — планы, task-list, walkthrough, записи браузера.
""")

_add("PERPLEXITY.md", """\
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
""")

_add(".perplexity/README.md", """\
# .perplexity/ — Perplexity / research

Бриф для вставки — [`../PERPLEXITY.md`](../PERPLEXITY.md); контекст — [`../AGENTS.md`](../AGENTS.md).
`artifacts/` — сохранённые ресёрч-отчёты (`YYYY-MM-DD-тема.md`; в конце — источники для верификации).
""")

_add(".ai/README.md", """\
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

<!-- Инициализировано init-ai-tooling __VERSION__ (__DATE__). -->
""")

GITIGNORE_LINES = [
    ".env",
    ".env.*",
    "!.env.example",
    "*.local",
    ".claude/settings.local.json",
    ".DS_Store",
]


def say(msg=""):
    print(msg)


def render(text, name, desc, date, version=VERSION):
    # __NAME_JSON__ — имя, экранированное для подстановки внутрь JSON: кавычки и
    # обратные слэши иначе сделали бы .claude/settings.json невалидным.
    name_json = name.replace("\\", "\\\\").replace('"', '\\"')
    return (text.replace("__NAME_JSON__", name_json)
                .replace("__NAME__", name)
                .replace("__DESC__", desc)
                .replace("__DATE__", date)
                .replace("__VERSION__", version))


def main(argv=None):
    p = argparse.ArgumentParser(
        prog="init_ai_tooling.py",
        description="Каркас AI-инструментов (AGENTS.md-модель).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Создаёт: AGENTS.md (источник истины), .cursorrules + .cursor/rules/*.mdc + "
            ".cursorignore, CLAUDE.md + .claude/, GEMINI.md + .antigravity/, "
            "PERPLEXITY.md + .perplexity/, .ai/ (карта + artifacts). "
            "У каждого инструмента папка artifacts/."
        ),
    )
    p.add_argument("--name", default="", help="Имя проекта (по умолчанию — имя папки).")
    p.add_argument("--desc", default="", help="Короткое описание (одна строка).")
    p.add_argument("--force", action="store_true", help="Перезаписывать существующие файлы.")
    p.add_argument("--dry-run", action="store_true", help="Показать план, ничего не писать.")
    p.add_argument("--no-gitignore", action="store_true", help="Не трогать .gitignore.")
    p.add_argument(
        "--version",
        action="version",
        version="%(prog)s " + VERSION,
        help="Показать версию и выйти.",
    )
    args = p.parse_args(argv)

    name = args.name or os.path.basename(os.getcwd())
    desc = args.desc or "TODO: короткое описание проекта"
    date = datetime.date.today().isoformat()
    force, dry = args.force, args.dry_run

    def ensure_dir(d: Path):
        if dry:
            say("mkdir  " + str(d).replace(os.sep, "/"))
        else:
            d.mkdir(parents=True, exist_ok=True)

    def gitkeep(d_str: str):
        p = Path(d_str)
        ensure_dir(p)
        f = p / ".gitkeep"
        if f.exists() and not force:
            return
        if dry:
            say("touch  " + str(f).replace(os.sep, "/"))
            return
        try:
            f.touch()
        except OSError as e:
            say("error  не удалось создать %s: %s" % (f, e))
            sys.exit(1)

    def write_file(path_str: str, content: str):
        p = Path(path_str)
        if p.exists() and not force:
            say("skip   " + path_str + " (уже есть)")
            return
        if dry:
            say("write  " + path_str)
            return
        try:
            p.parent.mkdir(parents=True, exist_ok=True)
            # newline="\n" — LF на всех ОС (в т.ч. Windows), как в bash-версии
            with open(p, "w", encoding="utf-8", newline="\n") as fh:
                fh.write(content)
            say("write  " + path_str)
        except OSError as e:
            say("error  не удалось записать %s: %s" % (path_str, e))
            sys.exit(1)

    # 1) каталоги artifacts + .gitkeep
    for d in GITKEEP_DIRS:
        gitkeep(d)

    # 2) файлы
    for rel, tpl in FILES:
        write_file(rel, render(tpl, name, desc, date))

    # 3) .gitignore
    if not args.no_gitignore:
        gitignore_path = Path(".gitignore")
        existing_lines = []
        if gitignore_path.exists():
            try:
                with open(gitignore_path, "r", encoding="utf-8") as fh:
                    existing_lines = fh.read().splitlines()
            except OSError as e:
                say("warning не удалось прочитать .gitignore: %s" % e)

        for line in GITIGNORE_LINES:
            if line not in existing_lines:
                if dry:
                    say("gitignore += " + line)
                    continue
                try:
                    needs_newline = False
                    if gitignore_path.exists() and gitignore_path.stat().st_size > 0:
                        with open(gitignore_path, "rb") as fh:
                            fh.seek(-1, os.SEEK_END)
                            if fh.read(1) != b"\n":
                                needs_newline = True
                    with open(gitignore_path, "a", encoding="utf-8", newline="\n") as fh:
                        if needs_newline:
                            fh.write("\n")
                            needs_newline = False
                        fh.write(line + "\n")
                    existing_lines.append(line)
                except OSError as e:
                    say("warning не удалось обновить .gitignore: %s" % e)

    say("")
    say("Готово (%s): каркас AGENTS.md-модели развёрнут для «%s»." % (VERSION, name))
    say("Дальше: заполни TODO в AGENTS.md — все инструменты берут контекст оттуда.")
    if dry:
        say("(dry-run: ничего не записано)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
