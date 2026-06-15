#!/bin/bash
# git-hygiene.sh — PreToolUse(Bash) hook enforcing ADP §6.4 commit-hygiene rules
# at the tool-call boundary (process discipline, not algorithmic constraint — see
# the §6.4 "Critical limitation" note).
#
# Battle-tested reference implementation (source production, 2026-06; verified
# firing live the session it was installed). Behavior:
#   - BULK STAGING  (git add -A | . | --all ; git commit -a/--all) -> DENY
#       §6.4 rule 1: stage by exact path; never sweep the working tree.
#   - DESTRUCTIVE   (git reset --hard ; push --force/-f ; branch -D) -> ASK
#       §6.4 rule 4 + destructive-op authorization: confirm per instance.
#   - git commit    (plain)                                          -> ALLOW
#       + inject `git status --short` as additionalContext so the staged set is
#       visible at every commit (§6.4 rule 2 — closes the shared-index sweep that
#       exact-path staging alone can't, since `.git/index` is process-shared).
#   - everything else                                                -> no-op
#
# Robustness: quoted substrings are stripped BEFORE matching, so a commit MESSAGE
# that mentions "git add -A" is never falsely denied. A token-proxy prefix
# (e.g. `rtk `) is tolerated because we match the `git <subcmd>` token.
#
# Requires: jq. Kill switch: export ADP_GIT_HOOK_DISABLE=1.
# Scope: place in .claude/settings.json PreToolUse(Bash). Protects all sessions
# sharing this working tree. (Subagents need it declared in their own scope —
# see §6.4 "Sub-finding for parallel work".)

set -euo pipefail

[ "${ADP_GIT_HOOK_DISABLE:-0}" = "1" ] && exit 0

INPUT="$(cat)"
CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")"
case "$CMD" in *git*) : ;; *) exit 0 ;; esac

emit() { # $1=decision $2=reason [$3=additionalContext]
  jq -n --arg d "$1" --arg r "$2" --arg c "${3:-}" '
    {hookSpecificOutput: ({
       hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r
     } + (if $c == "" then {} else {additionalContext: $c} end))}'
  exit 0
}

# Strip quoted substrings so commit messages can't trip the structural patterns.
STRIPPED="$(printf '%s' "$CMD" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g")"

# §6.4 rule 1 — bulk staging -> DENY
if printf '%s' "$STRIPPED" | grep -Eq 'git[[:space:]]+add[[:space:]]+(-A([[:space:]]|$)|--all([[:space:]]|$)|\.([[:space:]]|$))'; then
  emit deny "BLOCKED (ADP §6.4 rule 1): 'git add -A/./--all' bulk-stages the shared working tree and sweeps other sessions' files. Stage by exact path: git add <path1> <path2>. Need a file outside your lane? Write a handoff task."
fi
if printf '%s' "$STRIPPED" | grep -Eq 'git[[:space:]]+commit[[:space:]]+(-a([[:space:]]|$)|-[a-zA-Z]*a[a-zA-Z]*[[:space:]]|--all([[:space:]]|$))'; then
  emit deny "BLOCKED (ADP §6.4 rule 1): 'git commit -a/--all' stages every tracked change. Stage by exact path first, then 'git commit -m'."
fi

# §6.4 rule 4 + destructive-op -> ASK
if printf '%s' "$STRIPPED" | grep -Eq 'git[[:space:]]+reset[[:space:]].*--hard'; then
  emit ask "CONFIRM (ADP §6.4 rule 4): 'git reset --hard' discards work irreversibly. Prefer --soft/--mixed; 'git stash' first if you must. Authorize this instance?"
fi
if printf '%s' "$STRIPPED" | grep -Eq 'git[[:space:]]+push[[:space:]].*(--force([^-]|$)|--force-with-lease|-f([[:space:]]|$))'; then
  emit ask "CONFIRM: force-push rewrites remote history. Authorize this instance?"
fi
if printf '%s' "$STRIPPED" | grep -Eq 'git[[:space:]]+branch[[:space:]].*-D([[:space:]]|$)'; then
  emit ask "CONFIRM: 'git branch -D' force-deletes a branch (may drop unmerged work). Authorize this instance?"
fi

# §6.4 rule 2 — surface the staged set at every commit -> ALLOW + context
if printf '%s' "$STRIPPED" | grep -Eq 'git[[:space:]]+commit([[:space:]]|$)'; then
  STATUS="$(git status --short 2>/dev/null || echo '(git status unavailable)')"
  [ -z "$STATUS" ] && STATUS="(working tree clean — nothing staged?)"
  emit allow "git commit allowed; staged set surfaced for §6.4 rule 2 review." \
    "$(printf 'ADP §6.4 rule 2 — review the staged set BEFORE this commit lands.\n`git status --short`:\n%s\n\nStaged entries (M/A/D left column) MUST be only files you own. Un-stage strays: git reset HEAD <path>. If a stray already committed, fix forward with a new commit (rule 5), never --amend.' "$STATUS")"
fi

exit 0
