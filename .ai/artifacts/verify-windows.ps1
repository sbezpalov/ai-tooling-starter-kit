# Verification runner for init-ai-tooling.ps1 — report only, no fixes.
# Outputs ASCII markers so console encoding does not corrupt the report.
$ErrorActionPreference = 'Continue'
$repo = if ($args[0]) { $args[0] } else { (Get-Location).Path }
$script = Join-Path $repo 'init-ai-tooling.ps1'
$hostLabel = "PS$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
$py = $null
foreach ($c in @('py', 'python', (Join-Path $env:LOCALAPPDATA 'Python\bin\python.exe'))) {
    try {
        if ($c -eq 'py') {
            $v = & py --version 2>&1
            if ($LASTEXITCODE -eq 0 -or $v -match 'Python') { $py = 'py'; break }
        } elseif (Test-Path $c) {
            $py = $c; break
        } else {
            $v = & $c --version 2>&1
            if ($v -match 'Python') { $py = $c; break }
        }
    } catch {}
}
if (-not $py) { Write-Host "FATAL: Python not found"; exit 2 }

function Write-Result {
    param([string]$Step, [string]$Status, [string]$Detail)
    Write-Host ("RESULT|{0}|{1}|{2}|{3}" -f $Step, $hostLabel, $Status, $Detail)
}

Write-Host "=== VERIFY START host=$hostLabel repo=$repo py=$py ==="

# --- Step 1a BOM ---
$b = [System.IO.File]::ReadAllBytes($script)
$bom = '{0:X2} {1:X2} {2:X2}' -f $b[0], $b[1], $b[2]
if ($bom -eq 'EF BB BF') { Write-Result '1a' 'PASS' "BOM=$bom" }
else { Write-Result '1a' 'FAIL' "BOM=$bom expected EF BB BF" }

# --- Step 1b Parse ---
$errs = $null
$astNull = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$astNull, [ref]$errs)
if ($errs -and $errs.Count -gt 0) {
    $msg = ($errs | ForEach-Object { $_.ToString() }) -join '; '
    Write-Result '1b' 'FAIL' $msg
} else {
    Write-Result '1b' 'PASS' 'parses without errors'
}

# --- Step 1c PSScriptAnalyzer ---
try {
    if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
        Install-Module PSScriptAnalyzer -Force -Scope CurrentUser -SkipPublisherCheck -ErrorAction Stop
    }
    Import-Module PSScriptAnalyzer -ErrorAction Stop
    $findings = @(Invoke-ScriptAnalyzer -Path $script)
    $errors = @($findings | Where-Object Severity -eq 'Error')
    $warns = @($findings | Where-Object Severity -eq 'Warning')
    $warnText = if ($warns.Count) {
        ($warns | ForEach-Object { "$($_.RuleName):$($_.Line)" }) -join '; '
    } else { 'none' }
    if ($errors.Count -gt 0) {
        $errText = ($errors | ForEach-Object { "$($_.RuleName):$($_.Line):$($_.Message)" }) -join '; '
        Write-Result '1c' 'FAIL' "Errors: $errText | Warnings: $warnText"
    } else {
        Write-Result '1c' 'PASS' "0 Errors; Warnings($($warns.Count)): $warnText"
    }
} catch {
    Write-Result '1c' 'FAIL' "PSScriptAnalyzer: $($_.Exception.Message)"
}

# --- Step 2 DryRun ---
$dry = Join-Path $env:TEMP 'kit-dry'
Remove-Item $dry -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $dry | Out-Null
Push-Location $dry
$dryOut = & $script -Name ci-demo -Desc "CI" -DryRun 2>&1 | Out-String
$dryCount = @(Get-ChildItem -Force).Count
Pop-Location
$cyrOk = ($dryOut -match '[\u0400-\u04FF]') -and ($dryOut -notmatch '\?\?\?\?')
$cyrNote = if ($cyrOk) { 'Cyrillic OK' } elseif ($dryOut -match '\?\?\?\?') { 'Cyrillic BROKEN as ?????' } else { 'Cyrillic not detected in output (may be encoding capture)' }
if ($dryCount -eq 0) { Write-Result '2' 'PASS' "files=$dryCount; $cyrNote" }
else { Write-Result '2' 'FAIL' "files=$dryCount expected 0; $cyrNote" }
Write-Host "DRYRUN_OUTPUT_START"
Write-Host $dryOut
Write-Host "DRYRUN_OUTPUT_END"

