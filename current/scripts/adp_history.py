#!/usr/bin/env python3
"""adp_history.py — what the version history says the work actually was.

Derives the output mix of an agentic development install from git history:
how many lines went to production code, to tests, and to documentation, over
what period, at what commit cadence.

The motivating question: in agent-driven development the durable asset is
claimed to be the specification rather than the code. That is a testable
claim about where the effort went, and git already holds the answer.

Usage:
  python scripts/adp_history.py [repo_root] [--since YYYY-MM-DD] [--json out.json]

Method, stated so the number can be disputed:
  * Counts LINES ADDED per file, from `git log --numstat`, across all refs,
    excluding merge commits (whose numstat double-counts).
  * Lines added is a proxy for effort, and an imperfect one: it rewards
    verbose work and ignores deletion, review and thought. It is used because
    it is the only quantity git records without additional bookkeeping.
  * Generated artifacts are EXCLUDED, not counted as tests or config:
    dependency trees, build output, debug dumps, recorded test output and
    replay fixtures. Including them distorts the result by more than the
    result itself — in the install this was written against, three debug JSON
    dumps alone carried 144,000 lines.
  * Classification is by path and extension. A file matching several rules is
    classified by the first that matches, tests before docs before code.

Stdlib only — no dependencies.
"""

from __future__ import annotations

import argparse
import collections
import json
import re
import subprocess
import sys
from pathlib import Path

# Generated or recorded output. Not authored, so not evidence of effort.
EXCLUDE = re.compile(
    r'(^|/)(node_modules|dist|build|out|\.venv|venv|__pycache__|\.pytest_cache'
    r'|coverage|htmlcov|debug_files|test_output|replays|fixtures?|snapshots?'
    r'|\.next|vendor|third_party)(/|$)'
    r'|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|poetry\.lock|Cargo\.lock'
    r'|\.min\.(js|css)$|\.map$|\.lock$'
)

TEST_DIR = re.compile(r'(^|/)(tests?|__tests__|spec|e2e|integration-tests|[a-z-]*-tests)(/|$)')
DOC_DIR = re.compile(r'(^|/)(docs?|documentation|adr|rfcs?)(/|$)')

CODE_EXT = ('.py', '.js', '.jsx', '.ts', '.tsx', '.mjs', '.cjs', '.go', '.rs',
            '.java', '.kt', '.rb', '.php', '.c', '.h', '.cpp', '.hpp', '.cs',
            '.sh', '.bash', '.rules', '.html', '.css', '.scss', '.vue', '.sql')
DOC_EXT = ('.md', '.rst', '.adoc', '.txt')
CONF_EXT = ('.json', '.yml', '.yaml', '.toml', '.ini', '.cfg', '.conf', '.env')
CONF_NAME = {'.gitignore', 'Dockerfile', 'Makefile', 'Procfile'}


def classify(path: str) -> str | None:
    """Return category, or None if the path is excluded."""
    if EXCLUDE.search(path):
        return None
    low = path.lower()
    base = path.rsplit('/', 1)[-1]
    if (TEST_DIR.search(low)
            or base.startswith('test_')
            or base.endswith(('_test.py', '.test.js', '.test.jsx', '.test.ts',
                              '.test.tsx', '.spec.js', '.spec.ts'))):
        return 'tests'
    if DOC_DIR.search(low) or low.endswith(DOC_EXT):
        return 'docs'
    if low.endswith(CODE_EXT):
        return 'code'
    if low.endswith(CONF_EXT) or base in CONF_NAME:
        return 'config'
    return 'other'


def git(root: Path, *args: str) -> str:
    r = subprocess.run(['git', '-C', str(root), *args],
                       capture_output=True, text=True, errors='replace')
    if r.returncode != 0:
        print(r.stderr.strip(), file=sys.stderr)
    return r.stdout


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('root', nargs='?', default='.')
    ap.add_argument('--since', metavar='YYYY-MM-DD')
    ap.add_argument('--json', metavar='FILE')
    args = ap.parse_args(argv)

    root = Path(args.root).resolve()
    if not (root / '.git').exists():
        print(f'not a git repository: {root}', file=sys.stderr)
        return 2

    log_args = ['log', '--all', '--no-merges', '--numstat',
                '--format=@@%H|%ad', '--date=short']
    if args.since:
        log_args.append(f'--since={args.since}')

    added = collections.Counter()
    deleted = collections.Counter()
    files = collections.defaultdict(set)
    per_month_commits = collections.Counter()
    per_month_added = collections.defaultdict(collections.Counter)
    commits = 0
    month = None
    first = last = None

    for line in git(root, *log_args).splitlines():
        if line.startswith('@@'):
            _, date = line[2:].split('|', 1)
            month = date[:7]
            per_month_commits[month] += 1
            commits += 1
            first = date if first is None else min(first, date)
            last = date if last is None else max(last, date)
            continue
        parts = line.split('\t')
        if len(parts) != 3 or parts[0] == '-':
            continue
        cat = classify(parts[2])
        if cat is None:
            continue
        added[cat] += int(parts[0])
        deleted[cat] += int(parts[1])
        files[cat].add(parts[2])
        if month:
            per_month_added[month][cat] += int(parts[0])

    total = sum(added.values())
    triad = added['docs'] + added['tests'] + added['code']
    if not total:
        print('no countable history found', file=sys.stderr)
        return 1

    print('=' * 68)
    print(f'GIT HISTORY — {root.name}')
    print('=' * 68)
    print(f'commits (all refs, merges excluded): {commits:,}')
    print(f'period: {first} to {last}')
    print()
    print('LINES ADDED BY CATEGORY   (generated artifacts excluded)')
    print(f"  {'category':9} {'added':>10} {'deleted':>10} {'% all':>7} {'% triad':>8}  files")
    for cat in ('code', 'tests', 'docs', 'config', 'other'):
        if not added[cat]:
            continue
        pt = f'{100*added[cat]/triad:6.1f}%' if cat in ('code', 'tests', 'docs') else '      —'
        print(f'  {cat:9} {added[cat]:>10,} {deleted[cat]:>10,} '
              f'{100*added[cat]/total:6.1f}% {pt}  {len(files[cat]):>5,}')
    print(f"  {'TOTAL':9} {total:>10,}")
    print()
    print('THE OUTPUT MIX  (docs + tests + code only)')
    print(f"  documentation + tests : {100*(added['docs']+added['tests'])/triad:.1f}%")
    print(f"  production code       : {100*added['code']/triad:.1f}%")
    print()
    print('COMMITS PER MONTH')
    for m in sorted(per_month_commits):
        n = per_month_commits[m]
        print(f'  {m}  {n:>5,}  ' + '#' * min(60, n // 20))
    print()
    print('HONEST LIMITS')
    print('  - Lines added is a proxy for effort. It rewards verbosity and')
    print('    ignores deletion, review, and thinking. It is used because git')
    print('    records it without extra bookkeeping, not because it is right.')
    print('  - Classification is by path and extension; a repository with')
    print('    unusual layout will be misclassified. Read the rules before')
    print('    quoting the number.')
    print('  - Counts move as the repository moves. Quote a commit, not a date.')

    if args.json:
        Path(args.json).write_text(json.dumps({
            'repo': root.name, 'commits': commits, 'first': first, 'last': last,
            'added': dict(added), 'deleted': dict(deleted),
            'files': {k: len(v) for k, v in files.items()},
            'per_month_commits': dict(per_month_commits),
            'per_month_added': {m: dict(c) for m, c in per_month_added.items()},
        }, indent=2), encoding='utf-8')
        print(f'\njson written: {args.json}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
