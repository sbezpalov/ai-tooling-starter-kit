# Запрос для Cursor (запускать на Windows)

> Скопируй всё, что ниже разделителя, в чат Cursor, открытый на папке репозитория
> `ai-tooling-starter-kit` на Windows-машине.
>
> **Перед этим** убедись, что на Windows лежит актуальная версия файлов:
> `init-ai-tooling.ps1`, `init-ai-tooling.sh`, `init_ai_tooling.py`, `README.md`,
> `.gitattributes`, `.github/workflows/ci.yml`, `tests/compare-trees.py`.
> Проще всего — закоммитить и запушить их с Mac, затем `git pull` на Windows.
> Если тянешь через `git`, проверь, что `.gitattributes` уже в дереве: он задаёт
> `*.ps1 text eol=crlf`, и без него checkout может дать не те переводы строк.

---

## Задача

В репозитории три скрипта — `init-ai-tooling.sh` (bash), `init_ai_tooling.py` (Python),
`init-ai-tooling.ps1` (PowerShell). Они разворачивают одинаковый каркас конфигов для
AI-инструментов и **обязаны давать байт-в-байт идентичный результат**.

PowerShell-версия до сих пор **не запускалась ни на одной живой машине** — она
проверялась только статическим анализом. В ней недавно исправляли серию багов.
Твоя задача — выполнить её на настоящей Windows и подтвердить или опровергнуть,
что исправления работают.

Работай строго по шагам ниже. **Ничего не правь без моего согласия** — сначала
собери полный отчёт. Если шаг падает, зафиксируй это и переходи к следующему.

## Предусловия

```powershell
$PSVersionTable.PSVersion          # какой хост запущен
python --version                   # нужен Python 3
Get-Command powershell, pwsh -EA 0 # нужны ОБЕ оболочки
```

Если `pwsh` нет: `winget install --id Microsoft.PowerShell -e`.
Bash на Windows **не нужен** — эталоном служит Python-версия.

Все прогоны выполни **дважды**: сначала в `powershell` (встроенный Windows
PowerShell 5.1 — именно им пользуется большинство), потом в `pwsh` (PowerShell 7+).
Указывай в отчёте, какой хост давал какой результат.

---

## Шаг 1. Статика — до любого запуска

```powershell
$repo = (Get-Location).Path
$script = Join-Path $repo 'init-ai-tooling.ps1'

# 1a. BOM обязателен. Без него Windows PowerShell 5.1 читает .ps1 в ANSI-кодовой
#     странице, кириллица распадается на байты, часть которых в CP1251/CP1252 —
#     типографские кавычки. PowerShell считает их разделителями строк, и файл
#     перестаёт парситься целиком.
$b = [System.IO.File]::ReadAllBytes($script)
'{0:X2} {1:X2} {2:X2}' -f $b[0], $b[1], $b[2]     # ОЖИДАЕТСЯ: EF BB BF

# 1b. Файл должен парситься БЕЗ выполнения. Это прямая проверка бага выше.
$errs = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$null, [ref]$errs)
if ($errs) { $errs | Format-List } else { 'парсится без ошибок' }   # ОЖИДАЕТСЯ: без ошибок

# 1c. Статический анализатор
Install-Module PSScriptAnalyzer -Force -Scope CurrentUser -SkipPublisherCheck
Invoke-ScriptAnalyzer -Path $script | Format-Table -AutoSize
# ОЖИДАЕТСЯ: ни одной записи с Severity = Error. Warning допустимы — выпиши какие.
```

**Особо важно шаг 1b выполнить именно в `powershell` (5.1), а не только в `pwsh`.**
Под PowerShell 7 этот баг не воспроизводится в принципе, поэтому «в pwsh всё ок» ничего не доказывает.

---

## Шаг 2. `-DryRun` не должен ничего писать

```powershell
$dry = Join-Path $env:TEMP 'kit-dry'
Remove-Item $dry -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $dry | Out-Null
Push-Location $dry
& $script -Name ci-demo -Desc "CI" -DryRun
(Get-ChildItem -Force).Count       # ОЖИДАЕТСЯ: 0
Pop-Location
```

Заодно посмотри на сам вывод: сообщения должны быть **читаемой кириллицей**.
Если видишь `??????` — это баг кодировки консоли, зафиксируй.

---

## Шаг 3. Главный тест — запуск после `Set-Location`

Здесь проверяется самый опасный из исправленных багов: `.NET` разрешает относительные
пути через `[Environment]::CurrentDirectory`, который **не синхронизирован** с
расположением PowerShell. До фикса скрипт вываливал каркас в стартовый каталог
процесса (обычно домашнюю папку) вместо целевого.

```powershell
$psTree = Join-Path $env:TEMP 'kit-ps'
Remove-Item $psTree -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $psTree | Out-Null

Set-Location $psTree                       # именно Set-Location, не Push-Location
& $script -Name ci-demo -Desc "CI"

# 3a. Файлы обязаны появиться ИМЕННО здесь
(Get-ChildItem -Recurse -Force -File).Count       # ОЖИДАЕТСЯ: 21

# 3b. И НЕ должны появиться в домашней папке
Test-Path (Join-Path $HOME 'AGENTS.md')           # ОЖИДАЕТСЯ: False
Test-Path (Join-Path $HOME '.cursorrules')        # ОЖИДАЕТСЯ: False
Test-Path 'C:\AGENTS.md'                          # ОЖИДАЕТСЯ: False
```

Если 3b дал `True` — **немедленно останови проверку и сообщи мне**, скрипт мусорит
в домашней папке. Ничего не удаляй сам, я скажу что делать.

---

## Шаг 4. Переводы строк — обязан быть LF даже на Windows

