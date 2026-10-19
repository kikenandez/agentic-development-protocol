#!/bin/bash
# mcp-git-guard.sh — PreToolUse(mcp__.*) hook: make the MCP route around the
# git-hygiene hooks visible (ADP §6.4, §8.3; tooling 1.1.9).
#
# git-hygiene and post-commit-orphan-check match the Bash tool only. A git write
# made through an MCP tool (the reference git server's git_add / git_commit, a
# GitHub server's push_files, ...) never reaches them: the five §6.4 rules and the
# orphan check do not run, and nothing says so. This hook cannot parse what an
# MCP tool will do, so it does not try to enforce the rules. It names the gap:
#   - tool name has a `commit` word                               -> ASK
#   - tool name contains `git` and an add/reset/checkout/push word -> ASK
#   - everything else (git_status, git_diff, git_log, git_show,
#     non-git MCP tools)                                          -> no-op
# It never denies: the decision stays with the human, with the reason in view.
#
# Requires: jq to parse the payload. Without jq it falls back to a plain bash
# match on "tool_name" and says it did (fail visible, as the 1.1.7 hooks do).
# Kill switch: export ADP_GIT_HOOK_DISABLE=1 (shared with git-hygiene).

set -uo pipefail

[ "${ADP_GIT_HOOK_DISABLE:-0}" = "1" ] && exit 0

INPUT="$(cat)"
HAVE_JQ=0; command -v jq >/dev/null 2>&1 && HAVE_JQ=1

ask() { # $1 = reason (no double quotes or backslashes: the no-jq path prints it raw)
  if [ "$HAVE_JQ" = 1 ]; then
    jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
  else
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}' "$1"
  fi
  exit 0
}

NAME=""
if [ "$HAVE_JQ" = 1 ]; then
  NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")"
else
  re='"tool_name"[[:space:]]*:[[:space:]]*"([^"]*)"'
  [[ "$INPUT" =~ $re ]] && NAME="${BASH_REMATCH[1]}"
fi
# MCP tool names are [A-Za-z0-9_-]; drop anything else so the name is safe to echo.
NAME="$(printf '%s' "$NAME" | tr -cd 'A-Za-z0-9_.-')"

NOJQ_NOTE=""
[ "$HAVE_JQ" = 1 ] || NOJQ_NOTE=" (jq not found: tool name read by a plain bash match. Install jq or switch to the Node hooks, .claude/HOOKS-cross-platform.md.)"

if [ -z "$NAME" ]; then
  # Payload we cannot read. Stay quiet unless it smells of git, then say so.
  case "$INPUT" in
    *git*) ask "ADP mcp-git-guard cannot read the tool name of this MCP call, so it cannot tell whether it writes to git. The git-hygiene hooks do not run on MCP tools. Proceed only if this call does not stage, commit, reset, checkout or push.${NOJQ_NOTE}" ;;
  esac
  exit 0
fi

LOWER="$(printf '%s' "$NAME" | tr 'A-Z' 'a-z')"
WORDS=" $(printf '%s' "$LOWER" | tr '_.-' '   ') "

is_write=0
case "$WORDS" in *" commit "*) is_write=1 ;; esac
if [ "$is_write" = 0 ]; then
  case "$LOWER" in
    *git*)
      case "$WORDS" in *" add "*|*" reset "*|*" checkout "*|*" push "*) is_write=1 ;; esac ;;
  esac
fi
[ "$is_write" = 1 ] || exit 0

ask "CONFIRM (ADP §6.4): ${NAME} looks like a git write through an MCP tool. The git-hygiene and orphan-check hooks match the Bash tool only, so the five §6.4 rules do NOT run on this call, and an MCP commit usually takes the whole index with no pathspec form. Prefer Bash: git status --short; git add <paths>; git commit -m '...' -- <paths>. Authorize this instance only if you have checked the staged set yourself.${NOJQ_NOTE}"
