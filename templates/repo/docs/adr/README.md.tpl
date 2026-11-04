# Architecture decision records — __NAME__

## Prefixes

| Prefix | Repository |
|---|---|
| `__ADR_PREFIX__` | this repository |

Add a row for each neighbouring repository whose ADRs you reference.

## Rules
- File: `docs/adr/__ADR_PREFIX__-NNNN-topic.md` — four digits, topic in lowercase Latin
  letters and hyphens.
- Reference in text, code and comments: `ADR __ADR_PREFIX__-0001`. Never a bare number:
  it becomes ambiguous as soon as a neighbouring repository has its own decision 1.
- Numbering is historical. A replaced decision gets `Superseded by __ADR_PREFIX__-NNNN`
  and is not deleted.
- Header: `Status | Date | Context | Related`; sections: Context → Options → Decision →
  Consequences.

## Registry

| ADR | Status | Topic |
|---|---|---|

<!-- Initialized by init-repo-bootstrap __VERSION__ (__DATE__). -->
