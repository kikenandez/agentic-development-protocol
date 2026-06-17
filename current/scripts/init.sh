#!/usr/bin/env bash
# init.sh — Install the Agentic Development Protocol into a target repo.
#
# Usage:
#   ./init.sh /path/to/target/repo     # prose only (no .claude enforcement infra)
#   ./init.sh                          # uses current directory
#   ./init.sh --host=claude-code /path # ALSO install .claude/ enforcement infra
#                                      #   (subagents, hooks .sh+.mjs, settings wiring)
#   ./init.sh --ci /path               # ALSO install the CI workflow (opt-in; enforces
#                                      #   conventional commits — off by default)
#   ./init.sh --yes /path              # non-interactive (also auto when no TTY)
#   ./init.sh --upgrade /path          # upgrade an existing install (PROTOCOL.md §15)
#
# What it does:
#   1. Copies template/. into the target repo (does NOT overwrite existing files)
#      - .claude/agents/ (Claude Code subagents) ships ONLY with --host=claude-code
#        (PROTOCOL.md §8.1: "Without the flag, only prose ships")
#   2. Installs scripts/{generate_map.py,wire-sync.sh,adp_metrics.py} into <target>/scripts/
#   3. Marks hook scripts executable
#   4. Prints next steps
#
# --upgrade mode (existing installs only):
#   - PROTOCOL-OWNED files (hooks, CI workflow, wire syntax key, getting-started,
#     scripts) are replaced when the template's copy differs; the old version is
#     kept beside it as <file>.adp-bak for review.
#   - USER-OWNED files (role prompts, process.md, current.md, plans, skills,
#     memory, settings.json, live wire state) are NEVER touched — your
#     customizations are the point of the protocol.
#   - New template files are added; .agentic-protocol/VERSION is updated.
#
# Idempotent: safe to re-run. Existing files are preserved (or backed up in --upgrade).

set -euo pipefail

HOST=""
UPGRADE=0
ASSUME_YES=0
WITH_CI=0
DRYRUN=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --host=*) HOST="${a#--host=}" ;;
    --upgrade) UPGRADE=1 ;;
    --yes|-y) ASSUME_YES=1 ;;   # non-interactive (retro #9) — also auto-on when no TTY
    --ci) WITH_CI=1 ;;          # opt in to the CI workflow (retro #3) — off by default
    --dry-run|--plan) DRYRUN=1 ;; # preview every add/skip/merge; write NOTHING (retro02)
    *) ARGS+=("$a") ;;
  esac
done
set -- "${ARGS[@]:-}"

