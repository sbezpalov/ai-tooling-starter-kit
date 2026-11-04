#!/usr/bin/env python3
"""Check a repository against the documentation & AI-layout tradition (repo-tidy skill).

Usage:
    python3 check_layout.py <repo> [<repo> ...]

Errors (✗) break the tradition and fail the run; warnings (!) are worth a look but may
be deliberate. Exit 0 — clean, 1 — errors, 2 — a path is not a git work tree (it is
skipped). Only git-tracked files are inspected. The rules are described in
../reference/standard.md.
"""

from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from md_links import EXIT_UNUSABLE, NotARepo, tracked_files  # noqa: E402
from md_links import process as md_links_process  # noqa: E402

AGENTS_SECTIONS = [rf"^## {n}\." for n in range(1, 8)]
TOOLS_SECTION = re.compile(r"^## (Раскладка инструментов|Tool layout)", re.M)
ARTIFACT_NAME = re.compile(r"^\d{4}-\d{2}-\d{2}-[\w.-]+$")
BARE_ADR = re.compile(r"\bADR[- ]0*\d{1,4}\b")
# A mention inside quotes or inline code talks about the notation, it is not a reference.
QUOTED = re.compile(r"`[^`]*`|«[^»]*»|\"[^\"]*\"|'[^']*'")
ADR_FILE = re.compile(r"^(?P<prefix>[A-Z][A-Z0-9]*)-(?P<num>\d{4})-[a-z0-9-]+\.md$")
DENY_BASELINE = [
    "Read(.env)", "Read(.env.*)", "Read(**/*.pem)", "Read(**/*.key)",
    "Read(**/.ssh/**)", "Read(**/.aws/**)", "Read(**/.kube/**)",
    "Bash(rm -rf:*)", "Bash(git push --force:*)",
]
GITIGNORE_BASELINE = [".env", ".DS_Store", ".claude/settings.local.json", ".claude/worktrees/"]
JUNK = re.compile(
    r"(^|/)(\.DS_Store|Thumbs\.db|__pycache__/|\.pytest_cache/|node_modules/|\.venv/|"
    r"[^/]+\.egg-info/|[^/]+\.py[co]$|\.env$|\.env\.(?!example$)[^/]+$)"
)
REDIRECTS = ("CLAUDE.md", "GEMINI.md", ".cursorrules")
STRAY_DOC_ROOTS = ("specs", "documentation", "doc", "wiki")
TEXT_SUFFIXES = {".md", ".mdc", ".py", ".sh", ".txt", ".yml", ".yaml", ".toml", ".json", ".sql",
                 ".ts", ".tsx", ".js", ".php", ".go", ".rs", ".ini", ".cfg"}


@dataclass
class Report:
    repo: Path
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    def err(self, msg: str) -> None:
        self.errors.append(msg)

    def warn(self, msg: str) -> None:
        self.warnings.append(msg)


def tracked(repo: Path) -> list[str]:
    """Git-tracked paths relative to the repository, POSIX-style; raises NotARepo."""
    return [p.relative_to(repo).as_posix() for p in tracked_files(repo)]


def read(repo: Path, rel: str) -> str | None:
    p = repo / rel
    try:
        return p.read_text(encoding="utf-8") if p.is_file() else None
    except UnicodeDecodeError:
        return None


def check_agents(r: Report) -> None:
    text = read(r.repo, "AGENTS.md")
    if text is None:
        r.err("AGENTS.md missing — no source of truth for agents and people")
        return
    first = text.splitlines()[0] if text else ""
    if not first.startswith("# AGENTS.md"):
        r.warn(f"AGENTS.md: first line should be '# AGENTS.md — <repository>', found '{first[:60]}'")
    pos = -1
    for n, pattern in enumerate(AGENTS_SECTIONS, 1):
        m = re.search(pattern, text, re.M)
        if not m:
            r.err(f"AGENTS.md: no section '## {n}.'")
            continue
        if m.start() < pos:
            r.err(f"AGENTS.md: section '## {n}.' is out of order")
        pos = m.start()
    if not TOOLS_SECTION.search(text):
        r.err("AGENTS.md: no section '## Tool layout' (or '## Раскладка инструментов')")


