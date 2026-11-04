# AI Tooling Starter Kit

[![CI](https://github.com/sbezpalov/ai-tooling-starter-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/sbezpalov/ai-tooling-starter-kit/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**English** · [Русский](README.ru.md)

One command that scaffolds a consistent config layout for the AI tools you actually use —
**Claude, Codex, Cursor, Gemini/Antigravity** — in any new project. Describe the
project once; every tool reads the same context. Saves time and tokens.

Current release: **2.1.0** (see [CHANGELOG.md](CHANGELOG.md)). “Model v2” below names
the architectural generation (AGENTS.md), not the semver. Generated scaffolds and CLI
output are **English** by default; Russian docs live in `*.ru.md`.

## The model (v2 — AGENTS.md)

**`AGENTS.md` is the single source of truth.** Codex, Cursor, Google Antigravity/Gemini and other
AGENTS-aware tools read it natively, so context needs no duplication and there is no
"pointer file nobody opens". Claude Code and Gemini CLI get it through an `@AGENTS.md`
import; everything else is tool-specific detail.

| File | Tool | Role |
|------|------|------|
| `AGENTS.md` | Codex (CLI / IDE / app), all agents | ★ numbered sections: project, stack, structure, status, how to change, "never" list, definition of done, tool layout |
| `.cursor/rules/*.mdc` + `.cursorignore` | Cursor | rules (`000-project`, `010-safety`); Cursor reads `AGENTS.md` natively |
| `CLAUDE.md` + `.claude/` | Claude Code / Cowork | `@AGENTS.md` import + `commands/`, `agents/`, `settings.json` |
| `GEMINI.md` | Gemini CLI / Antigravity | `@./AGENTS.md` import + Gemini specifics; Antigravity reads `AGENTS.md` natively |
| `.ai/README.md` + `.ai/artifacts/` | — | layout map + artifacts from every tool |
| `.ai/manifest.json` | — | kit version + list of kit-owned files (for future upgrades) |

Plans, research, and other durable session results from every tool go in one place:
`.ai/artifacts/`.

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

**One source for the templates.** Generated text lives once, in `templates/<family>/*.tpl`
plus `layout.json` (write order, `.gitkeep` directories, `.gitignore` lines) and the root
`VERSION` file. `tools/sync-templates.py` embeds it into all six scripts, so each script
still works on its own when copied anywhere; CI fails if an embedded copy is stale.

## Repo bootstrap companion (B+)

AI scaffolding stays focused. Community/git stubs live in a **separate companion**
family with the same triple parity:

| Script | Environment |
|--------|-------------|
| `init-repo-bootstrap.sh` | Bash (macOS/Linux) |
| `init_repo_bootstrap.py` | Python 3.6+, pure stdlib |
| `init-repo-bootstrap.ps1` | Windows PowerShell 5.1 / PowerShell 7+ |

Profiles:

| Profile | Writes |
|---------|--------|
| `core` (default for companion) | `LICENSE` stub (not a real license), `SECURITY.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `.gitattributes` (LF), `.editorconfig` |
| `github` | core + `.github/CODEOWNERS`, issue/PR templates |
| `full` | github + `.github/dependabot.yml` stub, `docs/README.md` (documentation map), `docs/adr/README.md` (ADR registry) |

ADRs are named `docs/adr/PREFIX-NNNN-topic.md` and referenced as `ADR PREFIX-0001`, so
numbers stay unambiguous across repositories. Set the prefix with `--adr-prefix API`
(`-AdrPrefix`; a letter, then up to 9 letters or digits). The default is the first ASCII
word of the project name, upper-cased (`web-portal` → `WEB`); names without one get
`PROJ`. `--also-repo` uses the default.

Run it on its own:

```bash
/path/to/init-repo-bootstrap.sh --name my-project --desc "..." --profile github
python3 /path/to/init_repo_bootstrap.py --name my-project --profile full --adr-prefix API
.\init-repo-bootstrap.ps1 -Name my-project -Profile full -AdrPrefix API
```

| Option (Bash/Python) | Option (PowerShell) | Meaning |
|----------------------|---------------------|---------|
| `--name NAME` | `-Name NAME` | Project name (defaults to the folder name) |
| `--desc "TEXT"` | `-Desc "TEXT"` | One-line description |
| `--profile P` | `-Profile P` | `core` (default), `github` or `full` |
| `--adr-prefix PREFIX` | `-AdrPrefix PREFIX` | ADR prefix for `docs/adr/` (profile `full`) |
| `--force` | `-Force` | Overwrite existing files |
| `--dry-run` | `-DryRun` | Print the plan, write nothing |
| `--version` | `-Version` | Print script version and exit |

One-shot orchestration from the AI init (default profile for this path: `full`):

```bash
init-ai-tooling.sh --name my-project --desc "..." --also-repo
# or
python3 init_ai_tooling.py --name my-project --desc "..." --also-repo --repo-profile core
```

PowerShell: `-AlsoRepo` and `-RepoProfile`. Without the flag, the AI script prints a tip
pointing at the companion. The LICENSE file is an **inert stub** — you must choose and
paste a real license yourself.

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
| `--also-repo` | `-AlsoRepo` | Also run sibling repo-bootstrap companion |
| `--repo-profile P` | `-RepoProfile P` | Profile for `--also-repo` (`core`/`github`/`full`, default `full`) |
| `--prune-legacy` | `-PruneLegacy` | List leftovers from older kit versions and exit (deletes nothing) |
| `--version` | `-Version` | Print script version and exit |
| `-h`, `--help` | `-?`, `Get-Help` | Help |

Idempotent: without `--force` nothing existing is touched, so re-running is safe.

## Install globally

```bash
ln -s /path/to/ai-tooling-starter-kit/init-ai-tooling.sh ~/bin/ai-init   # if ~/bin is on PATH
# or an alias:
alias ai-init="/path/to/ai-tooling-starter-kit/init-ai-tooling.sh"
```

Link or alias rather than copy: `--also-repo` runs `init-repo-bootstrap.sh`, which has to sit
next to the real script — a symlink is followed to it, a copied file has no companion and
`--also-repo` stops with an error. If you do copy, copy both scripts into the same directory.

## After running

1. Fill in the `TODO`s in **`AGENTS.md`** (project, stack, structure, status, commands, bans) — every
   tool reads its context from there. The quickest route is to let your agent do it:
   *"Read this codebase and fill in the TODOs in AGENTS.md. Keep it short — only what you
   could not infer from the code."* Review the result before committing.
2. Optionally add domain rules in `.cursor/rules/*.mdc` and Gemini specifics in `GEMINI.md`.
3. Commit: `git add -A && git commit -m "chore: scaffold AI tooling (AGENTS.md model)"`.

## What `.claude/settings.json` does and does not protect

The generated `deny` list blocks the obvious mistakes (reading `.env`/keys with Claude's
file tools, `rm -rf`, `git push --force`). It is a **guardrail, not a security boundary**:

- `Bash(...)` rules match command prefixes — `rm -r -f`, `find . -delete`, or a script that
  deletes files slip through.
- Without Claude Code's sandbox, `Read(...)` rules cover Claude's file tools, not
  `cat .env` run through Bash.

For real isolation, enable Claude Code's sandbox, run the agent in a container or
devcontainer, or add a `PreToolUse` hook. The same limits are spelled out in the generated
`.claude/README.md`.

## Projects that already have a convention

The script is idempotent and **never overwrites** files you already have, but on a project
with its own layout (custom `.cursor/rules/*.mdc`, an existing `AGENTS.md`, skills) it can
create partial duplication — e.g. your `00-project.mdc` sitting next to a generic
`000-project.mdc`. Merge those by hand: make your content the basis of `AGENTS.md` and drop
the duplicates.

## Upgrading from an earlier version

2.0 no longer generates `.cursorrules`, `PERPLEXITY.md`, `.perplexity/`, `.antigravity/`,
or the per-tool `artifacts/` folders (`.claude/`, `.cursor/`); every tool now shares
`.ai/artifacts/`. To clean up a project scaffolded by 1.x (or by the v1 model):

1. List the leftovers — the script only reports, it never deletes:

   ```bash
   init-ai-tooling.sh --prune-legacy        # PowerShell: -PruneLegacy
   ```

2. Move anything the report marks as *saved item(s)* into `.ai/artifacts/`, then remove the
   listed paths, e.g. `git rm -r .cursorrules PERPLEXITY.md .perplexity .antigravity`.
3. Re-run the script **without** `--force` to add new files such as `.ai/manifest.json`.
   Existing files are kept. To adopt the new `CLAUDE.md` / `GEMINI.md` (`@AGENTS.md`
   imports) without touching a filled-in `AGENTS.md`, scaffold into an empty directory and
   copy those two files over.

## Keeping a repository tidy: the `repo-tidy` skill

[`skills/repo-tidy/`](skills/repo-tidy/SKILL.md) is an agent skill for the same layout
tradition the kit generates, for repositories that already exist or have drifted:
`AGENTS.md` sections, one `docs/` root with a map, an ADR registry with a repository prefix,
dated artifacts, honest statuses, secrets closed off, git hygiene. The rules are in
[`reference/standard.md`](skills/repo-tidy/reference/standard.md); two scripts (Python 3.9+,
no dependencies) do the checking:

```bash
python3 skills/repo-tidy/scripts/check_layout.py /path/to/repo   # ✗ errors, ! warnings
python3 skills/repo-tidy/scripts/md_links.py /path/to/repo --fix # repair relative links
```

To make it available to Claude Code in every project, link it into your skills folder, so
updates to the kit reach it with `git pull`:

```bash
ln -s "$PWD/skills/repo-tidy" ~/.claude/skills/repo-tidy
```

Then ask the agent to "tidy this repository". CI runs the checker on this repository and on a
fresh scaffold.

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md)
([Русский](CONTRIBUTING.ru.md)). The one rule that matters: any behaviour change must land
in **all three scripts at once**, or CI will catch the divergence. For security reports see
[SECURITY.md](SECURITY.md) ([Русский](SECURITY.ru.md)).

## License

[MIT](LICENSE). Use, modify and embed this starter kit in commercial and open source
projects freely.

---
*Release 2.1.0 is exercised by CI: dry-run, real run, idempotency, and byte-for-byte
equality across all three implementations (ubuntu + windows-latest, PowerShell 5.1 and 7).*
