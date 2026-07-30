# AI Tooling Starter Kit

[![CI](https://github.com/sbezpalov/ai-tooling-starter-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/sbezpalov/ai-tooling-starter-kit/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**English** · [Русский](README.ru.md)

One command that scaffolds a consistent config layout for the AI tools you actually use —
**Claude, Codex, Cursor, Antigravity/Gemini, Perplexity** — in any new project. Describe the
project once; every tool reads the same context. Saves time and tokens.

Current release: **1.1.0** (see [CHANGELOG.md](CHANGELOG.md)). “Model v2” below names
the architectural generation (AGENTS.md), not the semver. Generated scaffolds and CLI
output are **English** by default; Russian docs live in `*.ru.md`.

## The model (v2 — AGENTS.md)

**`AGENTS.md` is the single source of truth.** Codex, Cursor, Google Antigravity/Gemini and other
AGENTS-aware tools read it natively, so context needs no duplication and there is no
"pointer file nobody opens". Everything else is a thin redirect or tool-specific detail.

| File | Tool | Role |
|------|------|------|
| `AGENTS.md` | Codex (CLI / IDE / app), all agents | ★ project, stack, rules, DoD, security |
| `.cursorrules` + `.cursor/rules/*.mdc` + `.cursorignore` | Cursor | redirect + rules (`000-project`, `010-safety`) |
| `CLAUDE.md` + `.claude/` | Claude Code / Cowork | redirect + `commands/`, `agents/`, `settings.json` |
| `GEMINI.md` | Antigravity / Gemini | agent specifics (wins on conflict) |
| `PERPLEXITY.md` | Perplexity | paste-in brief (role / boundaries / output format) |
| `.ai/README.md` + `.ai/artifacts/` | — | layout map + cross-tool artifacts |

Tool-specific artifacts live in `.claude/artifacts/`, `.cursor/artifacts/`,
`.antigravity/artifacts/`, and `.perplexity/artifacts/`; shared and Codex artifacts live
in `.ai/artifacts/`.

Codex needs no redirect file: it discovers `AGENTS.md` natively. The kit deliberately leaves
`.codex/config.toml` optional because model, permission, and integration settings should be
added only when a repository has a concrete need.

> Why `AGENTS.md` rather than v1's `.ai/shared-context.md`: AGENTS is a growing cross-tool
> convention read directly by the tools, which means one less layer of indirection.

## Three implementations, one result

The kit ships three equivalent scripts: **byte-for-byte identical output**, identical
stdout, the same flags, LF line endings on every OS.

| Script | Environment |
|--------|-------------|
| `init-ai-tooling.sh` | Bash (macOS/Linux) |
| `init_ai_tooling.py` | Python 3.6+, pure stdlib (cross-platform) |
| `init-ai-tooling.ps1` | Windows PowerShell 5.1 / PowerShell 7+ (Windows 10/11, no dependencies) |

The PowerShell version has been verified by hand on Windows 10/11 under both the built-in
Windows PowerShell 5.1 and PowerShell 7, and is exercised by CI on every push. The script
never deletes anything, never overwrites existing files without `-Force`, and `-DryRun`
prints the plan without writing — a good place to start.

Equivalence is enforced by `tests/compare-trees.py`, which compares the scaffolded trees
byte for byte (line endings are deliberately *not* normalized). Run it locally:

```bash
mkdir -p /tmp/a /tmp/b
(cd /tmp/a && /path/to/init-ai-tooling.sh --name demo --desc "Test")
(cd /tmp/b && python3 /path/to/init_ai_tooling.py --name demo --desc "Test")
python3 tests/compare-trees.py /tmp/a /tmp/b
```

## Usage

```bash
# macOS / Linux (Bash)
/path/to/init-ai-tooling.sh --name my-project --desc "What this project is"

# Windows 11 / 10 (PowerShell)
.\init-ai-tooling.ps1 -Name my-project -Desc "What this project is"
# If script execution is blocked by Windows policy:
powershell -ExecutionPolicy Bypass -File .\init-ai-tooling.ps1 -Name my-project

# Any OS (Python 3, no dependencies)
python3 /path/to/init_ai_tooling.py --name my-project --desc "What this project is"
```

| Option (Bash/Python) | Option (PowerShell) | Meaning |
|----------------------|---------------------|---------|
| `--name NAME` | `-Name NAME` | Project name (defaults to the folder name) |
| `--desc "TEXT"` | `-Desc "TEXT"` | One-line description |
| `--force` | `-Force` | Overwrite existing files |
| `--dry-run` | `-DryRun` | Print the plan, write nothing |
| `--no-gitignore` | `-NoGitignore` | Leave `.gitignore` alone |
| `--version` | `-Version` | Print script version and exit |
| `-h`, `--help` | `-?`, `Get-Help` | Help |

Idempotent: without `--force` nothing existing is touched, so re-running is safe.

## Install globally

```bash
install -m755 init-ai-tooling.sh ~/bin/ai-init      # if ~/bin is on PATH
# or an alias:
alias ai-init="/path/to/ai-tooling-starter-kit/init-ai-tooling.sh"
```

## After running

1. Fill in the `TODO`s in **`AGENTS.md`** (stack, structure, status, security) — every tool
   reads its context from there.
2. Optionally add domain rules in `.cursor/rules/*.mdc` and a role in `PERPLEXITY.md`.
3. Commit: `git add -A && git commit -m "chore: scaffold AI tooling (AGENTS.md model)"`.

## Projects that already have a convention

The script is idempotent and **never overwrites** files you already have, but on a project
with its own layout (custom `.cursor/rules/*.mdc`, an existing `AGENTS.md`, skills) it can
create partial duplication — e.g. your `00-project.mdc` sitting next to a generic
`000-project.mdc`. Merge those by hand: make your content the basis of `AGENTS.md` and drop
the duplicates.

## Migrating v1 → v2

If a project was scaffolded with v1 (`.ai/shared-context.md` as the hub), remove the v1
leftovers and re-apply v2 with `--force`:

```bash
rm -f .ai/shared-context.md .cursor/README.md .perplexity/context.md \
      .perplexity/spaces/README.md .antigravity/rules/000-workspace.md \
      .antigravity/rules/.gitkeep .cursor/rules/.gitkeep
rmdir .antigravity/rules 2>/dev/null || true
init-ai-tooling.sh --name PROJECT --desc "..." --force
```

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md)
([Русский](CONTRIBUTING.ru.md)). The one rule that matters: any behaviour change must land
in **all three scripts at once**, or CI will catch the divergence. For security reports see
[SECURITY.md](SECURITY.md) ([Русский](SECURITY.ru.md)).

## License

[MIT](LICENSE). Use, modify and embed this starter kit in commercial and open source
projects freely.

---
*Release 1.1.0 is exercised by CI: dry-run, real run, idempotency, and byte-for-byte
equality across all three implementations (ubuntu + windows-latest, PowerShell 5.1 and 7).*