def check_redirects(r: Report, files: set[str]) -> None:
    for name in REDIRECTS:
        text = read(r.repo, name)
        if text is None:
            if name == "CLAUDE.md":
                r.err("CLAUDE.md missing — Claude will not find AGENTS.md")
            continue
        if "AGENTS.md" not in text:
            r.err(f"{name}: does not reference AGENTS.md (should import it or be a thin redirect)")
        if len(text.splitlines()) > 40:
            r.warn(f"{name}: {len(text.splitlines())} lines — the redirect has grown; shared rules belong in AGENTS.md")
    if ".ai/README.md" not in files:
        r.err(".ai/README.md missing — no map of tools and artifacts")


def check_artifacts(r: Report, files: list[str]) -> None:
    # Per-tool .<tool>/artifacts/ folders are optional; a single shared .ai/artifacts/ is
    # the default.
    if not any(f.startswith(".ai/artifacts/") for f in files):
        r.err(".ai/artifacts/ missing, or empty without .gitkeep")
    seen: set[str] = set()
    for f in files:
        parts = f.split("/")
        if len(parts) < 3 or parts[1] != "artifacts" or not parts[0].startswith("."):
            continue
        name = parts[2]
        if name == ".gitkeep" or name in seen:
            continue
        seen.add(name)
        stem = name.rsplit(".", 1)[0] if len(parts) == 3 else name
        if not ARTIFACT_NAME.match(stem):
            r.warn(f"{'/'.join(parts[:3])}: artifact name is not 'YYYY-MM-DD-topic'")


def check_docs(r: Report, files: list[str]) -> None:
    top = {f.split("/")[1] for f in files if f.startswith("docs/")}
    for stray in STRAY_DOC_ROOTS:
        if any(f.startswith(stray + "/") for f in files):
            r.err(f"{stray}/ — a second documentation root; move it into docs/")
    if not top:
        r.warn("no docs/ — documentation, if any, belongs in docs/")
        return
    index = read(r.repo, "docs/README.md")
    if index is None:
        r.warn("docs/README.md missing — the documentation has no map")
    else:
        for entry in sorted(top - {"README.md", ".gitkeep"}):
            if entry not in index:
                r.warn(f"docs/README.md: '{entry}' is not mentioned")
    for f in files:
        low = f.lower()
        if ("runbook" in low and low.endswith(".md") and not f.startswith("docs/runbooks/")
                and not f.startswith(".")):
            r.warn(f"{f}: runbook outside docs/runbooks/")


def check_adr(r: Report, files: list[str]) -> None:
    for f in files:
        name = f.rsplit("/", 1)[-1].lower()
        if re.match(r"^adr[-_ ]?\d+", name) and not f.startswith("docs/adr/"):
            r.err(f"{f}: ADR outside docs/adr/ (expected docs/adr/PREFIX-NNNN-topic.md)")
    adr_files = [f for f in files if f.startswith("docs/adr/")
                 and f not in ("docs/adr/README.md", "docs/adr/.gitkeep")]
    if not adr_files:
        return
    registry = read(r.repo, "docs/adr/README.md")
    if registry is None:
        r.err("docs/adr/README.md missing — ADRs have no registry")
    prefixes = set()
    for f in adr_files:
        name = f.rsplit("/", 1)[-1]
        m = ADR_FILE.match(name)
        if not m:
            r.err(f"{f}: ADR name is not 'PREFIX-NNNN-topic.md'")
            continue
        prefixes.add(m.group("prefix"))
        if registry is not None and name not in registry:
            r.err(f"docs/adr/README.md: no row for {name}")
    if len(prefixes) > 1:
        r.warn(f"docs/adr/: several prefixes {sorted(prefixes)}")


