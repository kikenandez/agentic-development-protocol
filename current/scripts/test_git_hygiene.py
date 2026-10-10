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

def run(hook, cmd, env=None):
    payload = json.dumps({"tool_input": {"command": cmd}})
    argv = ["bash", str(H / "git-hygiene.sh")] if hook == "sh" else ["node", str(H / "git-hygiene.mjs")]
    p = subprocess.run(argv, input=payload, capture_output=True, text=True, timeout=10, env=env)
    out = p.stdout.strip()
    if not out:
        return "none", ""
    o = json.loads(out)["hookSpecificOutput"]
    return o["permissionDecision"], o.get("additionalContext", "")

fails = 0
for cmd, want in CASES:
    for hook in ("sh", "mjs"):
        got, _ = run(hook, cmd)
        if got != want:
            fails += 1
            print(f"FAIL [{hook}] {cmd!r}: want {want}, got {got}")

# §6.4 rule 1, pathspec form (n=2): a commit WITHOUT `-- <paths>` is allowed but
# the injected context must say so; a commit WITH a pathspec must not nag.
PATHSPEC_CASES = [
    ('git commit -m "x"', True),
    ("git commit -F msg.txt -- a.c b.c", False),
    ('git commit -m "x" -- docs/a.md', False),
    ('git commit -m "x -- not a pathspec"', True),   # inside the message only
]
for cmd, want_note in PATHSPEC_CASES:
    for hook in ("sh", "mjs"):
        dec, ctx = run(hook, cmd)
        has_note = "No pathspec" in ctx
        if dec != "allow" or has_note != want_note:
            fails += 1
            print(f"FAIL [{hook}] pathspec {cmd!r}: want allow note={want_note}, got {dec} note={has_note}")

# Fail VISIBLE without jq: the .sh twin must ASK on a git command, not no-op.
import os, shutil, tempfile
shim = Path(tempfile.mkdtemp(prefix="adp-nojq-"))
for tool in ("bash", "grep", "git", "sed", "cat", "date", "stat"):
    src = shutil.which(tool)
    if src:
        os.symlink(src, shim / tool)
nojq = {**os.environ, "PATH": str(shim)}
assert shutil.which("jq", path=str(shim)) is None, "shim PATH still finds jq"
for cmd, want in [("git add -A", "ask"), ("git commit -m x", "ask"), ("ls -la", "none")]:
    got, _ = run("sh", cmd, env=nojq)
    if got != want:
        fails += 1
        print(f"FAIL [sh, no jq] {cmd!r}: want {want}, got {got}")

total = len(CASES) * 2 + len(PATHSPEC_CASES) * 2 + 3
print(f"{total - fails}/{total} passed")
sys.exit(1 if fails else 0)
