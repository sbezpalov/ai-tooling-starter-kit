#!/usr/bin/env python3
"""Check (and optionally repair) relative links in a repository's Markdown files.

Usage:
    python3 md_links.py <repo>            # report broken links, exit 1 if any
    python3 md_links.py <repo> --fix      # repair by unique basename, normalize paths

A link is repaired only when exactly one tracked file has the target's basename;
ambiguous or missing targets are reported and left alone. Repaired links are
rewritten as the shortest relative path (``os.path.relpath``). Code fences,
URLs, anchors and mailto: links are ignored. Only git-tracked files are scanned.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

LINK_RE = re.compile(r"(\[[^\]]*\]\()([^)\s]+)(\))")
FENCE_RE = re.compile(r"^\s*(```|~~~)")
SKIP_PREFIXES = ("http://", "https://", "mailto:", "#", "tel:", "data:")


def tracked_files(repo: Path) -> list[Path]:
    out = subprocess.run(
        ["git", "-C", str(repo), "ls-files", "-z"],
        capture_output=True, text=True, check=True,
    ).stdout
    return [repo / p for p in out.split("\0") if p]


def split_target(target: str) -> tuple[str, str]:
    """Return (path, suffix) where suffix is '#anchor' or '?query' or ''."""
    for sep in ("#", "?"):
        if sep in target:
            idx = target.index(sep)
            return target[:idx], target[idx:]
    return target, ""


def resolve(md: Path, path: str, repo: Path) -> Path:
    base = repo if path.startswith("/") else md.parent
    return (base / path.lstrip("/")).resolve()


def process(md: Path, repo: Path, by_name: dict[str, list[Path]], fix: bool) -> list[str]:
    problems: list[str] = []
    lines = md.read_text(encoding="utf-8").splitlines(keepends=True)
    in_fence = False
    changed = False
    for i, line in enumerate(lines):
        if FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue

        def repl(m: re.Match[str]) -> str:
            nonlocal changed
            target = m.group(2).strip("<>")
            if target.startswith(SKIP_PREFIXES):
                return m.group(0)
            path, suffix = split_target(target)
            if not path:
                return m.group(0)
            rel_md = md.relative_to(repo)
            resolved = resolve(md, path, repo)
            if resolved.exists():
                short = os.path.relpath(resolved, md.parent)
                if path.startswith("/") or len(Path(short).parts) >= len(Path(path).parts):
                    return m.group(0)
                # Valid but detours out and back in ("../../docs/x.md" from docs/prd/).
                if not fix:
                    problems.append(f"{rel_md}:{i + 1}: {target} — detour → {short}{suffix}")
                    return m.group(0)
                changed = True
                problems.append(f"{rel_md}:{i + 1}: {target} — fixed → {short}{suffix}")
                return f"{m.group(1)}{short}{suffix}{m.group(3)}"
            candidates = by_name.get(Path(path).name, [])
            if len(candidates) > 1:
                # Disambiguate by the longest matching path tail: "../src/pkg/README.md"
                # still names "src/pkg/README.md" after the linking file moved.
                tail = "/" + "/".join(p for p in Path(path).parts if p not in ("..", "."))
                candidates = [c for c in candidates if c.as_posix().endswith(tail)]
            if len(candidates) != 1:
                why = "missing" if not candidates else f"ambiguous ({len(candidates)} matches)"
                problems.append(f"{rel_md}:{i + 1}: {target} — {why}")
                return m.group(0)
            new_path = os.path.relpath(candidates[0], md.parent)
            if not fix:
                problems.append(f"{rel_md}:{i + 1}: {target} — fixable → {new_path}{suffix}")
                return m.group(0)
            changed = True
            problems.append(f"{rel_md}:{i + 1}: {target} — fixed → {new_path}{suffix}")
            return f"{m.group(1)}{new_path}{suffix}{m.group(3)}"

        lines[i] = LINK_RE.sub(repl, line)
    if changed:
        md.write_text("".join(lines), encoding="utf-8")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("repo", type=Path)
    parser.add_argument("--fix", action="store_true", help="repair links with a unique basename match")
    args = parser.parse_args()
    repo = args.repo.resolve()

    files = tracked_files(repo)
    by_name: dict[str, list[Path]] = defaultdict(list)
    for f in files:
        by_name[f.name].append(f.resolve())

    problems: list[str] = []
    for md in (f for f in files if f.suffix.lower() == ".md" and f.is_file()):
        problems += process(md.resolve(), repo, by_name, args.fix)

    for p in problems:
        print(p)
    remaining = [p for p in problems if " — fixed → " not in p and " — detour → " not in p]
    detours = sum(" — detour → " in p for p in problems)
    note = f" (detours {detours}, run --fix)" if detours else ""
    print(f"{'✗' if remaining else '✓'} {repo.name}: broken links {len(remaining)}{note}")
    return 1 if remaining else 0


if __name__ == "__main__":
    sys.exit(main())
