#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Byte-for-byte comparison of two trees scaffolded by different init-ai-tooling implementations.

The three scripts (bash / PowerShell / Python) must produce identical output.
The only allowed divergence is the generator signature line at the end of
AGENTS.md and .ai/README.md (release semver); it is normalized.

Line endings are deliberately NOT normalized: all three implementations must
write LF on every OS, and a mismatch here is a bug the test must catch.

Usage:
    python3 tests/compare-trees.py DIR_A DIR_B
Exit codes: 0 — trees match, 1 — differences found.
"""
import os
import re
import sys

SIGNATURE = re.compile(rb"init[-_]ai[-_]tooling(?:\.(?:sh|ps1|py))? \d+\.\d+\.\d+")


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
                files[rel] = SIGNATURE.sub(b"init-ai-tooling VERSION", fh.read())
    return files


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
