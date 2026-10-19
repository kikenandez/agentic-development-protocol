#!/usr/bin/env python3
"""Regression cases for mcp-git-guard.{sh,mjs}. Usage: python3 test_mcp_git_guard.py <repo>/.claude/hooks   (needs bash+jq and node)"""
import json, os, shutil, subprocess, sys, tempfile
from pathlib import Path

H = Path(sys.argv[1])
CASES = [
    # (MCP tool name, expected decision: ask | none)
    ("mcp__git__git_commit", "ask"),
    ("mcp__git__git_add", "ask"),
    ("mcp__git__git_reset", "ask"),
    ("mcp__git__git_checkout", "ask"),
    ("mcp__git__git_push", "ask"),
    ("mcp__github__push_files", "ask"),
    ("mcp__github__create_commit", "ask"),     # commit word, any server
    ("mcp__vcs__commit", "ask"),
    ("mcp__GitServer__Git-Commit", "ask"),     # case and dash separators
    ("mcp__plugin_x_git__git_add", "ask"),
    # read-only git tools and non-git MCP tools must NOT ask
    ("mcp__git__git_status", "none"),
    ("mcp__git__git_diff", "none"),
    ("mcp__git__git_diff_staged", "none"),
    ("mcp__git__git_log", "none"),
    ("mcp__git__git_show", "none"),
    ("mcp__git__git_create_branch", "none"),
    ("mcp__linear__add_comment", "none"),     # add, but no git
    ("mcp__todo__push_notification", "none"),  # push, but no git
    ("mcp__filesystem__write_file", "none"),
    ("mcp__github__get_file_contents", "none"),
    ("mcp__git__git_addendum", "none"),        # 'add' only as a whole word
    ("mcp__memory__commitment_list", "none"),  # 'commit' only as a whole word
]

def run(hook, payload, env=None):
    argv = ["bash", str(H / "mcp-git-guard.sh")] if hook == "sh" else ["node", str(H / "mcp-git-guard.mjs")]
    p = subprocess.run(argv, input=payload, capture_output=True, text=True, timeout=10, env=env)
    out = p.stdout.strip()
    if not out:
        return "none", ""
    o = json.loads(out)["hookSpecificOutput"]
    return o["permissionDecision"], o.get("permissionDecisionReason", "")

def payload(name):
    return json.dumps({"tool_name": name, "tool_input": {"repo_path": "."}})

fails = total = 0
def check(label, got, want):
    global fails, total
    total += 1
    if got != want:
        fails += 1
        print(f"FAIL {label}: want {want}, got {got}")

for name, want in CASES:
    for hook in ("sh", "mjs"):
        got, reason = run(hook, payload(name))
        check(f"[{hook}] {name!r}", got, want)
        # An ASK must say WHY: the Bash-only matcher, and the Bash route.
        if got == "ask":
            check(f"[{hook}] {name!r} reason", all(s in reason for s in ("Bash tool only", "-- <paths>", name)), True)

# Never a silent deny, and the kill switch is shared with git-hygiene.
for hook in ("sh", "mjs"):
    got, _ = run(hook, payload("mcp__git__git_commit"), env={**os.environ, "ADP_GIT_HOOK_DISABLE": "1"})
    check(f"[{hook}] kill switch", got, "none")
    got, _ = run(hook, "not json, but mentions git")
    check(f"[{hook}] unreadable payload mentioning git", got, "ask")
    got, _ = run(hook, "")
    check(f"[{hook}] empty payload", got, "none")

# Fail VISIBLE without jq: the .sh twin still asks, and says jq is missing.
shim = Path(tempfile.mkdtemp(prefix="adp-nojq-"))
for tool in ("bash", "cat", "tr", "printf"):
    src = shutil.which(tool)
    if src:
        os.symlink(src, shim / tool)
nojq = {**os.environ, "PATH": str(shim)}
assert shutil.which("jq", path=str(shim)) is None, "shim PATH still finds jq"
for name, want in [("mcp__git__git_commit", "ask"), ("mcp__github__push_files", "ask"), ("mcp__git__git_status", "none")]:
    got, reason = run("sh", payload(name), env=nojq)
    check(f"[sh, no jq] {name!r}", got, want)
    if got == "ask":
        check(f"[sh, no jq] {name!r} names jq", "jq not found" in reason, True)
        json.loads(json.dumps(reason))  # reason survived as valid JSON

# Both settings files wire the guard on the mcp__ matcher.
T = H.parent
for f, hook in (("settings.json", "mcp-git-guard.sh"), ("settings.node.json", "mcp-git-guard.mjs")):
    p = T / f
    if not p.exists():
        continue
    pre = json.loads(p.read_text()).get("hooks", {}).get("PreToolUse", [])
    wired = any(e.get("matcher") == "mcp__.*" and any(hook in h.get("command", "") for h in e.get("hooks", [])) for e in pre)
    check(f"{f} wires {hook} on mcp__.*", wired, True)

print(f"{total - fails}/{total} passed")
sys.exit(1 if fails else 0)
