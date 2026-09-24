#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fixture and checker for --prune-legacy / -PruneLegacy.

    python3 tests/legacy-fixture.py create DIR
        Populate DIR with every legacy path from templates/ai/layout.json, plus one
        user-saved artifact inside a legacy artifacts folder.
    python3 tests/legacy-fixture.py verify DIR REPORT
        Fail unless every fixture path still exists (the report must not delete
        anything) and REPORT (captured stdout) matches the expected report.
    python3 tests/legacy-fixture.py verify-empty REPORT
        Fail unless REPORT is the "none found" report.

REPORT may be UTF-8 or UTF-16 (Windows PowerShell 5.1 redirection); CRLF is ignored.
Exit codes: 0 — ok, 1 — mismatch, 2 — usage.
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAVED_ARTIFACT = ".perplexity/artifacts/2026-01-01-research.md"
HEADER = "Legacy paths from earlier kit versions (nothing is deleted):"
FOOTER = "Review each path, then remove it, e.g.: git rm -r <path>"


def load_layout():
    with open(os.path.join(ROOT, "templates", "ai", "layout.json"), encoding="utf-8") as fh:
        return json.load(fh)


def fixture_paths(layout):
    files = list(layout["legacy_files"])
    files += [d + "/.gitkeep" for d in layout["legacy_artifact_dirs"]]
    return files + [SAVED_ARTIFACT]


def create(root):
    for rel in fixture_paths(load_layout()):
        path = os.path.join(root, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write("" if rel.endswith(".gitkeep") else "legacy\n")
    return 0


def expected_report(layout):
    lines = [HEADER] + ["  " + rel for rel in layout["legacy_files"]]
    saved_dir = os.path.dirname(SAVED_ARTIFACT)
    for rel in layout["legacy_artifact_dirs"]:
        if rel == saved_dir:
            lines.append("  %s/ (1 saved item(s): move them to .ai/artifacts/ first)" % rel)
        else:
            lines.append("  %s/" % rel)
    return lines + [FOOTER]


def read_report(path):
    with open(path, "rb") as fh:
        raw = fh.read()
    if raw.startswith(b"\xff\xfe") or raw.startswith(b"\xfe\xff"):
        text = raw.decode("utf-16")
    else:
        text = raw.decode("utf-8-sig")
    return [line.rstrip("\r") for line in text.split("\n") if line.strip()]


def compare(actual, expected):
    if actual == expected:
        return []
    return (["report mismatch", "  expected:"] + ["    " + line for line in expected]
            + ["  actual:"] + ["    " + line for line in actual])


def verify(root, report):
    layout = load_layout()
    problems = ["deleted by --prune-legacy: " + rel
                for rel in fixture_paths(layout)
                if not os.path.exists(os.path.join(root, rel))]
    problems += compare(read_report(report), expected_report(layout))
    return finish(problems)


def verify_empty(report):
    return finish(compare(read_report(report), [HEADER, "  none found"]))


def finish(problems):
    for line in problems:
        print(line)
    if not problems:
        print("prune-legacy report OK")
    return 1 if problems else 0


def main(argv):
    if len(argv) == 3 and argv[1] == "create":
        return create(argv[2])
    if len(argv) == 4 and argv[1] == "verify":
        return verify(argv[2], argv[3])
    if len(argv) == 3 and argv[1] == "verify-empty":
        return verify_empty(argv[2])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
