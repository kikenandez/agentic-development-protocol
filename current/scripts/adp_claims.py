#!/usr/bin/env python3
"""adp_claims.py — the claim scorecard (MEASUREMENT.md §2).

Executes the counting rule that MEASUREMENT.md defines but never ran:

    "529 accepted / 22 falsified" counts terminal verdicts on claims.
    Claims are counted at the verdict, not at the assertion.
    Task acceptance verdicts, rule ratifications and protocol-audit
    findings all count.

Every counted item is emitted with its file and line number, so the output
IS the receipts table — a reader who clones the repo can re-run this and
land on the same rows, or dispute any individual one.

Usage:
  python scripts/adp_claims.py [repo_root] [--table receipts.md] [--csv out.csv]
                               [--since YYYY-MM-DD] [--verbose]

Design rules, so the number stays honest:
  * No target. Nothing here is tuned to reproduce a previously published
    figure. If the count disagrees with the paper, the paper is what moves.
  * Provenance or it doesn't count. An item with no file:line is not emitted.
  * Over-count nothing. The pointer layer (ARCHIVE_INDEX.md) restates verdicts
    recorded in the task files; it is excluded by default (--include-index to
    override) because counting both double-counts the same verdict.
  * Report blindness. Section 4 of the output lists what this script cannot
    see. A count without its blind spots is marketing.

Stdlib only — no dependencies.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import date, datetime
from pathlib import Path

# --------------------------------------------------------------------------
# Verdict vocabulary
#
# Derived by reading the two live installs (nexus_pmo, XIAO_PlantSystem)
# rather than from the protocol text, because the installs are the ground
# truth for what actually gets written. Where an install uses a phrasing not
# listed here, it is invisible to this script — see report section 4.
# --------------------------------------------------------------------------

DATE_RE = re.compile(r"(\d{4}-\d{2}-\d{2})")

PATTERNS: dict[str, re.Pattern[str]] = {
    # --- terminal verdicts on task acceptance (MEASUREMENT.md §2) ---
    # NB: written first as `ACCEPTED?` — which means "ACCEPTE" plus an optional
    # "D", and therefore matched NEITHER "ACCEPT" nor most real verdicts. It
    # reported 59 where the true count is 424. Logged rather than silently
    # corrected: an instrument's first run is a hypothesis about itself.
    "ACCEPT": re.compile(r"\bACCEPT(ED)?\b"),
    "RETURN_FOR_FIX": re.compile(r"\bRETURN[- ]FOR[- ]FIX\b", re.I),
    "PROVISIONAL": re.compile(r"\bPROVISIONAL\b"),
    # --- terminal verdicts on asserted claims ---
    # FALSIFIED: a claim accepted-then-overturned, or asserted-then-disproven
    # at a gate. This is the count the paper's headline depends on.
    "FALSIFIED": re.compile(r"\bFALSIFIED\b"),
    # CONFIRMED: the other terminal verdict on a pre-registered VERIFY claim.
    # Counting only FALSIFIED without CONFIRMED would report the failures of
    # the mechanism and hide its successes — the mirror of the error
    # MEASUREMENT.md §6 warns about for miss-only ledgers.
    "CONFIRMED": re.compile(r"\bCONFIRMED\b"),
    "WITHDRAWN": re.compile(r"\bWITHDRAWN\b"),
    # --- rule lifecycle (MEASUREMENT.md §3) ---
    "RATIFIED": re.compile(r"\bRATIFIED\b", re.I),
    "PROMOTED": re.compile(r"\bPROMOTED\b", re.I),
    "UN_ADOPTED": re.compile(r"\bUN-?ADOPT(ED|ION)\b", re.I),
}

# Miss-ledger entry: "## #128 — ..." or "- **#128** — ..."
MISS_ENTRY_RE = re.compile(r"(?:^#{1,4}\s*|\*\*)#(\d{1,4})\b")
ESCAPE_RE = re.compile(r"Escape:\s*\**\s*(CAUGHT|ESCAPED)", re.I)

# Files that restate verdicts recorded elsewhere.
POINTER_FILES = {"ARCHIVE_INDEX.md"}

# Where installs keep things. First match wins; missing paths are reported.
ARCHIVE_DIRS = ["docs/tasks/archive"]
CURRENT_FILES = ["docs/tasks/current.md"]
MISS_LOG_CANDIDATES = [
    "docs/tasks/archive/process-misses-log.md",
    "docs/tasks/process-misses-log.md",
    "docs/retros/process-misses-log.md",
]


@dataclass
class Hit:
    kind: str
    path: str
    line_no: int
    excerpt: str
    task: str = ""
    day: str = ""
    unit: str = ""  # the claim unit this verdict is attributed to (see below)


@dataclass
class Report:
    root: Path
    hits: list[Hit] = field(default_factory=list)
    miss_ids: set[int] = field(default_factory=set)
    escapes: Counter = field(default_factory=Counter)
    files_scanned: int = 0
    missing_paths: list[str] = field(default_factory=list)
    miss_log: str = ""


TASK_RE = re.compile(r"\bT(\d{1,4}[a-z]?)\b")
# Task ids embedded in an archive filename: 2026-08-11-t556-t567-t560-....md
FNAME_TASK_RE = re.compile(r"-(t\d{1,4}[a-z]?)(?=-|\.)", re.I)


def excerpt_of(line: str, width: int = 120) -> str:
    s = " ".join(line.strip().split())
    return s[:width] + ("…" if len(s) > width else "")


def scan_file(path: Path, root: Path, rep: Report, since: date | None) -> None:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return
    rep.files_scanned += 1
    rel = str(path.relative_to(root))

    fname_day = ""
    m = DATE_RE.search(path.name)
    if m:
        fname_day = m.group(1)
        if since:
            try:
                if datetime.strptime(fname_day, "%Y-%m-%d").date() < since:
                    return
            except ValueError:
                pass

    # Claim unit attribution (see report section 2b). A verdict belongs to the
    # task it names on its own line; failing that, to the single task named by
    # the filename; failing that, to the file. Multi-task filenames deliberately
    # fall through to the file, because attributing a verdict to one of three
    # tasks named in a filename would be a guess.
    fname_tasks = [t.upper() for t in FNAME_TASK_RE.findall(path.name)]
    file_unit = fname_tasks[0] if len(fname_tasks) == 1 else f"file:{rel}"

    for i, line in enumerate(text.splitlines(), 1):
        for kind, pat in PATTERNS.items():
            for _ in pat.finditer(line):
                t = TASK_RE.search(line)
                task = ("T" + t.group(1)) if t else ""
                rep.hits.append(
                    Hit(
                        kind=kind,
                        path=rel,
                        line_no=i,
                        excerpt=excerpt_of(line),
                        task=task,
                        day=fname_day,
                        unit=task or file_unit,
                    )
                )


def scan_miss_log(path: Path, root: Path, rep: Report) -> None:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return
    rep.miss_log = str(path.relative_to(root))
    for line in text.splitlines():
        for m in MISS_ENTRY_RE.finditer(line):
            rep.miss_ids.add(int(m.group(1)))
        e = ESCAPE_RE.search(line)
        if e:
            rep.escapes[e.group(1).upper()] += 1


def collect(root: Path, since: date | None, include_index: bool) -> Report:
    rep = Report(root=root)

    for rel in ARCHIVE_DIRS:
        d = root / rel
        if not d.is_dir():
            rep.missing_paths.append(rel)
            continue
        for f in sorted(d.glob("*.md")):
            if not include_index and f.name in POINTER_FILES:
                continue
            if f.name.startswith("_"):
                continue
            scan_file(f, root, rep, since)

    for rel in CURRENT_FILES:
        f = root / rel
        if f.is_file():
            scan_file(f, root, rep, since)
        else:
            rep.missing_paths.append(rel)

    for rel in MISS_LOG_CANDIDATES:
        f = root / rel
        if f.is_file():
            scan_miss_log(f, root, rep)
            break
    else:
        rep.missing_paths.append("process-misses-log.md (none of the known locations)")

    return rep


def render(rep: Report, verbose: bool) -> str:
    c = Counter(h.kind for h in rep.hits)
    units: dict[str, set[str]] = defaultdict(set)
    for h in rep.hits:
        units[h.kind].add(h.unit)
    d = {k: len(v) for k, v in units.items()}

    out: list[str] = []
    a = out.append

    a(f"ADP claim scorecard — {rep.root.name} — {date.today().isoformat()}")
    a("=" * 68)
    a("")
    a("1. HEADLINE (MEASUREMENT.md §2 — terminal verdicts on claims)")
    a("")
    a("   Reported as a RANGE, not a point estimate. The two bounds are honest")
    a("   answers to two different questions, and the true count sits between:")
    a("")
    a(f"     accepted    {d.get('ACCEPT', 0):>5}  ..{c['ACCEPT']:>5}   (distinct claim units .. mentions)")
    a(f"     falsified   {d.get('FALSIFIED', 0):>5}  ..{c['FALSIFIED']:>5}")
    lo_a, hi_a = d.get("ACCEPT", 0), c["ACCEPT"]
    lo_f, hi_f = d.get("FALSIFIED", 0), c["FALSIFIED"]
    if lo_a + lo_f:
        a(f"     falsification rate  {100.0 * lo_f / (lo_a + lo_f):.1f}% .. "
          f"{100.0 * hi_f / (hi_a + hi_f):.1f}%")
    a("")
    a("   LOWER BOUND (distinct claim units): one verdict per task per kind.")
    a("     Under-counts, because a task legitimately falsifies more than one")
    a("     claim — a spec hypothesis at Gate-1 and a VERIFY line are two claims.")
    a("   UPPER BOUND (mentions): every occurrence, line by line.")
    a("     Over-counts, because task files restate their own verdict in")
    a("     summaries, status lines and follow-up references.")
    a("   Cite the lower bound if you cite one number. It is the defensible floor.")
    a("")
    a("2. VERDICT BREAKDOWN            units   mentions")
    for kind in PATTERNS:
        a(f"   {kind.lower().replace('_', '-'):<20} {d.get(kind, 0):>6} {c[kind]:>10}")
    a("")
    a("2b. HOW A VERDICT IS ATTRIBUTED")
    a("   to the task named on its own line; else to the task named by the")
    a("   filename when the filename names exactly one; else to the file.")
    a("   Multi-task archive files fall through to the file rather than guess.")
    a("")
    a("3. MISS LEDGER (MEASUREMENT.md §3)")
    if rep.miss_ids:
        lo, hi = min(rep.miss_ids), max(rep.miss_ids)
        gaps = sorted(set(range(lo, hi + 1)) - rep.miss_ids)
        a(f"   source        : {rep.miss_log}")
        a(f"   entries       : {len(rep.miss_ids)}  (#{lo}–#{hi})")
        a(f"   numbering gaps: {len(gaps)}" + (f"  {gaps[:20]}" if gaps else ""))
    else:
        a("   no miss ledger found")
    caught, escaped = rep.escapes["CAUGHT"], rep.escapes["ESCAPED"]
    a(f"   escape-classified: {caught + escaped} of {len(rep.miss_ids) or 0}"
      f"   (CAUGHT {caught} / ESCAPED {escaped})")
    if rep.miss_ids and (caught + escaped) < len(rep.miss_ids):
        a("   NOTE: classification introduced 2026-08; earlier entries are unclassified")
    a("")
    a("4. WHAT THIS COUNT CANNOT SEE  (state these wherever the numbers are cited)")
    a("   - Verdicts phrased outside the vocabulary in PATTERNS are invisible.")
    a("   - One line carrying two verdicts counts twice; a verdict spanning two")
    a("     lines counts once. Both are line-granularity artifacts.")
    a("   - The pointer layer is excluded, so a verdict recorded ONLY in the")
    a("     index and never in a task file is missed (--include-index to test).")
    a("   - A claim never written down was never counted. As MEASUREMENT.md §6")
    a("     says, this bounds failure from below, never above.")
    a("   - All counts are self-reported by the protocol's author. The audit")
    a("     that settles them is an independent install, not this script.")
    for p in rep.missing_paths:
        a(f"   - PATH NOT FOUND: {p}")
    a("")
    a(f"   files scanned: {rep.files_scanned}")

    if verbose:
        a("")
        a("5. RECEIPTS (first 40; use --table for the full table)")
        for h in rep.hits[:40]:
            a(f"   [{h.kind}] {h.path}:{h.line_no} {h.task}")
    return "\n".join(out)


def write_table(rep: Report, path: Path) -> None:
    by_kind: dict[str, list[Hit]] = defaultdict(list)
    for h in rep.hits:
        by_kind[h.kind].append(h)
    lines = [
        f"# Claim receipts — {rep.root.name} — {date.today().isoformat()}",
        "",
        "Generated by `scripts/adp_claims.py`. Every row is a terminal verdict on a",
        "claim, with the file and line it was recorded at. Re-runnable against a",
        "clone; individual rows are meant to be disputable.",
        "",
    ]
    for kind in PATTERNS:
        hits = by_kind.get(kind, [])
        if not hits:
            continue
        lines += [f"## {kind} ({len(hits)})", "", "| # | Task | Location | Line |", "|---|---|---|---|"]
        for n, h in enumerate(hits, 1):
            safe = h.excerpt.replace("|", "\\|")
            lines.append(f"| {n} | {h.task or '—'} | `{h.path}:{h.line_no}` | {safe} |")
        lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def write_csv(rep: Report, path: Path) -> None:
    with path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["kind", "task", "path", "line", "date", "excerpt"])
        for h in rep.hits:
            w.writerow([h.kind, h.task, h.path, h.line_no, h.day, h.excerpt])


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("root", nargs="?", default=".", help="install root (default: cwd)")
    ap.add_argument("--since", metavar="YYYY-MM-DD", help="only archives dated on/after")
    ap.add_argument("--table", metavar="FILE.md", help="write the full receipts table")
    ap.add_argument("--csv", metavar="FILE.csv", help="write all hits as CSV")
    ap.add_argument("--include-index", action="store_true",
                    help="also count the pointer layer (double-counts by design)")
    ap.add_argument("--verbose", action="store_true", help="print sample receipts")
    args = ap.parse_args(argv)

    root = Path(args.root).resolve()
    if not root.is_dir():
        print(f"not a directory: {root}", file=sys.stderr)
        return 2

    since = None
    if args.since:
        try:
            since = datetime.strptime(args.since, "%Y-%m-%d").date()
        except ValueError:
            print("--since must be YYYY-MM-DD", file=sys.stderr)
            return 2

    rep = collect(root, since, args.include_index)
    print(render(rep, args.verbose))

    if args.table:
        write_table(rep, Path(args.table))
        print(f"\nreceipts table written: {args.table}")
    if args.csv:
        write_csv(rep, Path(args.csv))
        print(f"csv written: {args.csv}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
