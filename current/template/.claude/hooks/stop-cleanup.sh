#!/bin/bash
# stop-cleanup.sh — Stop hook, ADP §8.2.
#
# Session-end housekeeping (never blocks the stop):
#   1. Prune orphan git worktrees (left by competition mode §16.3 or
#      baseline-per-session checks §6.1 that didn't clean up).
#   2. If scripts/wire-sync.sh exists, regenerate .adp/ wire files from
#      docs/tasks/current.md (L4 adoption — §9.4).
#
# The dispatch-freshness latch is released by session-end-latch.sh (SessionEnd),
# NOT here: Claude Code fires Stop at the end of EVERY turn, so releasing the
# latch on Stop re-armed the once-per-session gate on every prompt (2026-10-12).
#
# Kill switch: ADP_STOP_HOOK_DISABLE=1.

set -uo pipefail   # deliberately NOT -e: cleanup must never fail the stop

[ "${ADP_STOP_HOOK_DISABLE:-0}" = "1" ] && exit 0

ROOT="${CLAUDE_PROJECT_DIR:-.}"

# 1. Prune worktree bookkeeping for deleted dirs, then remove ADP-tagged
#    throwaway worktrees (created as <repo>-adp-* by convention).
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$ROOT" worktree prune 2>/dev/null
  git -C "$ROOT" worktree list --porcelain 2>/dev/null \
    | awk '/^worktree /{print $2}' \
    | grep -E -- '-adp-(competition|baseline|tmp)-' \
    | while read -r wt; do
        git -C "$ROOT" worktree remove --force "$wt" 2>/dev/null
      done
fi

# 2. Wire sync (no-op unless the repo adopted L2/L4)
if [ -x "$ROOT/scripts/wire-sync.sh" ] && [ -d "$ROOT/.adp" ]; then
  "$ROOT/scripts/wire-sync.sh" >/dev/null 2>&1
fi

exit 0
