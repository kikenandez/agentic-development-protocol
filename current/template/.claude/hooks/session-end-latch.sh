#!/bin/bash
# session-end-latch.sh — SessionEnd hook, ADP §6.2.
#
# Releases this session's dispatch-freshness latch, so the next session faces
# the freshness gate again. Runs on SessionEnd, not Stop: Stop fires at the end
# of every turn, which re-armed the once-per-session gate on every prompt.
#
# Requires: jq (optional). Never fails.
set -uo pipefail
INPUT="$(cat 2>/dev/null || echo '{}')"
SESSION="$(printf '%s' "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || echo "")"
case "$SESSION" in (""|*[!A-Za-z0-9_-]*) SESSION="" ;; esac  # never a path fragment
[ -n "$SESSION" ] && rm -f "/tmp/.adp-dispatch-ok-${SESSION}" 2>/dev/null
exit 0