def check_bare_adr(r: Report, files: list[str]) -> None:
    hits = 0
    for f in files:
        if Path(f).suffix not in TEXT_SUFFIXES or f.startswith("CHANGELOG"):
            continue
        text = read(r.repo, f)
        if text is None:
            continue
        for i, line in enumerate(text.splitlines(), 1):
            if BARE_ADR.search(QUOTED.sub("", line)):
                hits += 1
                if hits <= 10:
                    r.err(f"{f}:{i}: bare ADR number without the repository prefix")
    if hits > 10:
        r.err(f"… {hits - 10} more bare ADR numbers")


def check_settings(r: Report) -> None:
    text = read(r.repo, ".claude/settings.json")
    if text is None:
        r.warn(".claude/settings.json missing — no committed deny rules for reading secrets")
        return
    try:
        deny = json.loads(text).get("permissions", {}).get("deny", [])
    except json.JSONDecodeError as exc:
        r.err(f".claude/settings.json: invalid JSON ({exc})")
        return
    missing = [d for d in DENY_BASELINE if d not in deny]
    if missing:
        r.err(f".claude/settings.json: permissions.deny lacks {', '.join(missing)}")


def check_git_hygiene(r: Report, files: list[str]) -> None:
    gi = read(r.repo, ".gitignore")
    if gi is None:
        r.err(".gitignore missing")
    else:
        lines = {ln.strip().lstrip("/") for ln in gi.splitlines()}
        lines |= {ln.removeprefix("**/") for ln in lines}
        for need in GITIGNORE_BASELINE:
            if need not in lines:
                r.err(f".gitignore: no '{need}'")
    junk = [f for f in files if JUNK.search(f)]
    for f in junk[:10]:
        r.err(f"{f}: junk or a secret under git")
    if len(junk) > 10:
        r.err(f"… {len(junk) - 10} more junk files under git")
    if ".gitattributes" not in files:
        r.warn(".gitattributes missing — line endings are not pinned")
    if ".editorconfig" not in files:
        r.warn(".editorconfig missing")


def check_service_files(r: Report, files: set[str]) -> None:
    for name in ("README.md", "LICENSE", "SECURITY.md", "CHANGELOG.md"):
        if name not in files:
            r.warn(f"{name} missing")
    cl = read(r.repo, "CHANGELOG.md")
    if cl is not None and not re.search(r"^## \[?Unreleased\]?", cl, re.M):
        r.err("CHANGELOG.md: no '## Unreleased' section")


def check_links(r: Report, files: list[str]) -> None:
    root = r.repo.resolve()
    by_name: dict[str, list[Path]] = defaultdict(list)
    for f in files:
        by_name[Path(f).name].append((root / f).resolve())
    for f in files:
        if f.lower().endswith(".md") and (root / f).is_file():
            for problem in md_links_process((root / f).resolve(), root, by_name, fix=False):
                (r.warn if " — detour → " in problem else r.err)(f"link {problem}")


def check(repo: Path) -> Report:
    r = Report(repo)
    files = tracked(repo)
    fset = set(files)
    check_agents(r)
    check_redirects(r, fset)
    check_artifacts(r, files)
    check_docs(r, files)
    check_adr(r, files)
    check_bare_adr(r, files)
    check_settings(r)
    check_git_hygiene(r, files)
    check_service_files(r, fset)
    check_links(r, files)
    return r


def main() -> int:
    repos = [Path(a).resolve() for a in sys.argv[1:]] or [Path.cwd()]
    failed = unusable = False
    for repo in repos:
        try:
            r = check(repo)
        except NotARepo as exc:
            print(f"✗ {exc}", file=sys.stderr)
            unusable = True
            continue
        mark = "✗" if r.errors else "✓"
        print(f"{mark} {repo.name}: {len(r.errors)} errors, {len(r.warnings)} warnings")
        for e in r.errors:
            print(f"  ✗ {e}")
        for w in r.warnings:
            print(f"  ! {w}")
        failed |= bool(r.errors)
    if unusable:
        return EXIT_UNUSABLE
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