Файл `.ps1` в рабочем дереве лежит в CRLF (так задано в `.gitattributes`), но
записывать он обязан LF — за это отвечает функция `Write-Utf8LfFile`.

```powershell
foreach ($f in @('AGENTS.md', 'CLAUDE.md', '.cursorrules', '.claude\settings.json')) {
    $bytes = [System.IO.File]::ReadAllBytes((Join-Path $psTree $f))
    $cr = ($bytes | Where-Object { $_ -eq 13 }).Count
    "{0,-24} CR-байтов: {1}" -f $f, $cr        # ОЖИДАЕТСЯ: 0 у всех
}
```

Также проверь, что сгенерированный markdown содержит **обычные обратные апострофы**
и в нём нет управляющих символов (был баг, вставлявший BEL `0x07`):

```powershell
Get-Content (Join-Path $psTree '.claude\README.md') -Raw | Set-Variable md
$md                                                      # глазами: `commands/`, `agents/`, `artifacts/`
([int[]][char[]]$md | Where-Object { $_ -lt 32 -and $_ -ne 10 }).Count   # ОЖИДАЕТСЯ: 0
```

---

## Шаг 5. Эквивалентность с эталоном

Python-версия работает на Windows и служит эталоном.

```powershell
$pyTree = Join-Path $env:TEMP 'kit-py'
Remove-Item $pyTree -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $pyTree | Out-Null
Set-Location $pyTree
python (Join-Path $repo 'init_ai_tooling.py') --name ci-demo --desc "CI"

Set-Location $repo
python .\tests\compare-trees.py $psTree $pyTree
# ОЖИДАЕТСЯ: "Деревья идентичны: 21 файлов." и код возврата 0
```

Если вывелись расхождения — **приведи их полностью**, а для каждого различающегося
файла покажи первые 40 строк обеих версий, чтобы было видно характер расхождения.

---

## Шаг 6. Идемпотентность и `-Force`

```powershell
Set-Location $psTree
& $script -Name ci-demo -Desc "CI"        # ОЖИДАЕТСЯ: везде "skip ... (уже есть)"
Set-Location $repo
python .\tests\compare-trees.py $psTree $pyTree   # ОЖИДАЕТСЯ: по-прежнему идентичны

Set-Location $psTree
& $script -Name ci-demo -Desc "CI" -Force # ОЖИДАЕТСЯ: везде "write ..."
Set-Location $repo
python .\tests\compare-trees.py $psTree $pyTree   # ОЖИДАЕТСЯ: по-прежнему идентичны
```

---

## Шаг 7. `.gitignore` из одной строки — тест на дубли

`Get-Content` на файле из одной строки возвращает скаляр, а не массив; из-за этого
`+=` конкатенировал строки, и проверка «уже есть» переставала работать.

```powershell
$gi = Join-Path $env:TEMP 'kit-gitignore'
Remove-Item $gi -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $gi | Out-Null
Set-Location $gi
[System.IO.File]::WriteAllText((Join-Path $gi '.gitignore'), "*.local`n")

& $script -Name x | Out-Null
Get-Content .\.gitignore
# ОЖИДАЕТСЯ ровно 6 строк без повторов:
#   *.local  /  .env  /  .env.*  /  !.env.example  /  .claude/settings.local.json  /  .DS_Store
#   (порядок: сначала уже бывшая *.local, затем добавленные)
(Get-Content .\.gitignore | Group-Object | Where-Object Count -gt 1)   # ОЖИДАЕТСЯ: пусто

& $script -Name x | Out-Null       # второй прогон — дублей тоже быть не должно
(Get-Content .\.gitignore).Count   # ОЖИДАЕТСЯ: то же число, что и было
```

Повтори тот же тест с **пустым** `.gitignore` (`[System.IO.File]::WriteAllText($p, "")`)
и с **отсутствующим** `.gitignore`.

---

## Шаг 8. Спецсимволы в имени проекта

```powershell
$js = Join-Path $env:TEMP 'kit-json'
Remove-Item $js -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $js | Out-Null
Set-Location $js
& $script -Name 'my "cool" a\b proj' -Desc 'цена $5 и $& символы' | Out-Null

# 8a. settings.json обязан остаться валидным JSON
python -c "import json;d=json.load(open('.claude/settings.json'));print(d['//'])"

# 8b. $-символы в описании не должны потеряться (был баг: -replace трактовал их
#     как regex-подстановку)
Select-String -Path .\AGENTS.md -Pattern 'цена \$5 и \$& символы' -SimpleMatch
# ОЖИДАЕТСЯ: строка найдена целиком
```

---

## Шаг 9. Отказ вне файловой системы

```powershell
Set-Location Cert:\
& $script -Name x
# ОЖИДАЕТСЯ: понятная ошибка «Запусти скрипт из каталога файловой системы…»
# НЕ ожидается: тихое создание файлов в корне C:\
Set-Location C:\
Test-Path 'C:\AGENTS.md'          # ОЖИДАЕТСЯ: False
Set-Location $repo
```

---

## Шаг 10. Уборка

```powershell
foreach ($p in 'kit-dry','kit-ps','kit-py','kit-gitignore','kit-json') {
    Remove-Item (Join-Path $env:TEMP $p) -Recurse -Force -ErrorAction SilentlyContinue
}
```

---

## Формат отчёта

Верни таблицу: шаг → хост (`powershell 5.1` / `pwsh 7`) → PASS/FAIL → фактический вывод
(коротко). Для каждого FAIL приведи полный текст ошибки и точный номер строки в
`init-ai-tooling.ps1`, если он известен.

В конце — общий вердикт одной строкой: можно ли выпускать PowerShell-версию
для публичного использования, или её лучше убрать из репозитория до починки.

**Правки не вноси**, пока я не посмотрю отчёт.
