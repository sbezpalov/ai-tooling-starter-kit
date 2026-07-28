<#
.SYNOPSIS
    init-ai-tooling.ps1 (1.0.0, AGENTS.md-модель) — PowerShell версия для Windows 11/10.

.DESCRIPTION
    Разворачивает каркас AI-инструментов (Claude, Cursor, Antigravity/Gemini, Perplexity)
    в текущем репозитории. Модель: AGENTS.md = единый источник истины.

.PARAMETER Name
    Имя проекта (по умолчанию — имя текущей папки).

.PARAMETER Desc
    Короткое описание (одна строка).

.PARAMETER Force
    Перезаписывать существующие файлы.

.PARAMETER DryRun
    Показать план, ничего не писать.

.PARAMETER NoGitignore
    Не трогать .gitignore.

.PARAMETER Version
    Показать версию и выйти.

.EXAMPLE
    .\init-ai-tooling.ps1 -Name "my-project" -Desc "Мой проект"
    powershell -ExecutionPolicy Bypass -File .\init-ai-tooling.ps1
#>
#Requires -Version 5.1
[CmdletBinding()]
param (
    [string]$Name = "",
    [string]$Desc = "",
    [switch]$Force,
    [switch]$DryRun,
    [switch]$NoGitignore,
    [switch]$Version
)

# Константа отдельно от -Version: в PowerShell имена переменных case-insensitive.
$ToolVersion = "1.0.0"

$ErrorActionPreference = "Stop"

if ($Version) {
    Write-Host "init-ai-tooling.ps1 $ToolVersion"
    exit 0
}

# Windows PowerShell 5.1 по умолчанию выводит в OEM-кодировке (CP437/CP866) — без этого
# кириллица в сообщениях превратится в "?????". Ошибку глотаем: в некоторых хостах
# (ISE, перенаправленный stdout) присвоение недоступно и это не повод падать.
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

# .NET разрешает относительные пути через [Environment]::CurrentDirectory, который НЕ
# синхронизирован с текущим расположением PowerShell. Без этой строки [System.IO.*]
# писал бы файлы в стартовый каталог процесса, а не туда, куда пользователь сделал cd.
if ($PWD.Provider.Name -ne 'FileSystem') {
    throw ("Запусти скрипт из каталога файловой системы. Текущее расположение: " +
           "$($PWD.Path) (провайдер $($PWD.Provider.Name)).")
}
[Environment]::CurrentDirectory = $PWD.ProviderPath

