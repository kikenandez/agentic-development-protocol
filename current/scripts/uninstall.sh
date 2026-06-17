#!/usr/bin/env bash
# uninstall.sh — Remove the Agentic Development Protocol from a repo, safely.
#
# Usage:
#   ./uninstall.sh /path/to/your/repo            # safe: remove scaffolding, KEEP your work
#   ./uninstall.sh --dry-run /path/to/your/repo  # show what would happen, change nothing
#   ./uninstall.sh --purge /path/to/your/repo    # ALSO remove your plans/tasks/memory (asks twice)
#   ./uninstall.sh                               # uses current directory
#
# Design principle (mirrors init.sh): ADP folders end up holding YOUR work, not
# just scaffolding. Default mode removes only protocol scaffolding and PRESERVES
# anything you authored (plans, dispatch/tasks, archive, memory facts), printing
# what it kept. --purge removes those too, with confirmation.
#
# settings.json is never deleted — only the ADP "hooks" block is un-wired
# (a timestamped backup is written first). Everything is git-tracked, so the
# real safety net is `git restore` / `git revert`.

set -euo pipefail

DRYRUN=0
PURGE=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --dry-run) DRYRUN=1 ;;
    --purge)   PURGE=1 ;;
    *) ARGS+=("$a") ;;
  esac
done
set -- "${ARGS[@]:-}"

TARGET="${1:-$(pwd)}"
[ -d "$TARGET" ] || { echo "Error: target directory does not exist: $TARGET"; exit 1; }
TARGET="$( cd "$TARGET" && pwd )"

if [ ! -f "$TARGET/.agentic-protocol/VERSION" ]; then
  echo "Error: no ADP install found at $TARGET (.agentic-protocol/VERSION missing)."
  echo "Nothing to uninstall."
  exit 1
fi

say() { echo "$1"; }
do_rm() { # $1 = path (file or dir)
  local p="$TARGET/$1"
  [ -e "$p" ] || return 0
  if [ "$DRYRUN" = "1" ]; then echo "  WOULD REMOVE  $1"; else rm -rf "$p"; echo "  REMOVED  $1"; fi
}
rmdir_if_empty() { # $1 = dir; remove only if empty (preserves user files inside)
  local p="$TARGET/$1"
  [ -d "$p" ] || return 0
  if [ "$DRYRUN" = "1" ]; then
    [ -z "$(ls -A "$p" 2>/dev/null)" ] && echo "  WOULD REMOVE  $1/ (empty)"
  else
    rmdir "$p" 2>/dev/null && echo "  REMOVED  $1/ (was empty)" || true
  fi
}

echo "==> Uninstalling Agentic Development Protocol"
echo "    Installed: $(head -1 "$TARGET/.agentic-protocol/VERSION")"
echo "    From: $TARGET"
[ "$DRYRUN" = "1" ] && echo "    MODE: dry-run (no changes will be made)"
[ "$PURGE" = "1" ]  && echo "    MODE: PURGE (your plans/tasks/memory will ALSO be removed)"
echo ""

if [ "$DRYRUN" != "1" ]; then
  read -r -p "Proceed? [y/N] " c; case "$c" in [yY]|[yY][eE][sS]) ;; *) echo "Aborted."; exit 0 ;; esac
  if [ "$PURGE" = "1" ]; then
    read -r -p "PURGE also deletes your dispatch, plans, retros, and memory facts. Type 'purge' to confirm: " c2
    [ "$c2" = "purge" ] || { echo "Aborted."; exit 0; }
  fi
  echo ""
fi

# --- 1) Scaffolding: always removed (protocol files, no user content) ---------
echo "==> Removing protocol scaffolding..."
# config / state
do_rm ".adp"
do_rm ".agentic-protocol"
do_rm ".github/workflows/adp-checks.yml"
# hooks (bash + optional Node port) + native agents
for h in git-hygiene dispatch-freshness post-commit-orphan-check stop-cleanup; do
  do_rm ".claude/hooks/$h.sh"; do_rm ".claude/hooks/$h.mjs"
