#!/usr/bin/env python3
"""adp_ledger_migrate.py — turn a prose miss ledger into a structured one.

The problem this solves: a miss ledger written as prose cannot be counted
reliably. Depending on the pattern used to read the source ledger this was
written against, the same file yields 66, 121 or 162 entries — none of them
wrong, none of them a fact. A published figure that moves when you change a
regular expression is not evidence.

This reads the prose ledger and emits `misses.yml`: one record per numbered
miss, with the fields the protocol actually reasons about. After that, every
question about the ledger is a query rather than an interpretation.

Usage:
  python scripts/adp_ledger_migrate.py <ledger.md> [-o misses.yml] [--report]

What it extracts, and what it cannot:
  * id, summary, and the lesson line where one is marked (🔑 / ⇒)
  * escape classification (CAUGHT / ESCAPED) where present
  * date, session, cost, and who caught it, where the entry records them
  * the enclosing session heading's date as a fallback date

  It cannot invent fields the prose never carried. Entries predating a
  convention come out with that field null, and the report says how many.
  That is the honest result: coverage is a fact about the ledger, and
  pretending otherwise would repeat the error this migration exists to fix.

Stdlib only — emits YAML by hand, no dependencies.
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from datetime import date
from pathlib import Path

# Entry openers. The source ledger has THREE shapes, written in two eras.
#
# A first version of this script knew only the two later shapes and silently
# dropped 93 of 159 entries — the same failure family the ledger itself
# records, reproduced by the tool built to read it. The legacy pattern below
# was added after an independent line count disagreed with the parser.
# Rather than enumerate punctuation variants — the ledger has at least four,
# written over six months — match the ONE thing every entry shares: a line that
# opens with the miss number. Everything before the bold closes is the header;
# date and session are then found wherever in it they happen to sit.
RICH = re.compile(r'^#{2,4}\s*#(\d{1,4})\s*[—–-]\s*(.+?)\s*$')
BULLET = re.compile(r'^-\s*\*\*#(\d{1,4})\b(.*?)\*\*\s*(.*)$')

HDR_DATE = re.compile(r'(\d{4}-\d{2}-\d{2})')
HDR_SESSION = re.compile(r'\b((?:ava_)?(?:architect|dev|designer|design|business|comms)[\w.]*)\b', re.I)

# Session heading, e.g. "## architect1508_01 (2026-08-15)" or "## `dev0908_03` (2026-09-08)"
SESSION_HEAD = re.compile(r'^#{2,4}\s*`?([A-Za-z][\w.-]*)`?\s*\((\d{4}-\d{2}-\d{2})')

FIELD = {
    'date': re.compile(r'\*\*Date:\*\*\s*`?(\d{4}-\d{2}-\d{2})'),
    'session': re.compile(r'\*\*Session:\*\*\s*`?([\w.-]+)'),
    'cost': re.compile(r'\*\*Cost:\*\*\s*([^·*\n]+)'),
    'caught_by': re.compile(r'\*\*Caught by:\*\*\s*([^·*\n]+)'),
}
ESCAPE = re.compile(r'Escape:?\s*`?\**\s*(CAUGHT|ESCAPED)', re.I)
LESSON = re.compile(r'(?:🔑|⇒)\s*\**_*([^*_\n][^\n]{15,200})')

STRIP_MD = re.compile(r'[*`_]|⇒|🔑|🔴|⚠️|⛔|✅|⚖️|🏅|📦')


def clean(s: str) -> str:
    s = STRIP_MD.sub('', s)
    return ' '.join(s.split()).strip(' .—–-')


def yaml_str(s: str) -> str:
    """Quote a scalar safely without a YAML library."""
    s = s.replace('\\', '\\\\').replace('"', '\\"')
    return f'"{s}"'


def parse(text: str) -> tuple[list[dict], list[str]]:
    lines = text.splitlines()
    entries: dict[int, dict] = {}
    order: list[int] = []
    dupes: list[str] = []
    ctx_session = ctx_date = None

    for i, line in enumerate(lines):
        h = SESSION_HEAD.match(line)
        if h and not RICH.match(line):
            ctx_session, ctx_date = h.group(1), h.group(2)
            continue

        inline_date = inline_session = None
        m = RICH.match(line)
        if m:
            mid, summary = int(m.group(1)), m.group(2)
        else:
            m = BULLET.match(line)
            if not m:
                continue
            mid = int(m.group(1))
            header, body = m.group(2) or '', m.group(3) or ''
            d = HDR_DATE.search(header)
            s = HDR_SESSION.search(header)
            inline_date = d.group(1) if d else None
            inline_session = s.group(1) if s else None
            # The headline is whatever the header carries once date/session and
            # punctuation are stripped; fall back to the body's opening clause.
            head = HDR_DATE.sub('', header)
            head = HDR_SESSION.sub('', head)
            head = clean(head.strip(' ():—–-'))
            summary = head if len(head) > 12 else clean(body)

        # The block belonging to this entry: until the next opener or heading.
        block = [line]
        for nxt in lines[i + 1:]:
            if RICH.match(nxt) or BULLET.match(nxt) or nxt.startswith('## '):
                break
            block.append(nxt)
        blob = '\n'.join(block)

        rec = {
            'id': mid,
            'summary': clean(summary)[:300],
            'date': None,
            'session': ctx_session,
            'escape': None,
            'cost': None,
            'caught_by': None,
            'lesson': None,
        }
        for key, pat in FIELD.items():
            f = pat.search(blob)
            if f:
                rec[key] = clean(f.group(1))[:120]
        e = ESCAPE.search(blob)
        if e:
            rec['escape'] = e.group(1).upper()
        l = LESSON.search(blob)
        if l:
            rec['lesson'] = clean(l.group(1))[:240]
        if not rec['date']:
            rec['date'] = inline_date or ctx_date
        if not rec['session']:
            rec['session'] = inline_session or ctx_session

        if mid in entries:
            dupes.append(f"#{mid} (line {i+1}) — kept the first occurrence")
            continue
        entries[mid] = rec
        order.append(mid)

    return [entries[k] for k in sorted(order)], dupes


def emit(recs: list[dict], src: str) -> str:
    out = [
        '# misses.yml — the process-miss ledger, structured.',
        '#',
        f'# Migrated from {src} by scripts/adp_ledger_migrate.py on {date.today()}.',
        '# Append new misses here. Every field the prose did not carry is null rather',
        '# than guessed — see the coverage report printed at migration time.',
        '#',
        '# escape: CAUGHT   — falsified at a gate before any code was written against it',
        '#         ESCAPED  — reached code, a commit, production, or a closed verdict',
        '#         null     — predates the classification (added 2026-08); not backfilled',
        '#',
        '# Only ESCAPED entries advance a candidate rule\'s recurrence counter.',
        '',
        'misses:',
    ]
    for r in recs:
        out.append(f'  - id: {r["id"]}')
        for k in ('date', 'session', 'escape', 'cost', 'caught_by'):
            out.append(f'    {k}: {yaml_str(r[k]) if r[k] else "null"}')
        out.append(f'    summary: {yaml_str(r["summary"])}')
        out.append(f'    lesson: {yaml_str(r["lesson"]) if r["lesson"] else "null"}')
        out.append('')
    return '\n'.join(out)


def report(recs: list[dict], dupes: list[str]) -> None:
    ids = [r['id'] for r in recs]
    lo, hi = min(ids), max(ids)
    gaps = sorted(set(range(lo, hi + 1)) - set(ids))
    esc = Counter(r['escape'] for r in recs)
    have = lambda k: sum(1 for r in recs if r[k])

    print(f'entries extracted : {len(recs)}  (#{lo}–#{hi})')
    print(f'numbering gaps    : {len(gaps)}' + (f'  {gaps}' if gaps and len(gaps) < 25 else ''))
    if dupes:
        print(f'duplicate openers : {len(dupes)} (first occurrence kept)')
        for d in dupes[:5]:
            print(f'                    {d}')
    print()
    print('FIELD COVERAGE — the honest part')
    for k in ('date', 'session', 'escape', 'cost', 'caught_by', 'lesson'):
        n = have(k)
        print(f'  {k:10} {n:>4} of {len(recs)}  ({100*n/len(recs):4.0f}%)')
    print()
    print('ESCAPE CLASSIFICATION')
    print(f'  CAUGHT     {esc["CAUGHT"]}')
    print(f'  ESCAPED    {esc["ESCAPED"]}')
    print(f'  unclassified {esc[None]}  — predates the convention; not invented here')
    if esc[None]:
        print()
        print('  NOTE: any escape-rate series computed today covers only the classified')
        print('        entries. Say so wherever the figure is published, or backfill first.')


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('ledger')
    ap.add_argument('-o', '--out', default='misses.yml')
    ap.add_argument('--report', action='store_true', help='print coverage only, write nothing')
    args = ap.parse_args(argv)

    src = Path(args.ledger)
    if not src.is_file():
        print(f'not found: {src}', file=sys.stderr)
        return 2

    recs, dupes = parse(src.read_text(encoding='utf-8', errors='replace'))
    if not recs:
        print('no numbered entries found — check the ledger format', file=sys.stderr)
        return 1

    report(recs, dupes)
    if not args.report:
        Path(args.out).write_text(emit(recs, src.name), encoding='utf-8')
        print(f'\nwritten: {args.out}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