# Protocol-owned paths: safe to replace on upgrade (reference implementations,
# not user content). Everything else is user-owned once installed.
is_protocol_owned() {
  case "$1" in
    .claude/hooks/*|.github/workflows/adp-checks.yml|.adp/README.wire|.agentic-protocol/GETTING_STARTED.md|.agentic-protocol/VERSION) return 0 ;;
    *) return 1 ;;
  esac
}

# Resolve script location (so the template can live next to this script)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMPLATE_DIR="${SCRIPT_DIR}/../template"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Error: template directory not found at $TEMPLATE_DIR"
  echo "Expected layout:"
  echo "  agentic-protocol/"
  echo "  ├── scripts/init.sh   (this script)"
  echo "  └── template/         (the files to install)"
  exit 1
fi

TARGET="${1:-$(pwd)}"

if [ ! -d "$TARGET" ]; then
  echo "Error: target directory does not exist: $TARGET"
  exit 1
fi

# Resolve to absolute path
TARGET="$( cd "$TARGET" && pwd )"

if [ "$UPGRADE" = "1" ] && [ ! -f "$TARGET/.agentic-protocol/VERSION" ]; then
  echo "Error: --upgrade requires an existing install ($TARGET/.agentic-protocol/VERSION not found)."
  echo "Run without --upgrade for a fresh install."
  exit 1
fi

if [ "$UPGRADE" = "1" ]; then
  echo "==> Upgrading Agentic Development Protocol"
  echo "    Installed: $(head -1 "$TARGET/.agentic-protocol/VERSION")"
  echo "    Template:  $(head -1 "$TEMPLATE_DIR/.agentic-protocol/VERSION")"
else
  echo "==> Installing Agentic Development Protocol"
  echo "    Version: $(head -1 "$TEMPLATE_DIR/.agentic-protocol/VERSION")"
fi
echo "    From: $TEMPLATE_DIR"
echo "    Into: $TARGET"
[ "$DRYRUN" = "1" ] && echo "    MODE: DRY RUN — previewing only, nothing will be written."
echo ""

# --- Clean-tree check (retro02: install onto uncommitted work entangles diffs) -
# The installer is git-neutral (writes files, never commits/branches). But if the
# target has uncommitted changes, the ~39 new files mix into your working tree and
# settings.json/.gitignore are merged on top of your pending edits. Recommend a
# clean tree / dedicated branch before mutating.
if [ "$DRYRUN" != "1" ] && command -v git >/dev/null 2>&1 \
   && git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 \
   && [ -n "$(git -C "$TARGET" status --porcelain 2>/dev/null)" ]; then
  echo "  WARN: $TARGET has uncommitted changes."
  echo "        Installing now mixes ADP's files with your pending work, and"
  echo "        settings.json/.gitignore are merged in place. Recommended:"
  echo "          git stash   (or commit)   # clean the tree"
  echo "          git checkout -b adopt-adp # install on a branch, review, then merge"
  echo "        Tip: re-run with --dry-run to preview without writing anything."
  if [ "$ASSUME_YES" != "1" ] && [ -t 0 ]; then
    read -r -p "  Proceed onto a dirty tree anyway? [y/N] " dirtyok
    case "$dirtyok" in [yY]|[yY][eE][sS]) ;; *) echo "Aborted."; exit 0 ;; esac
  fi
  echo ""
fi

# Confirm with the user
# --- Prerequisite check (ADP install-test finding 2 & 3) -------------------
# Enforcement fails SILENTLY when these are missing, so warn loudly up front.
echo "==> Checking prerequisites..."
command -v git     >/dev/null 2>&1 || echo "  WARN: git not found."
command -v python3 >/dev/null 2>&1 || echo "  WARN: python3 not found — generate_map.py / adp_metrics.py will not run."
if [ "$HOST" = "claude-code" ]; then
  command -v jq   >/dev/null 2>&1 || echo "  WARN: jq not found — the git-hygiene/dispatch hooks no-op silently without it. Install jq BEFORE relying on L3 enforcement."
  command -v bash >/dev/null 2>&1 || echo "  WARN: bash not found — .sh hooks need a bash interpreter (Windows: Git Bash) reachable by the hook runner."
fi
echo ""

# Non-interactive when --yes/-y is passed OR stdin isn't a terminal (agent/CI). (retro #9)
# Dry-run never prompts — it changes nothing.
if [ "$DRYRUN" = "1" ]; then
  :
elif [ "$ASSUME_YES" = "1" ] || [ ! -t 0 ]; then
  echo "Proceeding non-interactively (--yes or non-TTY)."
else
  read -r -p "Proceed? [y/N] " confirm
  case "$confirm" in
    [yY][eE][sS]|[yY]) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
fi

# Copy with -n (no clobber) so we never overwrite user files
echo ""
echo "==> Copying files (existing files are preserved)..."

# Use cp -Rn for portability (works on macOS and Linux)
# We copy with a manual loop to give a clear log of what's added vs skipped
cd "$TEMPLATE_DIR"
ADDED=0
SKIPPED=0
UPGRADED=0
MANIFEST_TMP="$(mktemp)"   # collect added paths for INSTALL_MANIFEST (retro #10)
MERGES_TMP="$(mktemp)"     # collect merge actions performed
while IFS= read -r -d '' src; do
  rel="${src#./}"
  # Enforcement infra is host-specific: ships ONLY with --host=claude-code, so
  # "without the flag, only prose ships" (PROTOCOL.md §8.1). This covers the
  # subagents, both hook implementations (.sh + .mjs), the hook wiring
  # (settings.json / settings.node.json), and the cross-platform note. (finding #9)
  if [ "$HOST" != "claude-code" ]; then
    case "$rel" in
      .claude/agents/*|.claude/hooks/*|.claude/settings.json|.claude/settings.node.json|.claude/HOOKS-cross-platform.md)
        echo "  SKIP  $rel (enforcement infra — use --host=claude-code)"; SKIPPED=$((SKIPPED+1)); continue ;;
    esac
  fi
  # CI workflow is opt-in: it enforces conventional commits and will fail repos
  # whose history isn't conventional. Ship only with --ci. (retro #3)
  if [ "$WITH_CI" != "1" ]; then
    case "$rel" in
      .github/workflows/adp-checks.yml)
        echo "  SKIP  $rel (CI is opt-in — use --ci to install)"; SKIPPED=$((SKIPPED+1)); continue ;;
    esac
  fi
  dst="$TARGET/$rel"
  if [ -e "$dst" ]; then
    if [ "$UPGRADE" = "1" ] && is_protocol_owned "$rel" && ! cmp -s "$src" "$dst"; then
      if [ "$DRYRUN" = "1" ]; then
        echo "  WOULD UPGRADE $rel (old kept as $rel.adp-bak)"
      else
        cp -p "$dst" "$dst.adp-bak"; cp -p "$src" "$dst"
        echo "  UPGRADE $rel (old kept as $rel.adp-bak)"
      fi
      UPGRADED=$((UPGRADED+1))
    else
      echo "  SKIP  $rel (already exists)"
      SKIPPED=$((SKIPPED+1))
    fi
  else
    if [ "$DRYRUN" = "1" ]; then
      echo "  WOULD ADD  $rel"
    else
      mkdir -p "$(dirname "$dst")"; cp -p "$src" "$dst"
      echo "  ADD   $rel"; echo "$rel" >> "$MANIFEST_TMP"
    fi
    ADDED=$((ADDED+1))
  fi
done < <(find . -type f -print0)

echo ""
if [ "$DRYRUN" = "1" ]; then
  echo "==> Plan: would add $ADDED file(s); would skip $SKIPPED already-present file(s)."
elif [ "$UPGRADE" = "1" ]; then
  echo "==> Done. Added $ADDED; upgraded $UPGRADED (with .adp-bak); left $SKIPPED untouched."
else
  echo "==> Done. Added $ADDED file(s); skipped $SKIPPED already-present file(s)."
fi

# --- settings.json: wire the hooks (finding 1 + retro04) -------------------
# The no-clobber copy SKIPs an existing settings.json, so hooks would land on disk
# but never be WIRED. We wire them, preferring the flavor that actually runs on
# THIS machine: bash hooks if jq is present, else the Node hooks if node is present
# (no jq needed — closes the Windows/jq-less gap). We never silently leave inert
# hooks; if neither tool is available, or a non-ADP "hooks" key already exists, we
# park a reference block + warn.
if [ "$HOST" = "claude-code" ]; then
  SETTINGS="$TARGET/.claude/settings.json"
  TPL_BASH="$TEMPLATE_DIR/.claude/settings.json"
  TPL_NODE="$TEMPLATE_DIR/.claude/settings.node.json"
  HAVE_JQ=0;   command -v jq   >/dev/null 2>&1 && HAVE_JQ=1
  HAVE_NODE=0; command -v node >/dev/null 2>&1 && HAVE_NODE=1

  # node-based JSON merge (no jq): set .hooks from $2 into $1, preserve other keys.
  node_merge_hooks() { # $1=settings $2=template-with-hooks  -> merged JSON on stdout
    # NOTE: with `node -e`, the first script arg is argv[1] (no script path), so skip ONE.
    node -e 'const fs=require("fs");const[,a,b]=process.argv;const c=JSON.parse(fs.readFileSync(a,"utf8"));const t=JSON.parse(fs.readFileSync(b,"utf8"));c.hooks=t.hooks;process.stdout.write(JSON.stringify(c,null,2)+"\n")' "$1" "$2"
  }

  if [ -f "$SETTINGS" ] && [ -f "$TPL_BASH" ]; then
    echo ""
    echo "==> Wiring hooks into .claude/settings.json (jq=$HAVE_JQ node=$HAVE_NODE)..."
    if grep -q 'git-hygiene.mjs' "$SETTINGS" 2>/dev/null; then
      echo "  OK: settings.json already wires the Node hooks."
    elif grep -q 'git-hygiene.sh' "$SETTINGS" 2>/dev/null; then
      # Already bash-wired (e.g. the fresh template copy). Keep it if jq is present;
      # otherwise prefer Node hooks — but only auto-swap a pristine template copy.
      if [ "$HAVE_JQ" = 1 ]; then
        echo "  OK: settings.json wires the bash hooks (jq present)."
      elif [ "$HAVE_NODE" = 1 ] && cmp -s "$SETTINGS" "$TPL_BASH"; then
        if [ "$DRYRUN" = "1" ]; then echo "  WOULD SWITCH to Node hooks (jq absent, node present)."
        else cp -p "$SETTINGS" "$SETTINGS.adp-bak"; cp -p "$TPL_NODE" "$SETTINGS"
          echo "  SWITCHED to Node hooks (jq absent, node present) — enforcement live without jq."
          echo "switch: .claude/settings.json -> Node hooks (jq absent)" >> "$MERGES_TMP"; fi
      else
        echo "  WARN: bash hooks wired but jq absent (and can't auto-switch) — INERT."
        echo "        Install jq, or: cp .claude/settings.node.json .claude/settings.json"
      fi
    elif grep -q '"hooks"' "$SETTINGS" 2>/dev/null; then
      # Non-ADP hooks key present — unsafe to auto-merge.
      if [ "$DRYRUN" = "1" ]; then echo "  WOULD WARN: settings.json has its own \"hooks\" key; would write sidecar."
      else cp -p "$TPL_BASH" "$SETTINGS.adp-hooks"
        echo "  WARN: settings.json has its own \"hooks\" key — NOT modified."
        echo "        Merge the block from .claude/settings.json.adp-hooks by hand."; fi
    elif [ "$HAVE_JQ" = 1 ]; then
      # No hooks key + jq -> merge bash hooks.
      if [ "$DRYRUN" = "1" ]; then echo "  WOULD MERGE bash hooks (jq; backup .adp-bak)."
      else tmp="$(mktemp)"
        if jq --slurpfile adp "$TPL_BASH" '. + {hooks: $adp[0].hooks}' "$SETTINGS" > "$tmp" 2>/dev/null; then
          cp -p "$SETTINGS" "$SETTINGS.adp-bak"; mv "$tmp" "$SETTINGS"
          echo "  MERGED bash hooks into settings.json (your keys preserved; old kept .adp-bak)."
          echo "merge: .claude/settings.json (bash hooks; backup .adp-bak)" >> "$MERGES_TMP"
        else rm -f "$tmp"; cp -p "$TPL_BASH" "$SETTINGS.adp-hooks"; echo "  WARN: jq merge failed — sidecar written."; fi; fi
    elif [ "$HAVE_NODE" = 1 ]; then
      # No hooks key + no jq + node -> merge Node hooks via node (no jq needed).
      if [ "$DRYRUN" = "1" ]; then echo "  WOULD MERGE Node hooks via node (jq absent; backup .adp-bak)."
      else tmp="$(mktemp)"
        if node_merge_hooks "$SETTINGS" "$TPL_NODE" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
          cp -p "$SETTINGS" "$SETTINGS.adp-bak"; mv "$tmp" "$SETTINGS"
          echo "  MERGED Node hooks into settings.json via node (your keys preserved; old kept .adp-bak)."
          echo "merge: .claude/settings.json (Node hooks via node; backup .adp-bak)" >> "$MERGES_TMP"
        else rm -f "$tmp"; cp -p "$TPL_NODE" "$SETTINGS.adp-hooks"; echo "  WARN: node merge failed — sidecar written."; fi; fi
    else
      # Neither jq nor node.
      if [ "$DRYRUN" = "1" ]; then echo "  WOULD WARN: no jq and no node — would write sidecar."
      else cp -p "$TPL_BASH" "$SETTINGS.adp-hooks"
        echo "  WARN: no jq and no node — settings.json NOT wired (hooks INERT)."
        echo "        Install jq or node, then wire from .claude/settings.json.adp-hooks."; fi
    fi
  fi
fi

# --- .gitignore: append missing lines (ADP install-test retro #1) ----------
# Like settings.json, an existing .gitignore is SKIPped by the no-clobber copy,
# so ADP's secret/cache ignores never land. Append only the lines not already
# present (never rewrite the user's file).
GITIGNORE="$TARGET/.gitignore"
TEMPLATE_GITIGNORE="$TEMPLATE_DIR/.gitignore"
if [ -f "$TEMPLATE_GITIGNORE" ] && [ -f "$GITIGNORE" ]; then
  ADDED_IGN=0
  TMP_IGN="$(mktemp)"
  while IFS= read -r line || [ -n "$line" ]; do
    # skip blanks and comments when testing membership; always keep them out of the append unless content
    case "$line" in ""|\#*) continue ;; esac
    if ! grep -qxF "$line" "$GITIGNORE"; then
      echo "$line" >> "$TMP_IGN"; ADDED_IGN=$((ADDED_IGN+1))
    fi
  done < "$TEMPLATE_GITIGNORE"
  if [ "$ADDED_IGN" -gt 0 ]; then
    if [ "$DRYRUN" = "1" ]; then
      echo ""
      echo "==> .gitignore: WOULD append $ADDED_IGN ADP pattern(s) you don't already have."
    else
      { echo ""; echo "# --- added by Agentic Development Protocol ---"; cat "$TMP_IGN"; } >> "$GITIGNORE"
      echo ""
      echo "==> .gitignore: appended $ADDED_IGN ADP pattern(s) you didn't already have."
      echo "merge: .gitignore (appended $ADDED_IGN pattern(s))" >> "$MERGES_TMP"
    fi
  fi
  rm -f "$TMP_IGN"
fi

# Install protocol scripts into the target so role prompts can call them.
# Scripts are protocol-owned: upgraded (with backup) in --upgrade mode.
echo ""
echo "==> Installing scripts..."
[ "$DRYRUN" = "1" ] || mkdir -p "$TARGET/scripts"
SCRIPTS_TO_INSTALL="generate_map.py wire-sync.sh wire-sync.mjs adp_metrics.py adp-fill.sh adp-fill.mjs"
# Hook self-tests ship only with the enforcement infra.
[ "$HOST" = "claude-code" ] && SCRIPTS_TO_INSTALL="$SCRIPTS_TO_INSTALL verify-hooks.sh verify-hooks.mjs"
for s in $SCRIPTS_TO_INSTALL; do
  [ -f "$SCRIPT_DIR/$s" ] || continue
  if [ ! -e "$TARGET/scripts/$s" ]; then
    if [ "$DRYRUN" = "1" ]; then
      echo "  WOULD ADD  scripts/$s"
    else
      cp -p "$SCRIPT_DIR/$s" "$TARGET/scripts/$s"
      echo "  ADD   scripts/$s"
      echo "scripts/$s" >> "$MANIFEST_TMP"
    fi
  elif [ "$UPGRADE" = "1" ] && ! cmp -s "$SCRIPT_DIR/$s" "$TARGET/scripts/$s"; then
    if [ "$DRYRUN" = "1" ]; then
      echo "  WOULD UPGRADE scripts/$s (old kept as scripts/$s.adp-bak)"
    else
      cp -p "$TARGET/scripts/$s" "$TARGET/scripts/$s.adp-bak"
      cp -p "$SCRIPT_DIR/$s" "$TARGET/scripts/$s"
      echo "  UPGRADE scripts/$s (old kept as scripts/$s.adp-bak)"
    fi
  fi
done

if [ "$DRYRUN" = "1" ]; then
  echo ""
  echo "==> DRY RUN complete — nothing was written. Re-run without --dry-run to install."
  rm -f "$MANIFEST_TMP" "$MERGES_TMP"
  exit 0
fi

# Hooks must be executable or Claude Code silently skips them
chmod +x "$TARGET"/.claude/hooks/*.sh 2>/dev/null || true
chmod +x "$TARGET"/scripts/*.sh 2>/dev/null || true

# --- Write INSTALL_MANIFEST (retro #10) ------------------------------------
# Records exactly what this install added and merged, so uninstall.sh can
# reverse precisely what was done rather than guessing from a hardcoded list.
MANIFEST="$TARGET/.agentic-protocol/INSTALL_MANIFEST"
mkdir -p "$TARGET/.agentic-protocol"
{
  echo "# ADP INSTALL_MANIFEST — generated by init.sh; do not edit by hand."
  echo "# Version: $(head -1 "$TEMPLATE_DIR/.agentic-protocol/VERSION" 2>/dev/null)"
  echo "# Installed: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# Host: ${HOST:-generic}"
  echo "# Reverse with: uninstall.sh (safe mode keeps your authored content)."
  echo ""
  echo "[files-added]"
  sort -u "$MANIFEST_TMP" 2>/dev/null
  echo ""
  echo "[merges-performed]"
  cat "$MERGES_TMP" 2>/dev/null
} > "$MANIFEST"
echo ""
echo "==> Wrote install manifest: .agentic-protocol/INSTALL_MANIFEST"
rm -f "$MANIFEST_TMP" "$MERGES_TMP"

if [ "$UPGRADE" = "1" ]; then
  echo ""
  echo "Upgrade complete. Review what changed:"
  echo "  diff <(cat FILE.adp-bak) FILE   # for each UPGRADE line above"
  echo "  rm \$(find $TARGET -name '*.adp-bak')   # when satisfied"
  echo "  Re-run the deliberate-violation test (PROTOCOL.md §11.1 step 6) —"
  echo "  upgraded enforcement you haven't watched fire is enforcement you don't have."
  echo ""
  echo "Whitepaper reference: ../PROTOCOL.md §15 (migration)"
  exit 0
fi

# --- Enforcement status (retro02 #1): state what is ACTUALLY true, not a -------
# generic checklist. The installer knows the mode, whether hooks are wired, and
# whether jq is present — so it says so plainly instead of implying enforcement.
ENF="none"
if [ "$HOST" = "claude-code" ]; then
  SET="$TARGET/.claude/settings.json"
  if grep -q 'git-hygiene.mjs' "$SET" 2>/dev/null; then
    command -v node >/dev/null 2>&1 && ENF="active_node" || ENF="inert_nonode"
  elif grep -q 'git-hygiene.sh' "$SET" 2>/dev/null; then
    command -v jq >/dev/null 2>&1 && ENF="active_bash" || ENF="inert_nojq"
  else
    ENF="notwired"
  fi
fi

echo ""
echo "==> ENFORCEMENT STATUS:"
case "$ENF" in
  none)
    echo "  L3 enforcement NOT installed — this is a prose-only install."
    echo "  The git-hygiene / freshness hooks were not added. To enable enforcement"
    echo "  later, re-run with --host=claude-code." ;;
  active_bash)
    echo "  Hooks WIRED (bash) and jq present — looks ready."
    echo "  If you merged hooks into a live session, reload/restart it to ARM them."
    echo "  *** REQUIRED final check *** in a Claude Code session try 'git add -A'"
    echo "  and confirm it is BLOCKED. Config can be right yet the host not fire it." ;;
  active_node)
    echo "  Hooks WIRED (Node) and node present — looks ready, no jq needed."
    echo "  If you merged hooks into a live session, reload/restart it to ARM them."
    echo "  *** REQUIRED final check *** in a Claude Code session try 'git add -A'"
    echo "  and confirm it is BLOCKED. Config can be right yet the host not fire it." ;;
  inert_nojq)
    echo "  Hooks wired (bash) but INERT — jq is NOT installed, so they no-op."
    echo "  Fix it, then live-test 'git add -A': install jq, OR switch to Node hooks:"
    echo "        cp .claude/settings.node.json .claude/settings.json" ;;
  inert_nonode)
    echo "  Hooks wired (Node) but INERT — node is NOT on PATH. Install Node.js,"
    echo "  then live-test 'git add -A'." ;;
  notwired)
    echo "  Hooks NOT wired — your existing settings.json was preserved and the"
    echo "  hooks block was not merged (see .claude/settings.json.adp-hooks)."
    echo "  Merge it, or use the Node hooks (cp .claude/settings.node.json"
    echo "  .claude/settings.json), then live-test 'git add -A'." ;;
esac

echo ""
echo "Next steps:"
echo "  1. Read $TARGET/.agentic-protocol/GETTING_STARTED.md"
echo "  2. Fill in <<<PLACEHOLDERS>>> in docs/prompts/*.md and docs/skills/*/SKILL.md"
echo "     grep -r '<<<' $TARGET/docs/ $TARGET/memory/CLAUDE.md   # what needs filling"
echo "  3. Generate the codebase index: python scripts/generate_map.py $TARGET"
echo "  4. Start an architect session: paste docs/prompts/architect.md, then hand it"
echo "     docs/prompts/initialize.md (one-time) to write the first plan + Dispatch."
if [ "$HOST" = "claude-code" ]; then
  echo ""
  echo "  Claude Code native: .claude/agents/ installed. Models are PINNED in"
  echo "  frontmatter (§5.3) — review them against current model names."
  echo "  Self-test the hooks offline: scripts/verify-hooks.sh $TARGET   (bash+jq)"
  echo "                         or:  node scripts/verify-hooks.mjs $TARGET (no jq)"
fi
echo ""
echo "Whitepaper reference: ../PROTOCOL.md"