done
do_rm ".claude/settings.node.json"
do_rm ".claude/HOOKS-cross-platform.md"
for a in architect developer designer reviewer; do do_rm ".claude/agents/$a.md"; done
# role prompts (ADP structure — useless without the protocol)
for p in architect developer designer reviewer analyst business comms process; do do_rm "docs/prompts/$p.md"; done
# skills
for s in codebase-index contract-enforcement design-principles operational-quick-ref; do do_rm "docs/skills/$s"; done
do_rm "docs/skills/_README.md"
# templates + scaffolding readmes
do_rm "docs/plans/_template.md"
do_rm "docs/retros/_template.md"
do_rm "docs/tasks/archive/_README.md"
do_rm "memory/_README.md"
# protocol scripts + generated indexes (leave uninstall.sh so it can finish)
for f in generate_map.py wire-sync.sh adp_metrics.py verify-hooks.sh; do do_rm "scripts/$f"; done
do_rm "codebase_index.txt"
do_rm "codebase_tests_index.txt"

# --- 2) User work: removed ONLY in --purge mode -------------------------------
if [ "$PURGE" = "1" ]; then
  echo ""
  echo "==> PURGE: removing authored ADP content..."
  do_rm "docs/tasks/current.md"
  do_rm "docs/tasks/archive"
  do_rm "docs/plans"
  do_rm "docs/retros"
  do_rm "memory/CLAUDE.md"
  # remove remaining memory write-layer files (*.md) but leave the dir if user had non-ADP files
  if [ -d "$TARGET/memory" ]; then
    for f in "$TARGET"/memory/*.md; do [ -e "$f" ] || continue; do_rm "memory/$(basename "$f")"; done
  fi
fi

# --- 3) Un-wire settings.json (never delete it) -------------------------------
echo ""
echo "==> Un-wiring hooks from .claude/settings.json..."
SETTINGS="$TARGET/.claude/settings.json"
if [ -f "$SETTINGS" ] && grep -q 'git-hygiene.sh' "$SETTINGS"; then
  if [ "$DRYRUN" = "1" ]; then
    echo "  WOULD remove the ADP \"hooks\" block (your other settings preserved)."
  elif command -v jq >/dev/null 2>&1; then
    cp -p "$SETTINGS" "$SETTINGS.pre-uninstall-$(date +%Y%m%d%H%M%S)"
    tmp="$(mktemp)"
    if jq 'del(.hooks)' "$SETTINGS" > "$tmp" 2>/dev/null; then
      mv "$tmp" "$SETTINGS"
      echo "  UN-WIRED hooks (backup written as settings.json.pre-uninstall-*)."
    else
      rm -f "$tmp"; echo "  WARN: jq failed — remove the \"hooks\" block from settings.json by hand."
    fi
  else
    echo "  WARN: jq not found — remove the ADP \"hooks\" block from settings.json by hand"
    echo "        (look for the four .claude/hooks/*.sh entries)."
  fi
else
  echo "  No ADP hooks wired in settings.json — nothing to un-wire."
fi

# --- 4) Tidy now-empty ADP dirs (never force-removes dirs with your files) -----
echo ""
echo "==> Tidying empty directories..."
for d in .claude/hooks .claude/agents docs/prompts docs/skills docs/tasks/archive docs/tasks docs/plans docs/retros; do
  rmdir_if_empty "$d"
done

# --- 5) Report ----------------------------------------------------------------
echo ""
if [ "$PURGE" != "1" ]; then
  echo "==> Done (safe mode). Anything still under docs/ or memory/ is YOUR work, kept on purpose:"
  for d in docs/plans docs/retros docs/tasks memory; do
    if [ -d "$TARGET/$d" ] && [ -n "$(ls -A "$TARGET/$d" 2>/dev/null)" ]; then
      echo "  KEPT  $d/  ->  $(ls -A "$TARGET/$d" 2>/dev/null | tr '\n' ' ')"
    fi
  done
  echo "  (Re-run with --purge to remove these too.)"
else
  echo "==> Done (purge). All ADP files removed."
fi
echo ""
echo "Notes:"
echo "  - .gitignore was left as-is (ADP's secret/cache patterns are harmless; trim by hand if you want)."
echo "  - Everything was tracked in git: review with 'git status', then commit the removal —"
echo "    or undo the whole thing with 'git restore .' / 'git checkout -- .'."
[ "$DRYRUN" = "1" ] && echo "  - DRY RUN: nothing was actually changed."
