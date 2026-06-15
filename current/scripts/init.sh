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
ARGS=()
for a in "$@"; do
  case "$a" in
    --host=*) HOST="${a#--host=}" ;;
    --upgrade) UPGRADE=1 ;;
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
read -r -p "Proceed? [y/N] " confirm
case "$confirm" in
  [yY][eE][sS]|[yY]) ;;
  *) echo "Aborted."; exit 0 ;;
esac

# Copy with -n (no clobber) so we never overwrite user files
echo ""
echo "==> Copying files (existing files are preserved)..."

# Use cp -Rn for portability (works on macOS and Linux)
# We copy with a manual loop to give a clear log of what's added vs skipped
cd "$TEMPLATE_DIR"
ADDED=0
SKIPPED=0
UPGRADED=0
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
    ADDED=$((ADDED+1))
  fi
done < <(find . -type f -print0)

echo ""
if [ "$UPGRADE" = "1" ]; then
  echo "==> Done. Added $ADDED; upgraded $UPGRADED (with .adp-bak); left $SKIPPED untouched."
else
  echo "==> Done. Added $ADDED file(s); skipped $SKIPPED already-present file(s)."
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
  elif [ "$UPGRADE" = "1" ] && ! cmp -s "$SCRIPT_DIR/$s" "$TARGET/scripts/$s"; then
    cp -p "$TARGET/scripts/$s" "$TARGET/scripts/$s.adp-bak"
    cp -p "$SCRIPT_DIR/$s" "$TARGET/scripts/$s"
    echo "  UPGRADE scripts/$s (old kept as scripts/$s.adp-bak)"
  fi
done

# Hooks must be executable or Claude Code silently skips them
chmod +x "$TARGET"/.claude/hooks/*.sh 2>/dev/null || true
chmod +x "$TARGET"/scripts/*.sh 2>/dev/null || true

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
echo "  6. VERIFY ENFORCEMENT (deliberate-violation test): in a Claude Code"
echo "     session, try 'git add -A' — confirm the hook blocks it."
echo "  7. Start your first architect session by pasting docs/prompts/architect.md"
if [ "$HOST" = "claude-code" ]; then
  echo ""
  echo "  Claude Code native: .claude/agents/ installed. Models are PINNED in"
  echo "  frontmatter (§5.3) — review them against current model names."
fi
echo ""
echo "Whitepaper reference: ../PROTOCOL.md"
