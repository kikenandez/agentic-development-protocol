#!/usr/bin/env python3
"""Regression cases for adp_bounds.py. Usage: python3 test_adp_bounds.py  (stdlib only)

Builds throwaway ADP-shaped repos in a temp dir and checks the exit code and
the report lines. Mirrors the install's own convention (process.md §10 target
≤800 lines / mechanical trigger ~1000; §10.2 memory read layer ≤200 lines).
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT = Path(__file__).with_name("adp_bounds.py")

DISPATCH = "## Dispatch — architect-maintained (updated 2026-10-10)\n"


def make_repo(current_lines: int, dispatch_lines: int, memory_lines: int | None,
              current_bytes_pad: int = 0) -> Path:
    root = Path(tempfile.mkdtemp(prefix="adp-bounds-"))
    tasks = root / "docs" / "tasks"
    tasks.mkdir(parents=True)
    body = ["# Active Tasks", "", DISPATCH.rstrip("\n")]
    body += [f"- dispatch line {i}" for i in range(dispatch_lines)]
    body += ["", "---", "", "## Active tasks", ""]
    remaining = max(current_lines - len(body), 0)
    body += [f"line {i}" for i in range(remaining)]
    text = "\n".join(body) + "\n" + ("x" * current_bytes_pad)
    (tasks / "current.md").write_text(text, encoding="utf-8")
    if memory_lines is not None:
        mem = root / "memory"
        mem.mkdir()
        (mem / "CLAUDE.md").write_text("\n".join(f"m{i}" for i in range(memory_lines)) + "\n",
                                       encoding="utf-8")
    return root


def run(root: Path, *args: str) -> tuple[int, str]:
    p = subprocess.run([sys.executable, "-I", str(SCRIPT), str(root), *args],
                       capture_output=True, text=True, timeout=30)
    return p.returncode, p.stdout + p.stderr


CASES = [
    # (name, repo kwargs, extra args, expected exit, substring that must appear)
    ("all within target", dict(current_lines=300, dispatch_lines=20, memory_lines=50), (), 0, "OK"),
    ("above target, below trigger → warn only", dict(current_lines=900, dispatch_lines=20, memory_lines=50), (), 0, "WARN"),
    ("above target with --strict → fail", dict(current_lines=900, dispatch_lines=20, memory_lines=50), ("--strict",), 1, "WARN"),
    ("above mechanical trigger → fail", dict(current_lines=1100, dispatch_lines=20, memory_lines=50), (), 1, "FAIL"),
    ("memory read layer over 200 lines → fail", dict(current_lines=300, dispatch_lines=20, memory_lines=250), (), 1, "memory/CLAUDE.md"),
    ("memory file absent → not an error", dict(current_lines=300, dispatch_lines=20, memory_lines=None), (), 0, "OK"),
    ("dispatch block oversized → warn", dict(current_lines=300, dispatch_lines=120, memory_lines=50), (), 0, "Dispatch"),
    ("current.md bytes over cap → fail", dict(current_lines=300, dispatch_lines=20, memory_lines=50, current_bytes_pad=70000), (), 1, "bytes"),
    ("custom --max-lines honoured", dict(current_lines=300, dispatch_lines=20, memory_lines=50), ("--max-lines", "250"), 1, "FAIL"),
]


def main() -> int:
    fails = 0
    for name, kw, args, want_rc, needle in CASES:
        root = make_repo(**kw)
        rc, out = run(root, *args)
        if rc != want_rc or needle not in out:
            fails += 1
            print(f"FAIL {name!r}: want rc={want_rc} containing {needle!r}, got rc={rc}\n{out}")
    # missing current.md is a usage error, not a pass
    empty = Path(tempfile.mkdtemp(prefix="adp-bounds-empty-"))
    rc, out = run(empty)
    if rc != 2 or "not found" not in out:
        fails += 1
        print(f"FAIL 'missing current.md': want rc=2 'not found', got rc={rc}\n{out}")
    total = len(CASES) + 1
    print(f"{total - fails}/{total} passed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
