<#
.SYNOPSIS
    init-ai-tooling.ps1 (1.0.0, AGENTS.md model) — PowerShell version for Windows 11/10.

.DESCRIPTION
    Deploys an AI tooling scaffold (Claude, Cursor, Antigravity/Gemini, Perplexity)
    in the current repository. Model: AGENTS.md = single source of truth.

.PARAMETER Name
    Project name (defaults to the current folder name).

.PARAMETER Desc
    Short one-line description.

.PARAMETER Force
    Overwrite existing files.

.PARAMETER DryRun
    Print the plan, write nothing.

.PARAMETER NoGitignore
    Leave .gitignore alone.

.PARAMETER Version
    Print version and exit.

.EXAMPLE
    .\init-ai-tooling.ps1 -Name "my-project" -Desc "My project"
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

# Separate constant from -Version: PowerShell variable names are case-insensitive.
$ToolVersion = "1.0.0"

$ErrorActionPreference = "Stop"

if ($Version) {
    Write-Host "init-ai-tooling.ps1 $ToolVersion"
    exit 0
}

# Windows PowerShell 5.1 defaults to OEM encoding (CP437/CP866) — without this
# non-ASCII text in messages becomes "?????". Swallow errors: in some hosts
# (ISE, redirected stdout) assignment is unavailable and that is not fatal.
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

# .NET resolves relative paths via [Environment]::CurrentDirectory, which is NOT
# synced with PowerShell's current location. Without this line [System.IO.*]
# would write to the process start directory, not where the user cd'd.
if ($PWD.Provider.Name -ne 'FileSystem') {
    throw ("Run the script from a filesystem directory. Current location: " +
           "$($PWD.Path) (provider $($PWD.Provider.Name)).")
}
[Environment]::CurrentDirectory = $PWD.ProviderPath

if ([string]::IsNullOrWhiteSpace($Name)) {
    $Name = (Get-Item -Path .).Name
}
if ([string]::IsNullOrWhiteSpace($Desc)) {
    $Desc = "TODO: short project description"
}
$Date = (Get-Date -Format "yyyy-MM-dd")
# Separate value for JSON substitution: quotes and backslashes in the project name
# would otherwise invalidate .claude/settings.json.
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
    # Normalize to LF; non-empty files end with \n, matching Python/bash templates
    # (here-strings in PowerShell do not always keep the newline before closing '@).
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
        Say ("skip   " + ($RelPath -replace "\\", "/") + " (already exists)")
        return
    }
    if ($DryRun) {
        Say ("write  " + ($RelPath -replace "\\", "/"))
        return
    }
    # .Replace() — literal substitution. -replace would treat $Name/$Desc as regex
    # substitution ($1, $&, $$), breaking descriptions containing dollar signs.
    $rendered = $Content.Replace("__NAME_JSON__", $NameJson).Replace("__NAME__", $Name).Replace("__DESC__", $Desc).Replace("__DATE__", $Date).Replace("__VERSION__", $ToolVersion)
    Write-Utf8LfFile -Path $RelPath -Content $rendered
    Say ("write  " + ($RelPath -replace "\\", "/"))
}

# 1) artifact directories + .gitkeep
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

# 2) template files
$AgentsMd = @'
# AGENTS.md — __NAME__

> **Single source of truth for all AI tools and humans in this repository.**
> Cursor, Google Antigravity/Gemini, and other AGENTS-compatible tools read this file
> natively. Thin redirects (`.cursorrules`, `CLAUDE.md`, `GEMINI.md`, `PERPLEXITY.md`)
> add detail but do not override these rules. **Read this file fully before working.**

## 1. Project
__DESC__

<!-- TODO: 2–4 sentences — purpose, users, value. -->

## 2. Stack
<!-- TODO: languages, frameworks, DB, infrastructure. -->

## 3. Structure
<!-- TODO: table of "directory → purpose". -->

## 4. Status / current priority
<!-- TODO: where the project is now and what to focus on. -->

## 5. How to change things (agent)
- Work from a plan: break the task down and show steps BEFORE executing.
- Human-in-the-loop: for irreversible operations and production-data edits — stop and ask.
- Produce artifacts (diff, list of changed files, rollback plan) before applying.
- Keep changes atomic; explain WHAT and WHY.
- New code ships with tests; the task is not "done" if tests/lint are failing.

## 6. Security (NEVER)
- Do not edit production directly <!-- TODO: delivery path, e.g. local → staging → prod via git -->.
- Secrets (passwords, keys, tokens, `.env`, local configs) — never commit or print them;
  the repo may only contain `*.example` files.
- Destructive operations on production data/DB — only with explicit confirmation and a dry run on a copy.
- <!-- TODO: project-specific bans (do not touch core/…). -->

## 7. Definition of Done
- [ ] Change is local; secrets did not land in code/commit.
- [ ] Tests/lint are green; verified on staging if needed.
- [ ] Diff is reviewed; a rollback plan exists.

## Tool layout
Artifacts live in `.ai/artifacts/` (cross-tool) and `.<tool>/artifacts/`. Details — `.ai/README.md`.

<!-- Initialized by init-ai-tooling __VERSION__ (__DATE__). -->
'@

$CursorRules = @'
# Cursor reads this file for compatibility. SOURCE OF TRUTH — ./AGENTS.md.
# Detailed rules — ./.cursor/rules/*.mdc. Read AGENTS.md before any work.
See AGENTS.md
'@