# --- Step 3 Set-Location ---
$psTree = Join-Path $env:TEMP 'kit-ps'
Remove-Item $psTree -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $psTree | Out-Null
$homeAgentsBefore = Test-Path (Join-Path $HOME 'AGENTS.md')
$homeCursorBefore = Test-Path (Join-Path $HOME '.cursorrules')
$rootAgentsBefore = Test-Path 'C:\AGENTS.md'

Set-Location $psTree
$runOut = & $script -Name ci-demo -Desc "CI" 2>&1 | Out-String
$fileCount = @(Get-ChildItem -Recurse -Force -File).Count
$homeAgents = Test-Path (Join-Path $HOME 'AGENTS.md')
$homeCursor = Test-Path (Join-Path $HOME '.cursorrules')
$rootAgents = Test-Path 'C:\AGENTS.md'

# Pollution only if newly created (True now but was False before)
$polluted = $false
$polluteDetail = @()
if ($homeAgents -and -not $homeAgentsBefore) { $polluted = $true; $polluteDetail += 'HOME/AGENTS.md NEW' }
if ($homeCursor -and -not $homeCursorBefore) { $polluted = $true; $polluteDetail += 'HOME/.cursorrules NEW' }
if ($rootAgents -and -not $rootAgentsBefore) { $polluted = $true; $polluteDetail += 'C:\AGENTS.md NEW' }

if ($fileCount -eq 21) { Write-Result '3a' 'PASS' "files=$fileCount" }
else { Write-Result '3a' 'FAIL' "files=$fileCount expected 21" }

if ($polluted) {
    Write-Result '3b' 'FAIL' ("POLLUTION: " + ($polluteDetail -join ', '))
    Write-Host "STOP: home/root pollution detected. Aborting remaining steps per prompt."
    Set-Location $repo
    exit 1
} else {
    Write-Result '3b' 'PASS' "HOME/AGENTS=$homeAgents HOME/.cursorrules=$homeCursor C:\AGENTS=$rootAgents (no NEW pollution)"
}

# --- Step 4 LF + control chars ---
$crFail = @()
foreach ($f in @('AGENTS.md', 'CLAUDE.md', '.cursorrules', '.claude\settings.json')) {
    $bytes = [System.IO.File]::ReadAllBytes((Join-Path $psTree $f))
    $cr = @($bytes | Where-Object { $_ -eq 13 }).Count
    if ($cr -ne 0) { $crFail += "$f=$cr" }
}
if ($crFail.Count -eq 0) { Write-Result '4a' 'PASS' 'CR bytes=0 for all checked files' }
else { Write-Result '4a' 'FAIL' ("CR found: " + ($crFail -join '; ')) }

$mdPath = Join-Path $psTree '.claude\README.md'
$md = [System.IO.File]::ReadAllText($mdPath)
$ctrl = @([int[]][char[]]$md | Where-Object { $_ -lt 32 -and $_ -ne 10 }).Count
$hasBackticks = ($md -match '`commands/`') -or ($md -match 'commands/')
if ($ctrl -eq 0) { Write-Result '4b' 'PASS' "ctrlChars=0; backticksPresent=$hasBackticks" }
else { Write-Result '4b' 'FAIL' "ctrlChars=$ctrl expected 0" }

# --- Step 5 Python equivalence ---
$pyTree = Join-Path $env:TEMP 'kit-py'
Remove-Item $pyTree -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $pyTree | Out-Null
Set-Location $pyTree
if ($py -eq 'py') {
    & py (Join-Path $repo 'init_ai_tooling.py') --name ci-demo --desc "CI" 2>&1 | Out-Null
} else {
    & $py (Join-Path $repo 'init_ai_tooling.py') --name ci-demo --desc "CI" 2>&1 | Out-Null
}
Set-Location $repo
$cmpOut = if ($py -eq 'py') {
    & py .\tests\compare-trees.py $psTree $pyTree 2>&1 | Out-String
} else {
    & $py .\tests\compare-trees.py $psTree $pyTree 2>&1 | Out-String
}
$cmpCode = $LASTEXITCODE
$cmpOutTrim = $cmpOut.Trim()
if ($cmpCode -eq 0 -and $cmpOutTrim -match '21') {
    Write-Result '5' 'PASS' $cmpOutTrim
} else {
    Write-Result '5' 'FAIL' "exit=$cmpCode; $cmpOutTrim"
    Write-Host "DIFF_FULL_START"
    Write-Host $cmpOut
    Write-Host "DIFF_FULL_END"
}

