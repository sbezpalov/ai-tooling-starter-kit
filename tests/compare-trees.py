#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Побайтовое сравнение двух деревьев, развёрнутых разными реализациями init-ai-tooling.

Три скрипта (bash / PowerShell / Python) обязаны давать идентичный результат.
Единственное допустимое расхождение — строка-подпись генератора в конце
AGENTS.md и .ai/README.md, она нормализуется.

Переводы строк НЕ нормализуются намеренно: все три реализации обязаны писать LF
на любой ОС, и расхождение здесь — это баг, который тест должен ловить.

Использование:
    python3 tests/compare-trees.py КАТАЛОГ_A КАТАЛОГ_B
Код возврата: 0 — деревья совпадают, 1 — есть расхождения.
"""
import os
import re
import sys

SIGNATURE = re.compile(rb"init[-_]ai[-_]tooling(?:\.(?:sh|ps1|py))? v2")


def configure_stdio():
    """UTF-8 stdout/stderr: иначе на Windows (cp1252) print с кириллицей падает."""
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, OSError, ValueError):
            pass


def snapshot(root):
    """{относительный путь -> содержимое} для всех файлов дерева."""
    files = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames.sort()
        for name in sorted(filenames):
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, root).replace(os.sep, "/")
            with open(full, "rb") as fh:
                files[rel] = SIGNATURE.sub(b"init-ai-tooling v2", fh.read())
    return files


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    a_root, b_root = argv[1], argv[2]
    a, b = snapshot(a_root), snapshot(b_root)

    problems = []
    for rel in sorted(set(a) - set(b)):
        problems.append("только в %s: %s" % (a_root, rel))
    for rel in sorted(set(b) - set(a)):
        problems.append("только в %s: %s" % (b_root, rel))
    for rel in sorted(set(a) & set(b)):
        if a[rel] != b[rel]:
            problems.append("различается содержимое: %s" % rel)
            if b"\r\n" in a[rel] or b"\r\n" in b[rel]:
                problems.append("    ^ обнаружены CRLF — ожидается LF на всех ОС")

    if problems:
        print("РАСХОЖДЕНИЯ (%d):" % len(problems))
        for p in problems:
            print("  " + p)
        return 1

    print("Деревья идентичны: %d файлов." % len(a))
    return 0


if __name__ == "__main__":
    configure_stdio()
    sys.exit(main(sys.argv))