if ([string]::IsNullOrWhiteSpace($Name)) {
    $Name = (Get-Item -Path .).Name
}
if ([string]::IsNullOrWhiteSpace($Desc)) {
    $Desc = "TODO: короткое описание проекта"
}
$Date = (Get-Date -Format "yyyy-MM-dd")
# Отдельное значение для подстановки внутрь JSON: кавычки и обратные слэши в имени
# проекта иначе сделали бы .claude/settings.json невалидным.
$NameJson = $Name.Replace('\', '\\').Replace('"', '\"')

function Say([string]$msg = "") {
    Write-Host $msg
}

function Write-Utf8LfFile {
    param (
        [string]$Path,
        [string]$Content
    )
    $parent = [System.IO.Path]::GetDirectoryName($Path)
    if ($parent -and -not (Test-Path $parent)) {
        [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    }
    # Нормализуем в LF; непустые файлы — с завершающим \n, как в Python/bash-шаблонах
    # (here-string в PowerShell не всегда сохраняет newline перед закрывающим '@).
    $lfContent = $Content -replace "`r`n", "`n" -replace "`r", "`n"
    if ($lfContent.Length -gt 0 -and -not $lfContent.EndsWith("`n")) {
        $lfContent += "`n"
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $lfContent, $utf8NoBom)
}

function Initialize-Directory {
    param ([string]$Dir)
    if ($DryRun) {
        Say ("mkdir  " + ($Dir -replace "\\", "/"))
    } else {
        if (-not (Test-Path $Dir)) {
            [System.IO.Directory]::CreateDirectory($Dir) | Out-Null
        }
    }
}

function Write-Gitkeep {
    param ([string]$Dir)
    Initialize-Directory $Dir
    $filePath = Join-Path $Dir ".gitkeep"
    if ((Test-Path $filePath) -and -not $Force) {
        return
    }
    if ($DryRun) {
        Say ("touch  " + ($filePath -replace "\\", "/"))
        return
    }
    Write-Utf8LfFile -Path $filePath -Content ""
}

function Write-ProjectFile {
    param (
        [string]$RelPath,
        [string]$Content
    )
    if ((Test-Path $RelPath) -and -not $Force) {
        Say ("skip   " + ($RelPath -replace "\\", "/") + " (уже есть)")
        return
    }
    if ($DryRun) {
        Say ("write  " + ($RelPath -replace "\\", "/"))
        return
    }
    # .Replace() — литеральная замена. -replace трактовал бы $Name/$Desc как строку
    # подстановки regex ($1, $&, $$), что ломало бы описания со знаком доллара.
    $rendered = $Content.Replace("__NAME_JSON__", $NameJson).Replace("__NAME__", $Name).Replace("__DESC__", $Desc).Replace("__DATE__", $Date).Replace("__VERSION__", $ToolVersion)
    Write-Utf8LfFile -Path $RelPath -Content $rendered
    Say ("write  " + ($RelPath -replace "\\", "/"))
}

# 1) каталоги artifacts + .gitkeep
$GitkeepDirs = @(
    ".ai/artifacts",
    ".claude/commands",
    ".claude/agents",
    ".claude/artifacts",
    ".cursor/artifacts",
    ".antigravity/artifacts",
    ".perplexity/artifacts"
)

foreach ($d in $GitkeepDirs) {
    Write-Gitkeep $d
}

# 2) Файлы шаблонов
$AgentsMd = @'
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
'@

$CursorRules = @'
# Cursor читает этот файл для совместимости. ИСТОЧНИК ИСТИНЫ — ./AGENTS.md.
# Детальные правила — в ./.cursor/rules/*.mdc. Прочитай AGENTS.md перед любой работой.
См. AGENTS.md
'@

$CursorRule000 = @'
---
description: Базовый контекст проекта __NAME__ — указывает на AGENTS.md
alwaysApply: true
---

# __NAME__

Источник истины — `../../AGENTS.md` (прочитай целиком). Здесь и в соседних `*.mdc` —
только Cursor-специфика и детальные тематические правила.
'@

$CursorRule010 = @'
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
'@

$CursorIgnore = @'
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
'@

$ClaudeMd = @'
# CLAUDE.md — __NAME__

**Источник истины — [`AGENTS.md`](AGENTS.md). Прочитай его первым.** Ниже — только Claude-специфика.

## Директории Claude
- `.claude/commands/` — slash-команды; `.claude/agents/` — субагенты; `.claude/artifacts/` — артефакты.
- Командные настройки — `.claude/settings.json`; личные — `.claude/settings.local.json` (не коммить).
'@

$ClaudeReadme = @'
# .claude/ — конфигурация Claude Code

Источник истины — [`../AGENTS.md`](../AGENTS.md).

- `commands/` — slash-команды; `agents/` — субагенты; `artifacts/` — артефакты Claude.
- `settings.json` — командные настройки; `settings.local.json` — личные (не коммить).
'@

$ClaudeSettings = @'
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
'@

$GeminiMd = @'
# GEMINI.md — Google Antigravity / Gemini

> Antigravity читает и `AGENTS.md`, и `GEMINI.md`; при конфликте приоритет у `GEMINI.md`.
> **Источник истины по проекту — `AGENTS.md`, прочитай первым.** Здесь — Antigravity/Gemini-специфика.

## Агентный режим
- Работай через план (task/plan): декомпозируй задачу и покажи шаги до исполнения.
- Human-in-the-loop: для правок прод-данных/ядра — остановись и запроси подтверждение.
- Формируй артефакты (diff, список файлов, план отката) до применения; сохраняй в `.antigravity/artifacts/`.
- Не выполняй shell-команды против боевого сервера/БД.
- Изменения атомарные, с объяснением ЧТО и ПОЧЕМУ.
'@

$AntigravityReadme = @'
# .antigravity/ — рабочая область Google Antigravity

Правила — в [`../GEMINI.md`](../GEMINI.md); источник истины — [`../AGENTS.md`](../AGENTS.md).
`artifacts/` — планы, task-list, walkthrough, записи браузера.
'@

$PerplexityMd = @'
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
'@

$PerplexityReadme = @'
# .perplexity/ — Perplexity / research

Бриф для вставки — [`../PERPLEXITY.md`](../PERPLEXITY.md); контекст — [`../AGENTS.md`](../AGENTS.md).
`artifacts/` — сохранённые ресёрч-отчёты (`YYYY-MM-DD-тема.md`; в конце — источники для верификации).
'@

$AiReadme = @'
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
'@

Write-ProjectFile "AGENTS.md" $AgentsMd
Write-ProjectFile ".cursorrules" $CursorRules
Write-ProjectFile ".cursor/rules/000-project.mdc" $CursorRule000
Write-ProjectFile ".cursor/rules/010-safety.mdc" $CursorRule010
Write-ProjectFile ".cursorignore" $CursorIgnore
Write-ProjectFile "CLAUDE.md" $ClaudeMd
Write-ProjectFile ".claude/README.md" $ClaudeReadme
Write-ProjectFile ".claude/settings.json" $ClaudeSettings
Write-ProjectFile "GEMINI.md" $GeminiMd
Write-ProjectFile ".antigravity/README.md" $AntigravityReadme
Write-ProjectFile "PERPLEXITY.md" $PerplexityMd
Write-ProjectFile ".perplexity/README.md" $PerplexityReadme
Write-ProjectFile ".ai/README.md" $AiReadme

# 3) .gitignore
if (-not $NoGitignore) {
    $gitignorePath = ".gitignore"
    $existingLines = @()
    if (Test-Path $gitignorePath) {
        # @(...) обязательно: на файле из одной строки Get-Content вернёт скаляр String,
        # и дальнейший += сконкатенировал бы строки вместо добавления в массив.
        $existingLines = @(Get-Content -Path $gitignorePath -Encoding UTF8)
    }
    $linesToAdd = @(".env", ".env.*", "!.env.example", "*.local", ".claude/settings.local.json", ".DS_Store")
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

    foreach ($line in $linesToAdd) {
        if (-not ($existingLines -ccontains $line)) {
            if ($DryRun) {
                Say "gitignore += $line"
            } else {
                if ((Test-Path $gitignorePath) -and ((Get-Item $gitignorePath).Length -gt 0)) {
                    $rawBytes = [System.IO.File]::ReadAllBytes($gitignorePath)
                    if ($rawBytes[-1] -ne 10) {
                        [System.IO.File]::AppendAllText($gitignorePath, "`n", $utf8NoBom)
                    }
                }
                [System.IO.File]::AppendAllText($gitignorePath, "$line`n", $utf8NoBom)
                $existingLines += $line
            }
        }
    }
}

Say ""
Say "Готово (${ToolVersion}): каркас AGENTS.md-модели развёрнут для «$Name»."
Say "Дальше: заполни TODO в AGENTS.md — все инструменты берут контекст оттуда."
if ($DryRun) {
    Say "(dry-run: ничего не записано)"
}