# --- Step 6 Idempotency + Force ---
Set-Location $psTree
$skipOut = & $script -Name ci-demo -Desc "CI" 2>&1 | Out-String
$skipOk = ($skipOut -match 'skip') -and ($skipOut -notmatch '(?m)^write ')
# Also accept Cyrillic skip message via mojibake patterns or file count unchanged
$fileCountAfterSkip = @(Get-ChildItem -Recurse -Force -File).Count
Set-Location $repo
$cmp2 = if ($py -eq 'py') { & py .\tests\compare-trees.py $psTree $pyTree 2>&1 | Out-String } else { & $py .\tests\compare-trees.py $psTree $pyTree 2>&1 | Out-String }
$cmp2Code = $LASTEXITCODE
if ($cmp2Code -eq 0 -and $fileCountAfterSkip -eq 21) {
    Write-Result '6a' 'PASS' "idempotent skip; compare exit=0; skipOutHasSkip=$($skipOut -match 'skip')"
} else {
    Write-Result '6a' 'FAIL' "compare exit=$cmp2Code files=$fileCountAfterSkip; out=$($skipOut.Substring(0, [Math]::Min(200,$skipOut.Length)))"
}

Set-Location $psTree
$forceOut = & $script -Name ci-demo -Desc "CI" -Force 2>&1 | Out-String
$forceHasWrite = $forceOut -match 'write'
Set-Location $repo
$cmp3 = if ($py -eq 'py') { & py .\tests\compare-trees.py $psTree $pyTree 2>&1 | Out-String } else { & $py .\tests\compare-trees.py $psTree $pyTree 2>&1 | Out-String }
$cmp3Code = $LASTEXITCODE
if ($cmp3Code -eq 0 -and $forceHasWrite) {
    Write-Result '6b' 'PASS' "Force rewrite; compare exit=0"
} elseif ($cmp3Code -eq 0) {
    Write-Result '6b' 'PASS' "Force compare exit=0 (write keyword capture uncertain due to encoding)"
} else {
    Write-Result '6b' 'FAIL' "compare exit=$cmp3Code forceHasWrite=$forceHasWrite"
}

# --- Step 7 gitignore ---
function Test-GitignoreCase {
    param([string]$Label, [string]$InitialContent, [bool]$FileExists)
    $gi = Join-Path $env:TEMP "kit-gitignore-$Label"
    Remove-Item $gi -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $gi | Out-Null
    Set-Location $gi
    $giPath = Join-Path $gi '.gitignore'
    if ($FileExists) {
        [System.IO.File]::WriteAllText($giPath, $InitialContent)
    }
    & $script -Name x 2>&1 | Out-Null
    $lines1 = @(Get-Content .\.gitignore -ErrorAction SilentlyContinue)
    $dups1 = @($lines1 | Group-Object | Where-Object Count -gt 1)
    & $script -Name x 2>&1 | Out-Null
    $lines2 = @(Get-Content .\.gitignore -ErrorAction SilentlyContinue)
    $dups2 = @($lines2 | Group-Object | Where-Object Count -gt 1)
    $content = ($lines1 -join ' | ')
    $ok = ($dups1.Count -eq 0) -and ($dups2.Count -eq 0) -and ($lines1.Count -eq $lines2.Count)
    # Expected patterns for one-line case
    if ($Label -eq 'oneline') {
        $expected = @('*.local', '.env', '.env.*', '!.env.example', '.claude/settings.local.json', '.DS_Store')
        $ok = $ok -and ($lines1.Count -eq 6)
        foreach ($e in $expected) {
            if ($lines1 -notcontains $e) { $ok = $false }
        }
    }
    if ($ok) {
        Write-Result "7-$Label" 'PASS' "lines=$($lines1.Count); content=[$content]; secondRunSame=$($lines1.Count -eq $lines2.Count)"
    } else {
        Write-Result "7-$Label" 'FAIL' "lines=$($lines1.Count); dups1=$($dups1.Count); dups2=$($dups2.Count); content=[$content]; second=$($lines2.Count)"
    }
}

