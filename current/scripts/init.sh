#!/usr/bin/env bash
# init.sh — Install the Agentic Development Protocol into a target repo.
#
# Usage:
#   ./init.sh /path/to/target/repo
#   ./init.sh                          # uses current directory
#   ./init.sh --host=claude-code /path # ALSO install .claude/agents/ subagents
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
ARGS=()
for a in "$@"; do
  case "$a" in
    --host=*) HOST="${a#--host=}" ;;
    --upgrade) UPGRADE=1 ;;
    --yes|-y) ASSUME_YES=1 ;;   # non-interactive (retro #9) — also auto-on when no TTY
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
echo ""

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
if [ "$ASSUME_YES" = "1" ] || [ ! -t 0 ]; then
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
  # Subagent files are host-specific: only ship with --host=claude-code
  if [ "$HOST" != "claude-code" ]; then
    case "$rel" in .claude/agents/*) echo "  SKIP  $rel (use --host=claude-code)"; SKIPPED=$((SKIPPED+1)); continue ;; esac
  fi
  dst="$TARGET/$rel"
  if [ -e "$dst" ]; then
    if [ "$UPGRADE" = "1" ] && is_protocol_owned "$rel" && ! cmp -s "$src" "$dst"; then
      cp -p "$dst" "$dst.adp-bak"
      cp -p "$src" "$dst"
      echo "  UPGRADE $rel (old kept as $rel.adp-bak)"
      UPGRADED=$((UPGRADED+1))
    else
      echo "  SKIP  $rel (already exists)"
      SKIPPED=$((SKIPPED+1))
    fi
  else
    mkdir -p "$(dirname "$dst")"
    cp -p "$src" "$dst"
    echo "  ADD   $rel"
    echo "$rel" >> "$MANIFEST_TMP"
    ADDED=$((ADDED+1))
  fi
done < <(find . -type f -print0)

echo ""
if [ "$UPGRADE" = "1" ]; then
  echo "==> Done. Added $ADDED; upgraded $UPGRADED (with .adp-bak); left $SKIPPED untouched."
else
  echo "==> Done. Added $ADDED file(s); skipped $SKIPPED already-present file(s)."
fi

# --- settings.json: merge-or-warn (ADP install-test finding 1) -------------
# THE critical gap: the no-clobber copy SKIPS an existing .claude/settings.json,
# so the hooks land on disk but are never WIRED — enforcement looks installed
# but is inert. Detect that case and fix it (or warn loudly), never stay silent.
if [ "$HOST" = "claude-code" ]; then
  SETTINGS="$TARGET/.claude/settings.json"
  TEMPLATE_SETTINGS="$TEMPLATE_DIR/.claude/settings.json"
  if [ -f "$SETTINGS" ] && [ -f "$TEMPLATE_SETTINGS" ]; then
    echo ""
    echo "==> Wiring hooks into existing .claude/settings.json..."
    if grep -q 'git-hygiene.sh' "$SETTINGS" 2>/dev/null; then
      echo "  OK: settings.json already wires the ADP hooks — nothing to do."
    elif command -v jq >/dev/null 2>&1 && ! grep -q '"hooks"' "$SETTINGS"; then
      # Safe case: your settings.json has no "hooks" key — inject ADP's, keep all else.
      tmp="$(mktemp)"
      if jq --slurpfile adp "$TEMPLATE_SETTINGS" '. + {hooks: $adp[0].hooks}' "$SETTINGS" > "$tmp" 2>/dev/null; then
        cp -p "$SETTINGS" "$SETTINGS.adp-bak"
        mv "$tmp" "$SETTINGS"
        echo "  MERGED ADP hooks into settings.json (your other keys preserved; old kept as settings.json.adp-bak)."
        echo "merge: .claude/settings.json (hooks key added; backup .adp-bak)" >> "$MERGES_TMP"
      else
        rm -f "$tmp"
        cp -p "$TEMPLATE_SETTINGS" "$SETTINGS.adp-hooks"
        echo "  WARN: jq merge failed. Reference hooks written to settings.json.adp-hooks — merge by hand."
      fi
    else
      # Unsafe to auto-merge: no jq, OR a "hooks" key already exists.
      cp -p "$TEMPLATE_SETTINGS" "$SETTINGS.adp-hooks"
      echo "  WARN: settings.json was NOT modified (no jq, or it already has a \"hooks\" key)."
      echo "        The hooks are on disk but INERT until wired in."
      echo "        Reference block written to: .claude/settings.json.adp-hooks"
      echo "        Merge its \"hooks\" object into your settings.json, then run the"
      echo "        deliberate-violation test below to confirm enforcement fires."
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
    { echo ""; echo "# --- added by Agentic Development Protocol ---"; cat "$TMP_IGN"; } >> "$GITIGNORE"
    echo ""
    echo "==> .gitignore: appended $ADDED_IGN ADP pattern(s) you didn't already have."
    echo "merge: .gitignore (appended $ADDED_IGN pattern(s))" >> "$MERGES_TMP"
  fi
  rm -f "$TMP_IGN"
fi

# Install protocol scripts into the target so role prompts can call them.
# Scripts are protocol-owned: upgraded (with backup) in --upgrade mode.
echo ""
echo "==> Installing scripts..."
mkdir -p "$TARGET/scripts"
for s in generate_map.py wire-sync.sh adp_metrics.py; do
  [ -f "$SCRIPT_DIR/$s" ] || continue
  if [ ! -e "$TARGET/scripts/$s" ]; then
    cp -p "$SCRIPT_DIR/$s" "$TARGET/scripts/$s"
    echo "  ADD   scripts/$s"
    echo "scripts/$s" >> "$MANIFEST_TMP"
  elif [ "$UPGRADE" = "1" ] && ! cmp -s "$SCRIPT_DIR/$s" "$TARGET/scripts/$s"; then
    cp -p "$TARGET/scripts/$s" "$TARGET/scripts/$s.adp-bak"
    cp -p "$SCRIPT_DIR/$s" "$TARGET/scripts/$s"
    echo "  UPGRADE scripts/$s (old kept as scripts/$s.adp-bak)"
  fi
done

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

echo ""
echo "Next steps:"
echo "  1. Read $TARGET/.agentic-protocol/GETTING_STARTED.md"
echo "  2. Fill in <<<PLACEHOLDERS>>> in docs/prompts/*.md and docs/skills/*/SKILL.md"
echo "     grep -r '<<<' $TARGET/docs/   # to see what needs filling"
echo "  3. Generate the codebase index: python scripts/generate_map.py $TARGET"
echo "  4. Write your first plan from docs/plans/_template.md"
echo "  5. Write the first Dispatch block in docs/tasks/current.md"
echo "  6. *** REQUIRED — the install is NOT done until this passes ***"
echo "     VERIFY ENFORCEMENT (deliberate-violation test): in a Claude Code"
echo "     session, try 'git add -A' — confirm the hook BLOCKS it. If it does"
echo "     not, enforcement is not live (check jq, bash, and settings.json wiring)."
echo "  7. Start your first architect session by pasting docs/prompts/architect.md"
if [ "$HOST" = "claude-code" ]; then
  echo ""
  echo "  Claude Code native: .claude/agents/ installed. Models are PINNED in"
  echo "  frontmatter (§5.3) — review them against current model names."
fi
echo ""
echo "Whitepaper reference: ../PROTOCOL.md"
