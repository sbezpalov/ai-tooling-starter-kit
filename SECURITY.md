# Security

Russian translation: [SECURITY.ru.md](SECURITY.ru.md).

## What this project does

The starter kit is three scripts that **create text configuration files** in the current
directory. It downloads nothing from the network, executes no third-party code, has no
dependencies, and deletes nothing. The only modification of an existing file is appending
lines to `.gitignore` (disabled with `--no-gitignore` / `-NoGitignore`).

Before the first run in an unfamiliar project, use `--dry-run` / `-DryRun`: the script
prints the full plan and writes nothing.

## What the kit configures for you

- `.gitignore` gains `.env`, `.env.*`, `!.env.example`, `*.local` — so secrets stay out of
  commits.
- `.claude/settings.json` includes `deny` rules: reading `.env`, `*.pem`, `*.key`,
  `~/.ssh`, `~/.aws`, `~/.kube`, plus `rm -rf` and `git push --force`.
- `.cursorignore` excludes secrets and local configs from indexing.
- Generated `AGENTS.md` includes a “Security (NEVER)” section — extend it with your
  project rules.

These are sensible defaults, not a full threat model. Review them against your
requirements and extend as needed.

## How to report a problem

If you find a vulnerability — for example a way to make the script write outside the
current directory, run an arbitrary command via arguments, or corrupt the user's existing
data:

1. Open the repository **Security** tab and click **Report a vulnerability**
   (private GitHub Security Advisories channel).
2. If that is unavailable — email sergey@bezpalov.com with a subject starting with
   `SECURITY:`.

Please **do not open a public issue** for exploitable problems until they are fixed.

Expect an initial reply within a few days. The project is maintained by one person, so
there is no formal SLA.

## What is not a vulnerability

- Running the script in the wrong directory by mistake (that is what `--dry-run` is for).
- Overwriting files when `--force` / `-Force` was explicitly passed.
- Linter warnings without an exploit scenario.

## Supported versions

Fixes ship only for the current state of the `main` branch.
