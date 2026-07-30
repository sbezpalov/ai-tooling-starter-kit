# Codex support — pre-change plan

Date: 2026-07-30

## Scope

Add Codex as an explicitly supported AI tool while preserving the existing
`AGENTS.md` single-source-of-truth model.

The implementation intentionally does not add `CODEX.md`, a default
`.codex/config.toml`, or `.codex/artifacts/`:

- Codex reads `AGENTS.md` natively.
- Repository-specific Codex settings are optional and should not override user
  defaults without a concrete project need.
- `.codex/` is configuration state and is protected from writes in the standard
  Codex workspace sandbox; Codex uses `.ai/artifacts/` for durable shared output.

## Planned changed files

- `AGENTS.md`
- `.ai/README.md`
- `.ai/artifacts/2026-07-30-codex-support-plan.md`
- `README.md`
- `README.ru.md`
- `CHANGELOG.md`
- `CHANGELOG.ru.md`
- `init-ai-tooling.sh`
- `init_ai_tooling.py`
- `init-ai-tooling.ps1`
- `tests/compare-trees.py`

## Expected diff

- Name Codex in project descriptions, support tables, generated instructions,
  and command help.
- Document native `AGENTS.md` discovery and the deliberate absence of redundant
  Codex-specific files.
- Route Codex artifacts to `.ai/artifacts/`.
- Bump the product version from `1.0.0` to `1.1.0`.
- Extend the scaffold comparison test with a small Codex support contract.
- Keep Bash, Python, and PowerShell output byte-for-byte equivalent.

## Verification

- Syntax checks for Python, Bash, and PowerShell.
- Dry-run writes nothing.
- Bash, Python, PowerShell 5.1, and PowerShell 7 scaffolds compare byte for byte
  on the available Windows environment.
- Re-running a generator without force changes nothing.
- `git diff --check` and final diff review.

## Rollback plan

Before commit, restore only the files listed above from the current `HEAD` and
remove this plan artifact. No generated project or production data is in scope.
