<#
.SYNOPSIS
    init-repo-bootstrap.ps1 (1.2.0) — PowerShell community/git repository bootstrap.

.DESCRIPTION
    Scaffolds inert governance stubs and optional GitHub community files.
    Does NOT choose a real license. Complements init-ai-tooling.ps1.

.PARAMETER Name
    Project name (defaults to the current folder name).

.PARAMETER Desc
    Short one-line description.

.PARAMETER Profile
    core (default) | github | full

.PARAMETER Force
    Overwrite existing files.

.PARAMETER DryRun
    Print the plan, write nothing.

.PARAMETER Version
    Print version and exit.

.EXAMPLE
    .\init-repo-bootstrap.ps1 -Name "my-project" -Profile full
#>
#Requires -Version 5.1
[CmdletBinding()]
param (
    [string]$Name = "",
    [string]$Desc = "",
    [ValidateSet("core", "github", "full")]
    [string]$Profile = "core",
    [switch]$Force,
    [switch]$DryRun,
    [switch]$Version
)

$ToolVersion = "1.2.0"

$ErrorActionPreference = "Stop"

if ($Version) {
    Write-Host "init-repo-bootstrap.ps1 $ToolVersion"
    exit 0
}

try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

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
$Year = (Get-Date -Format "yyyy")

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
    $lfContent = $Content -replace "`r`n", "`n" -replace "`r", "`n"
    if ($lfContent.Length -gt 0 -and -not $lfContent.EndsWith("`n")) {
        $lfContent += "`n"
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $lfContent, $utf8NoBom)
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
    $rendered = $Content.Replace("__NAME__", $Name).Replace("__DESC__", $Desc).Replace("__DATE__", $Date).Replace("__YEAR__", $Year).Replace("__VERSION__", $ToolVersion)
    Write-Utf8LfFile -Path $RelPath -Content $rendered
    Say ("write  " + ($RelPath -replace "\\", "/"))
}

$LicenseTpl = @'
LICENSE NOT CHOSEN
==================

This is an inert stub written by init-repo-bootstrap. It is NOT a grant of rights.

TODO:
1. Choose a license (MIT, Apache-2.0, proprietary, …).
2. Replace this entire file with the official license text.
3. Update README / package metadata to match.

Copyright holder placeholder: __NAME__ authors
Year placeholder: __YEAR__

Initialized by init-repo-bootstrap __VERSION__ (__DATE__).
'@

$SecurityTpl = @'
# Security Policy

<!-- TODO: replace the contact channel below with a real one before publishing. -->

## Supported versions

Security fixes ship only for the current state of the default branch.

## Reporting a vulnerability

Please **do not open a public issue** for exploitable problems until they are fixed.

1. Prefer a private channel (GitHub Security Advisories / `Security` tab).
2. If that is unavailable — email `TODO: security@example.com` with a subject
   starting with `SECURITY:`.

Expect an initial reply within a few days. There is no formal SLA until you
define one.

## Scope notes for __NAME__

__DESC__

<!-- TODO: document what is in scope, what is out of scope, and safe harbor. -->

<!-- Initialized by init-repo-bootstrap __VERSION__ (__DATE__). -->
'@

$ChangelogTpl = @'
# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Project bootstrap for __NAME__.

<!-- Initialized by init-repo-bootstrap __VERSION__ (__DATE__). -->
'@

$ContributingTpl = @'
# Contributing

Thanks for your interest in __NAME__.

## How to contribute

1. Open an issue describing the change (or claim an existing one).
2. Keep pull requests focused; explain WHAT and WHY.
3. Add or update tests when behaviour changes.
4. Do not commit secrets (`.env`, keys, tokens).

## Local checks

<!-- TODO: document lint, test, and format commands for this repository. -->

```bash
# TODO: replace with the project's real verification commands
echo "No project checks defined yet"
```

<!-- Initialized by init-repo-bootstrap __VERSION__ (__DATE__). -->
'@

$CodeownersTpl = @'
# TODO: replace @TODO-OWNER with real GitHub usernames or teams.
# Docs: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
*       @TODO-OWNER
'@

$PrTpl = @'
## Summary

<!-- What changed and why? -->

## Test plan

- [ ] Documented how this was verified
- [ ] No secrets in the diff

## Related

<!-- Issues / tickets -->
'@

$BugTpl = @'
---
name: Bug report
about: Something is broken
title: ""
labels: bug
assignees: ""
---

## What happened

<!-- Observed behaviour -->

## What you expected

<!-- Expected behaviour -->

## Steps to reproduce

1.
2.
3.

## Environment

- OS:
- Version / commit:
'@

$FeatureTpl = @'
---
name: Feature request
about: Suggest an improvement
title: ""
labels: enhancement
assignees: ""
---

## Problem

<!-- What pain does this solve? -->

## Proposal

<!-- Concrete suggestion -->

## Alternatives considered

<!-- Optional -->
'@

$DependabotTpl = @'
# TODO: enable only after reviewing update cadence and review assignees.
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
'@

Write-ProjectFile "LICENSE" $LicenseTpl
Write-ProjectFile "SECURITY.md" $SecurityTpl
Write-ProjectFile "CHANGELOG.md" $ChangelogTpl
Write-ProjectFile "CONTRIBUTING.md" $ContributingTpl

if ($Profile -eq "github" -or $Profile -eq "full") {
    Write-ProjectFile ".github/CODEOWNERS" $CodeownersTpl
    Write-ProjectFile ".github/PULL_REQUEST_TEMPLATE.md" $PrTpl
    Write-ProjectFile ".github/ISSUE_TEMPLATE/bug_report.md" $BugTpl
    Write-ProjectFile ".github/ISSUE_TEMPLATE/feature_request.md" $FeatureTpl
}

if ($Profile -eq "full") {
    Write-ProjectFile ".github/dependabot.yml" $DependabotTpl
}

Say ""
Say "Done (${ToolVersion}): repo-bootstrap profile `"$Profile`" for `"$Name`"."
Say "Next: replace LICENSE stub and fill SECURITY contact TODOs."
if ($DryRun) {
    Say "(dry-run: nothing was written)"
}