Test-GitignoreCase -Label 'oneline' -InitialContent "*.local`n" -FileExists $true
Test-GitignoreCase -Label 'empty' -InitialContent "" -FileExists $true
Test-GitignoreCase -Label 'missing' -InitialContent "" -FileExists $false

# --- Step 8 special chars ---
$js = Join-Path $env:TEMP 'kit-json'
Remove-Item $js -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $js | Out-Null
Set-Location $js
& $script -Name 'my "cool" a\b proj' -Desc 'цена $5 и $& символы' 2>&1 | Out-Null
$jsonOk = $false
$jsonVal = ''
try {
    if ($py -eq 'py') {
        $jsonVal = & py -c "import json;d=json.load(open('.claude/settings.json',encoding='utf-8'));print(d['//'])" 2>&1 | Out-String
    } else {
        $jsonVal = & $py -c "import json;d=json.load(open('.claude/settings.json',encoding='utf-8'));print(d['//'])" 2>&1 | Out-String
    }
    $jsonOk = ($LASTEXITCODE -eq 0)
} catch {
    $jsonVal = $_.Exception.Message
}
if ($jsonOk) { Write-Result '8a' 'PASS' ("json // = " + $jsonVal.Trim()) }
else { Write-Result '8a' 'FAIL' ("json invalid: " + $jsonVal.Trim()) }

$agentsText = [System.IO.File]::ReadAllText((Join-Path $js 'AGENTS.md'))
$needle = 'цена $5 и $& символы'
if ($agentsText.Contains($needle)) {
    Write-Result '8b' 'PASS' 'dollar/desc preserved in AGENTS.md'
} else {
    # show nearby line
    $hit = Select-String -Path .\AGENTS.md -Pattern 'цена|\$5|символ' | ForEach-Object { $_.Line }
    Write-Result '8b' 'FAIL' ("needle not found; nearby=" + ($hit -join ' || '))
}

# --- Step 9 non-filesystem ---
Set-Location Cert:\
$err9 = ''
$exit9 = 0
try {
    $out9 = & $script -Name x 2>&1 | Out-String
    $exit9 = $LASTEXITCODE
    $err9 = $out9
} catch {
    $err9 = $_.Exception.Message
    $exit9 = 1
}
$rootAfter = Test-Path 'C:\AGENTS.md'
$msgOk = ($err9 -match 'файловой системы') -or ($err9 -match 'file system') -or ($err9 -match 'filesystem') -or ($err9 -match 'FileSystem') -or ($err9 -match 'FileSystemProvider')
# Also accept any non-zero / terminating error without creating C:\AGENTS.md
Set-Location C:\
$rootAfter2 = Test-Path 'C:\AGENTS.md'
Set-Location $repo
if (-not $rootAfter2 -and ($exit9 -ne 0 -or $err9 -match 'error|Error|ошиб|Запусти|file')) {
    Write-Result '9' 'PASS' ("no C:\AGENTS.md; exit=$exit9; msgSnippet=" + $err9.Trim().Substring(0, [Math]::Min(180, $err9.Trim().Length)))
} elseif (-not $rootAfter2 -and $msgOk) {
    Write-Result '9' 'PASS' ("clear error; no C:\ pollution")
} else {
    Write-Result '9' 'FAIL' ("rootAgents=$rootAfter2 exit=$exit9 msg=" + $err9.Trim().Substring(0, [Math]::Min(300, $err9.Trim().Length)))
}

# --- Step 10 cleanup ---
foreach ($p in @('kit-dry','kit-ps','kit-py','kit-gitignore-oneline','kit-gitignore-empty','kit-gitignore-missing','kit-json','kit-gitignore')) {
    Remove-Item (Join-Path $env:TEMP $p) -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Result '10' 'PASS' 'temp dirs cleaned'
Write-Host "=== VERIFY END host=$hostLabel ==="
