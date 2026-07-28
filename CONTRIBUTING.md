# Contributing

Thanks for your interest. The project is small; the rules are short.

Russian translation: [CONTRIBUTING.ru.md](CONTRIBUTING.ru.md).

## The one rule

**All three implementations must stay equivalent.** Any behaviour change — new template,
new flag, edit to generated text — lands in **all three scripts at once**:

- `init-ai-tooling.sh`
- `init_ai_tooling.py`
- `init-ai-tooling.ps1`

CI compares the scaffolded trees byte for byte and fails if a single character diverges.

When bumping a release, update `VERSION` / `$ToolVersion` in all three scripts,
signatures/help (they read the constant), `CHANGELOG.md` (+ `CHANGELOG.ru.md` if present),
and the version badge in both READMEs.

Check locally before pushing:

```bash
mkdir -p /tmp/a /tmp/b
(cd /tmp/a && ./init-ai-tooling.sh --name demo --desc "Test")
(cd /tmp/b && python3 ./init_ai_tooling.py --name demo --desc "Test")
python3 tests/compare-trees.py /tmp/a /tmp/b     # expect "Trees are identical"
```

The PowerShell script cannot be verified locally without Windows — CI covers it
(`windows-latest`, Windows PowerShell 5.1 and PowerShell 7).

## Pitfalls we have already hit

These are easy to break again, so they are called out explicitly.

**PowerShell: literal here-strings only.** Templates use `@'…'@`, not `@"…"@`. In an
expandable here-string the backtick is an escape: markdown backticks vanish, and `` `a ``
becomes BEL (0x07) mid-file.

**PowerShell: the file must be UTF-8 with BOM.** Without a BOM, Windows PowerShell 5.1
reads `.ps1` as the ANSI code page; non-ASCII bytes can decode into typographic quotes
`“` `”`, which PowerShell treats as string delimiters — the file stops parsing. CI checks
for the BOM in a dedicated step.

**PowerShell: a here-string may omit the trailing newline** before the closing `'@`.
`Write-Utf8LfFile` appends `\n` to non-empty content.

**PowerShell: `.NET` does not follow `Set-Location`.** `[System.IO.*]` resolves relative
paths via `[Environment]::CurrentDirectory`, which is not synced with the PowerShell
location. The script syncs it at startup and refuses to run outside a FileSystem
provider. Do not remove those checks.

**JSON substitution.** The project name lands in `.claude/settings.json`, so it has a
separate `__NAME_JSON__` placeholder with `\` and `"` escaping. Do not put plain
`__NAME__` inside JSON.

**PowerShell: `-replace` is regex.** The replacement side treats `$1`, `$&`, `$$` as
backreferences, so value substitution uses `.Replace()`.

**Output is always LF.** On every OS, including Windows. `tests/compare-trees.py`
deliberately does not normalize line endings, so CRLF is a failure.

## Style

- Scripts are self-contained: templates live inline; no external dependencies.
- Idempotent: without `--force` / `-Force`, existing files are left alone.
- Never delete. The script only creates files and appends lines to `.gitignore`.
- `bash` passes `shellcheck`; `.ps1` passes `PSScriptAnalyzer` with no Error-level findings.
- Comments and messages are **English** so the three scripts stay one language.

## Pull request

1. Branch from `main`.
2. Change all three scripts + local equivalence check.
3. If behaviour changed — update both READMEs (`README.md` and `README.ru.md`).
4. PR description: what changes and why.

Green CI is required to merge.