$CursorRule000 = @'
---
description: Base project context for __NAME__ — points to AGENTS.md
alwaysApply: true
---

# __NAME__

Source of truth — `../../AGENTS.md` (read it fully). This file and sibling `*.mdc`
files hold Cursor-specific and detailed topical rules only.
'@

$CursorRule010 = @'
---
description: Security, secrets, production work
alwaysApply: true
---

# Security

- Secrets (passwords, keys, tokens, `.env`, local configs) — not in code, commits, or context.
- Do not edit production directly; destructive operations on production data — only
  with explicit confirmation and a dry run on a copy.
- Before a risky change — show a diff and rollback plan, ask for confirmation.
- Full rules — in `../../AGENTS.md`.
'@

$CursorIgnore = @'
# Secrets and local config
.env
*.local

# Build artifacts and data
dist/
build/
*.egg-info/

# Environments and caches
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

**Source of truth — [`AGENTS.md`](AGENTS.md). Read it first.** Below — Claude-specific only.

## Claude directories
- `.claude/commands/` — slash commands; `.claude/agents/` — subagents; `.claude/artifacts/` — artifacts.
- Team settings — `.claude/settings.json`; personal — `.claude/settings.local.json` (do not commit).
'@

$ClaudeReadme = @'
# .claude/ — Claude Code configuration

Source of truth — [`../AGENTS.md`](../AGENTS.md).

- `commands/` — slash commands; `agents/` — subagents; `artifacts/` — Claude artifacts.
- `settings.json` — team settings; `settings.local.json` — personal (do not commit).
'@

$ClaudeSettings = @'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "//": "Team Claude Code settings for __NAME_JSON__. Personal overrides — settings.local.json (do not commit).",
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

> Antigravity reads both `AGENTS.md` and `GEMINI.md`; on conflict, `GEMINI.md` wins.
> **Project source of truth — `AGENTS.md`; read it first.** Here — Antigravity/Gemini specifics.

## Agent mode
- Work from a plan (task/plan): break the task down and show steps before executing.
- Human-in-the-loop: for production-data/core edits — stop and ask for confirmation.
- Produce artifacts (diff, file list, rollback plan) before applying; save them in `.antigravity/artifacts/`.
- Do not run shell commands against a production server/DB.
- Keep changes atomic, with an explanation of WHAT and WHY.
'@

$AntigravityReadme = @'
# .antigravity/ — Google Antigravity workspace

Rules — in [`../GEMINI.md`](../GEMINI.md); source of truth — [`../AGENTS.md`](../AGENTS.md).
`artifacts/` — plans, task lists, walkthroughs, browser recordings.
'@

$PerplexityMd = @'
# PERPLEXITY.md — brief for Perplexity / research agents

> Perplexity has no native repo config. This file is a **brief**: paste it into a
> prompt / Space (or Comet) to set role, context, and boundaries. Project context comes from `AGENTS.md`.

## Role
Research/content assistant for __NAME__.
<!-- TODO: clarify the role; whether it writes code; data access. -->

## What to use it for
<!-- TODO: research, fact-checking, drafts, competitive analysis. -->

## Boundaries
- Cite sources for facts; do not invent — mark unknowns as "needs verification".
- <!-- TODO: domain limits (ads/medicine/legal/etc.). -->

## Output format
Structured (Markdown/table), easy to transfer. Save as an artifact in `.perplexity/artifacts/`.
'@

$PerplexityReadme = @'
# .perplexity/ — Perplexity / research

Paste-in brief — [`../PERPLEXITY.md`](../PERPLEXITY.md); context — [`../AGENTS.md`](../AGENTS.md).
`artifacts/` — saved research reports (`YYYY-MM-DD-topic.md`; end with sources for verification).
'@

$AiReadme = @'
# .ai/ — AI tooling layout

**Source of truth — [`../AGENTS.md`](../AGENTS.md)** (read natively by Cursor,
Antigravity/Gemini, and others). Everything else is a thin redirect or tool-specific detail.

| Tool | File | Artifacts |
|---|---|---|
| All agents | `AGENTS.md` | `.ai/artifacts/` |
| Cursor | `.cursorrules` → AGENTS.md; `.cursor/rules/*.mdc`; `.cursorignore` | `.cursor/artifacts/` |
| Claude (Code / Cowork) | `CLAUDE.md` → AGENTS.md; `.claude/` | `.claude/artifacts/` |
| Antigravity / Gemini | `GEMINI.md` (+ AGENTS.md) | `.antigravity/artifacts/` |
| Perplexity | `PERPLEXITY.md` (paste-in brief) | `.perplexity/artifacts/` |

## Rule
Project changes → edit **`AGENTS.md`**. Tool-specific detail → that tool's file.
An artifact is a durable session result (plan, research, diff, task list).

<!-- Initialized by init-ai-tooling __VERSION__ (__DATE__). -->
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
        # @(...) required: Get-Content on a single-line file returns a scalar String,
        # and later += would concatenate strings instead of appending to an array.
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
Say "Done (${ToolVersion}): AGENTS.md-model scaffold deployed for `"$Name`"."
Say "Next: fill in the TODOs in AGENTS.md — every tool reads context from there."
if ($DryRun) {
    Say "(dry-run: nothing was written)"
}
