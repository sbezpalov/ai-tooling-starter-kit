# Documentation — __NAME__

The only documentation root is `docs/`. This page is its map: section → what is inside →
when to open it. Add a row when you add a section.

| Section | What | When to open |
|---|---|---|
| [`adr/`](adr/README.md) | Architecture decision records and their registry | Before changing a past decision; when making a new one |

## Conventions
- Document header — a table `Status | Date | Related`. Status reflects reality:
  `Draft`, `Blocked` (with the reason), `Ready`, `Accepted`, `Superseded`.
- Procedures go in `docs/runbooks/`: when to apply, prerequisites, numbered idempotent
  steps, abort criteria, rollback, escalation.
- Requirements (PRD/SRS) only as real documents — no empty placeholders.
- Plans, research and reviews from AI sessions are dated artifacts in `.ai/artifacts/`.

<!-- Initialized by init-repo-bootstrap __VERSION__ (__DATE__). -->
