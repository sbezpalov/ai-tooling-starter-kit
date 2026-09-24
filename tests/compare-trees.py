#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Byte-for-byte comparison of two trees scaffolded by equivalent init implementations.

Covers init-ai-tooling and init-repo-bootstrap (bash / PowerShell / Python).
The only allowed divergence is the generator signature line (release semver);
it is normalized. Codex contract checks run only for AI-family trees
(AGENTS.md present). Repo-family trees get a lightweight governance stub check.

Line endings are deliberately NOT normalized: all implementations must write LF
on every OS, and a mismatch here is a bug the test must catch.

Usage:
    python3 tests/compare-trees.py DIR_A DIR_B
Exit codes: 0 — trees match, 1 — differences found.
"""
import os
import re
import sys

SIGNATURE = re.compile(
    rb"init[-_](?:ai[-_]tooling|repo[-_]bootstrap)(?:\.(?:sh|ps1|py))? \d+\.\d+\.\d+"
)

CODEX_CONTRACT = {
    "AGENTS.md": (
        b"Codex, Cursor, Google Antigravity/Gemini",
        b"Codex reads this file natively and uses the shared artifacts directory.",
    ),
    ".ai/README.md": (
        b"| Codex (CLI / IDE / app) |",
        b"optional `.codex/config.toml`",
    ),
}

# Claude Code loads AGENTS.md only via an explicit import line; a prose redirect
# depends on the model choosing to open the file.
CLAUDE_IMPORT_LINE = b"\n@AGENTS.md\n"

CODEX_FORBIDDEN_PATHS = {
    "CODEX.md",
    ".codex/config.toml",
    ".codex/artifacts/.gitkeep",
}

REPO_REQUIRED_PATHS = (
    "LICENSE",
    "SECURITY.md",
    "CHANGELOG.md",
    "CONTRIBUTING.md",
)

REPO_LICENSE_MARKERS = (
    b"LICENSE NOT CHOSEN",
    b"It is NOT a grant of rights.",
)


def configure_stdio():
    """UTF-8 stdout/stderr: otherwise Windows (cp1252) can fail on non-ASCII prints."""
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, OSError, ValueError):
            pass


def snapshot(root):
    """{relative path -> content} for every file in the tree."""
    files = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames.sort()
        for name in sorted(filenames):
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, root).replace(os.sep, "/")
            with open(full, "rb") as fh:
                files[rel] = SIGNATURE.sub(b"init-tooling VERSION", fh.read())
    return files


def validate_codex_contract(files, root):
    """Verify explicit native Codex support without redundant Codex files."""
    problems = []
    for rel, required_fragments in CODEX_CONTRACT.items():
        content = files.get(rel)
        if content is None:
            problems.append("Codex contract missing in %s: %s" % (root, rel))
            continue
        for fragment in required_fragments:
            if fragment not in content:
                problems.append(
                    "Codex contract text missing in %s: %s" % (root, rel)
                )
    for rel in sorted(CODEX_FORBIDDEN_PATHS & set(files)):
        problems.append("Codex contract forbids generated path in %s: %s" % (root, rel))
    return problems


def validate_claude_contract(files, root):
    """Verify CLAUDE.md imports AGENTS.md instead of merely pointing at it."""
    content = files.get("CLAUDE.md")
    if content is None:
        return ["Claude contract missing in %s: CLAUDE.md" % root]
    if CLAUDE_IMPORT_LINE not in content:
        return ["Claude contract in %s: CLAUDE.md lacks an '@AGENTS.md' import line" % root]
    return []


def validate_repo_contract(files, root):
    """Verify inert governance stubs (no silent real license)."""
    problems = []
    for rel in REPO_REQUIRED_PATHS:
        if rel not in files:
            problems.append("repo contract missing in %s: %s" % (root, rel))
    license_content = files.get("LICENSE")
    if license_content is not None:
        for marker in REPO_LICENSE_MARKERS:
            if marker not in license_content:
                problems.append(
                    "repo LICENSE stub marker missing in %s: %s" % (root, marker)
                )
        if b"Permission is hereby granted" in license_content:
            problems.append(
                "repo LICENSE looks like a real MIT grant in %s (expected inert stub)"
                % root
            )
    return problems


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    a_root, b_root = argv[1], argv[2]
    a, b = snapshot(a_root), snapshot(b_root)

    problems = []
    for rel in sorted(set(a) - set(b)):
        problems.append("only in %s: %s" % (a_root, rel))
    for rel in sorted(set(b) - set(a)):
        problems.append("only in %s: %s" % (b_root, rel))
    for rel in sorted(set(a) & set(b)):
        if a[rel] != b[rel]:
            problems.append("content differs: %s" % rel)
            if b"\r\n" in a[rel] or b"\r\n" in b[rel]:
                problems.append("    ^ CRLF found — LF expected on every OS")

    if "AGENTS.md" in a:
        problems.extend(validate_codex_contract(a, a_root))
        problems.extend(validate_claude_contract(a, a_root))
    # Independent of Codex: also-repo trees carry both families.
    if "LICENSE" in a:
        problems.extend(validate_repo_contract(a, a_root))

    if problems:
        print("DIFFERENCES (%d):" % len(problems))
        for p in problems:
            print("  " + p)
        return 1

    print("Trees are identical: %d files." % len(a))
    return 0


if __name__ == "__main__":
    configure_stdio()
    sys.exit(main(sys.argv))
