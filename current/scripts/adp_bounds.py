#!/usr/bin/env python3
"""adp_bounds.py — mechanical size caps for the standing-context files (ADP §10).

Turns three pieces of advice into a check that can fail a hook or a CI step:

  docs/tasks/current.md   process.md §10: target ≤800 lines active content,
                          mechanical cleanup trigger at ~1000 lines (FAIL);
                          plus a byte cap, because a 66K-token task file is
                          what the 1.2 simplification candidate was cut from.
  Dispatch block          the part every session reads first — WARN when it
                          outgrows a screenful (the "what's next" block is
                          not where closed-task bodies belong).
  memory/CLAUDE.md        PROTOCOL.md §10.2: hard cap 200 lines — it is
                          re-injected on every /compact, so every line is
                          paid for repeatedly (FAIL).

Usage:
  python scripts/adp_bounds.py [repo_root] [--strict]
      [--max-lines 1000] [--target-lines 800] [--max-bytes 65536]
      [--max-dispatch-lines 60] [--max-memory-lines 200]

Exit codes: 0 within bounds (warnings allowed unless --strict), 1 a cap was
breached, 2 usage error (not an ADP repo). Stdlib only — no dependencies.

The advice stays in process.md; the check lives here so a hook or a CI step
can run it (new in tooling 1.1.7).
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

DISPATCH_HEADING_RE = re.compile(r"^##\s+Dispatch\b", re.I)
SECTION_BREAK_RE = re.compile(r"^(---\s*$|##\s)")


@dataclass(frozen=True)
class Finding:
    level: str  # "OK" | "WARN" | "FAIL"
    subject: str
    detail: str

    def line(self) -> str:
        return f"  {self.level:4} {self.subject:<22} {self.detail}"


@dataclass(frozen=True)
class Caps:
    max_lines: int
    target_lines: int
    max_bytes: int
    max_dispatch_lines: int
    max_memory_lines: int


def count_lines(text: str) -> int:
    return text.count("\n") + (1 if text and not text.endswith("\n") else 0)


def dispatch_block_lines(text: str) -> int | None:
    """Lines from the Dispatch heading to the next `---` or `## ` heading."""
    lines = text.splitlines()
    start = next((i for i, ln in enumerate(lines) if DISPATCH_HEADING_RE.match(ln)), None)
    if start is None:
        return None
    end = next((i for i in range(start + 1, len(lines)) if SECTION_BREAK_RE.match(lines[i])),
               len(lines))
    return end - start


def check_current(path: Path, caps: Caps) -> list[Finding]:
    text = path.read_text(encoding="utf-8", errors="replace")
    n_lines = count_lines(text)
    n_bytes = path.stat().st_size
    out: list[Finding] = []

    if n_lines > caps.max_lines:
        out.append(Finding("FAIL", "current.md lines",
                           f"{n_lines} > {caps.max_lines} (process.md §10 mechanical trigger — archive-stub pass due)"))
    elif n_lines > caps.target_lines:
        out.append(Finding("WARN", "current.md lines",
                           f"{n_lines} > target {caps.target_lines} (process.md §10)"))
    else:
        out.append(Finding("OK", "current.md lines", f"{n_lines} ≤ {caps.target_lines}"))

    if n_bytes > caps.max_bytes:
        out.append(Finding("FAIL", "current.md bytes",
                           f"{n_bytes} > {caps.max_bytes} bytes — closed-task bodies belong in docs/tasks/archive/"))
    else:
        out.append(Finding("OK", "current.md bytes", f"{n_bytes} ≤ {caps.max_bytes}"))

    d = dispatch_block_lines(text)
    if d is None:
        out.append(Finding("WARN", "Dispatch block", "no '## Dispatch' heading found (process.md §3a)"))
    elif d > caps.max_dispatch_lines:
        out.append(Finding("WARN", "Dispatch block",
                           f"{d} lines > {caps.max_dispatch_lines} — Dispatch is 'what's next', not a status log"))
    else:
        out.append(Finding("OK", "Dispatch block", f"{d} lines ≤ {caps.max_dispatch_lines}"))
    return out


def check_memory(path: Path, caps: Caps) -> list[Finding]:
    if not path.exists():
        return [Finding("OK", "memory/CLAUDE.md", "absent (no read layer installed)")]
    n = count_lines(path.read_text(encoding="utf-8", errors="replace"))
    if n > caps.max_memory_lines:
        return [Finding("FAIL", "memory/CLAUDE.md",
                        f"{n} lines > {caps.max_memory_lines} (PROTOCOL.md §10.2 hard cap — re-injected on every /compact)")]
    return [Finding("OK", "memory/CLAUDE.md", f"{n} lines ≤ {caps.max_memory_lines}")]


def verdict(findings: list[Finding], strict: bool) -> int:
    levels = {f.level for f in findings}
    if "FAIL" in levels:
        return 1
    if strict and "WARN" in levels:
        return 1
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="ADP standing-context size caps (§10).")
    ap.add_argument("root", nargs="?", default=".")
    ap.add_argument("--strict", action="store_true", help="treat WARN as failure")
    ap.add_argument("--max-lines", type=int, default=1000)
    ap.add_argument("--target-lines", type=int, default=800)
    ap.add_argument("--max-bytes", type=int, default=65536)
    ap.add_argument("--max-dispatch-lines", type=int, default=60)
    ap.add_argument("--max-memory-lines", type=int, default=200)
    a = ap.parse_args()

    root = Path(a.root).resolve()
    current = root / "docs" / "tasks" / "current.md"
    if not current.exists():
        print(f"error: {current} not found — is this an ADP repo?", file=sys.stderr)
        return 2
    caps = Caps(a.max_lines, a.target_lines, a.max_bytes, a.max_dispatch_lines, a.max_memory_lines)

    findings = check_current(current, caps) + check_memory(root / "memory" / "CLAUDE.md", caps)
    rc = verdict(findings, a.strict)

    print(f"ADP bounds — {root.name}")
    for f in findings:
        print(f.line())
    print({0: "RESULT: OK", 1: "RESULT: FAIL — caps breached (see PROTOCOL.md §10, process.md §10)"}[rc]
          + (" [--strict]" if a.strict and rc else ""))
    return rc


if __name__ == "__main__":
    sys.exit(main())
