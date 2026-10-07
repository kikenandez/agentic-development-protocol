#!/usr/bin/env python3
"""Regression cases for git-hygiene.{sh,mjs}. Usage: python3 test_git_hygiene.py <repo>/.claude/hooks   (needs bash+jq and node)"""
import json, subprocess, sys
from pathlib import Path

H = Path(sys.argv[1])
CASES = [
    # (command, expected decision: deny | ask | allow | none)
    ("git add -A", "deny"),
    ("git add .", "deny"),
    ("git add --all", "deny"),
    ('git add "-A"', "deny"),            # quoted flag bypass
    ("git add '.'", "deny"),             # quoted dot bypass
    ("git -C . add -A", "deny"),         # global option bypass
    ("git -c core.x=y add --all", "deny"),
    ("git add src/a.c .", "deny"),       # dot after a real path
    ("git add :/", "deny"),
    ("git add *", "deny"),
    ("rtk git add -A", "deny"),
    ("git commit -am wip", "deny"),
    ("git commit -a -m wip", "deny"),
    ('git commit "-a" -m x', "deny"),
    ("git commit --all -m x", "deny"),
    ("/usr/bin/git add -A", "deny"),     # path-prefixed binary (regression guard)
    ("echo `git add -A`", "deny"),       # backtick substitution (regression guard)
    ("x=$(git add .)", "deny"),
    ('git add -"A"', "deny"),            # partially quoted flag
    ("git add \\-A", "deny"),            # backslash-escaped flag
    ("git ad''d -A", "deny"),            # empty quotes inside the subcommand
    ("git -p add -A", "deny"),           # single-letter global option
    ("git --no-pager add --all", "deny"),
    ('git commit -m "fix: a; b && c" -a', "deny"),   # message with separators, then -a
    ("git commit -m \"don't stage\" -a", "deny"),    # apostrophe inside double quotes
    ("git reset --hard HEAD~1", "ask"),
    ("git -C /x reset --hard", "ask"),
    ("git push --force", "ask"),
    ("git push -f origin main", "ask"),
    ("git push origin +main", "ask"),
    ("git push --force-with-lease", "ask"),
    ("git branch -D old", "ask"),
    # must NOT be denied
    ("git add src/a.c docs/b.md", "none"),
    ('git commit -m "do not git add -A here"', "allow"),
    ("git commit -F msg.txt -- a.c b.c", "allow"),
    ("git commit --amend -m x", "allow"),
    ("git add a.c && ls -A", "none"),     # later command's -A
    ("git add a.c; echo .", "none"),
    ("git push origin main", "none"),
    ("git push --follow-tags", "none"),
    ("git branch -d merged", "none"),
    ("git reset --soft HEAD~1", "none"),
    ("ls -la", "none"),
    ("git add 'my file.c' docs/x.md", "none"),
    ('git commit -m "stage with git add -A next time"', "allow"),
    ("legit add -A", "none"),             # 'git' inside another word
    ("cat .git add -A", "none"),
]

def run(hook, cmd):
    payload = json.dumps({"tool_input": {"command": cmd}})
    argv = ["bash", str(H / "git-hygiene.sh")] if hook == "sh" else ["node", str(H / "git-hygiene.mjs")]
    out = subprocess.run(argv, input=payload, capture_output=True, text=True, timeout=10).stdout.strip()
    if not out:
        return "none"
    return json.loads(out)["hookSpecificOutput"]["permissionDecision"]

fails = 0
for cmd, want in CASES:
    for hook in ("sh", "mjs"):
        got = run(hook, cmd)
        if got != want:
            fails += 1
            print(f"FAIL [{hook}] {cmd!r}: want {want}, got {got}")
print(f"{len(CASES) * 2 - fails}/{len(CASES) * 2} passed")
sys.exit(1 if fails else 0)
