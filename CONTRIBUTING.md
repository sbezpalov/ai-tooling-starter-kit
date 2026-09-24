# Contributing

Thanks for your interest. The project is small; the rules are short.

Russian translation: [CONTRIBUTING.ru.md](CONTRIBUTING.ru.md).

## The one rule

**All three implementations must stay equivalent.**

- **Generated text** (a new template, an edited template, write order, `.gitkeep`
  directories, `.gitignore` lines, the release number) is edited **once**: in
  `templates/<family>/*.tpl`, `templates/<family>/layout.json`, or `VERSION`. Then run
  `python3 tools/sync-templates.py` — it rewrites the generated block in all six scripts.
  CI runs it with `--check` and fails if a script is stale; never edit a generated block
  by hand.
- **Logic** (a new flag, a new write rule) still lands in **all three scripts of that
  family at once**.

Templates keep a `.tpl` suffix so that agents working on this repository do not mistake
`templates/ai/AGENTS.md.tpl` for the repository's own instructions.

AI family:

- `init-ai-tooling.sh`
- `init_ai_tooling.py`
- `init-ai-tooling.ps1`

Repo-bootstrap family (same rule):

- `init-repo-bootstrap.sh`
- `init_repo_bootstrap.py`
- `init-repo-bootstrap.ps1`

CI compares scaffolded trees byte for byte (AI trees, repo trees, and `--also-repo`
combined trees) and fails if a single character diverges.

When bumping a release, edit the root `VERSION` file and run
`python3 tools/sync-templates.py` (it updates the constant and header in all six scripts),
then update `CHANGELOG.md` + `CHANGELOG.ru.md` and the version badge in both READMEs.

Check locally before pushing:

```bash
mkdir -p /tmp/a /tmp/b
(cd /tmp/a && ./init-ai-tooling.sh --name demo --desc "Test")
(cd /tmp/b && python3 ./init_ai_tooling.py --name demo --desc "Test")
python3 tests/compare-trees.py /tmp/a /tmp/b     # expect "Trees are identical"

mkdir -p /tmp/ra /tmp/rb
(cd /tmp/ra && ./init-repo-bootstrap.sh --name demo --desc "Test" --profile full)
(cd /tmp/rb && python3 ./init_repo_bootstrap.py --name demo --desc "Test" --profile full)
python3 tests/compare-trees.py /tmp/ra /tmp/rb
```

With PowerShell 7 (`pwsh`) installed, the `.ps1` scripts run on macOS/Linux too; CI
additionally covers Windows PowerShell 5.1 on `windows-latest`.

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

- Scripts are self-contained: templates are embedded (generated from `templates/`); no
  external dependencies, so a single script can be copied anywhere.
- Idempotent: without `--force` / `-Force`, existing files are left alone.
- Never delete. The script only creates files and appends lines to `.gitignore`.
- `bash` passes `shellcheck`; `.ps1` passes `PSScriptAnalyzer` with no Error-level findings.
- Comments and messages are **English** so the three scripts stay one language.

## Pull request

1. Branch from `main`.
2. Edit `templates/` and run `tools/sync-templates.py`, or change logic in all three
   scripts; then the local equivalence check.
3. If behaviour changed — update both READMEs (`README.md` and `README.ru.md`).
4. PR description: what changes and why.

Green CI is required to merge.
