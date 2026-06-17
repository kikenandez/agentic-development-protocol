# Getting Started — Agentic Development Protocol (ADP) 1.1 (tooling 1.1.1)

You've installed the protocol. This walkthrough gets you from "files on disk" to "first parallel multi-agent session" in about 15 minutes.

If you haven't read `PROTOCOL.md` yet, do that first — this file assumes you understand the five core patterns (stable prompts, Dispatch block, file ownership, commit hygiene, session lifecycle).

---

## Step 0 — How to install cleanly (before you run init.sh)

The installer writes files but **never touches git** — it won't commit or branch
for you. So install onto a clean tree, ideally a dedicated branch, then review and
merge:

```bash
cd /path/to/your/repo
git checkout -b adopt-adp                 # install on a branch
/path/to/adp/current/scripts/init.sh --dry-run .   # preview — writes nothing
/path/to/adp/current/scripts/init.sh --host=claude-code .   # then install for real
git status && git diff --stat             # review, then commit + merge
```

`--dry-run` shows exactly what would be added/skipped/merged. If you install onto a
repo with uncommitted changes, init.sh warns first — heed it, or your work and
ADP's files end up entangled in the same diff.

---

## Step 1 — Confirm the install (30 seconds)

```bash
ls -la docs/prompts/
# Expect: architect.md, developer.md, designer.md, reviewer.md, analyst.md, process.md

ls -la docs/tasks/
# Expect: current.md, archive/

ls -la docs/plans/
# Expect: _template.md, archive/

cat .agentic-protocol/VERSION
# Expect: ADP 1.1.1
```

If anything's missing, re-run the init script or `cp -r template/. .` from the protocol repo.

---

## Step 2 — Fill in your stack (5 minutes)

Each role prompt has `<<<PLACEHOLDER>>>` blocks. Replace them. Do it once; they don't change after.

**First, set the project name once** in `memory/CLAUDE.md`: replace `<<<PROJECT_NAME>>>` with your project name and a one-line description. This is the single place the name lives — every role session reads it on startup, so the role prompts stay generic ("for this repository").

**Then open and edit the role prompts:**

1. `docs/prompts/architect.md`:
   - `<<<STACK>>>` → e.g. "Python 3.12 + FastAPI + Postgres + React/Vite"
   - `<<<LOCAL_RUN>>>` → e.g. "`docker compose up`" or "`./run_local.sh`"
   - `<<<DEPLOY>>>` → e.g. "`./scripts/deploy.sh`" or "GitHub Actions on push to main"
   - `<<<GLOSSARY>>>` → internal acronyms / project codenames a fresh session should know

2. `docs/prompts/developer.md`:
   - Same `<<<STACK>>>` / `<<<LOCAL_RUN>>>` / `<<<DEPLOY>>>`
   - `<<<TEST_CMD>>>` → e.g. "`pytest tests/ -q`"
   - `<<<OWNED_PATHS>>>` → e.g. "`api/`, `db/`, `tests/`, `scripts/`"
   - `<<<DO_NOT_TOUCH>>>` → e.g. "`web/`, `docs/`"
   - `<<<ARCH_RULES>>>` → 3-7 timeless rules specific to your codebase (database access pattern, auth pattern, secrets handling)

3. `docs/prompts/designer.md` (or delete if no UI):
   - `<<<UI_STACK>>>` → e.g. "React + TypeScript + Tailwind, Vite"
   - `<<<DESIGN_TOKENS>>>` → font + color + spacing tokens
   - `<<<I18N_LOCALES>>>` → e.g. "en, fr, es" or "en only — no i18n yet"
   - `<<<BUILD_CMD>>>` → e.g. "`npm run build`"
   - `<<<E2E_CMD>>>` → e.g. "`npm run test:e2e`"
   - `<<<OWNED_PATHS>>>` → e.g. "`web/src/`, `web/public/locales/`, `web/tests/e2e/`"
   - `<<<DO_NOT_TOUCH>>>` → e.g. "`api/`, `db/`, `scripts/`"

4. `docs/prompts/reviewer.md` (optional):
   - `<<<TEST_CMD>>>`, `<<<BUILD_CMD>>>`

5. `docs/prompts/process.md`:
   - Fill in the File Ownership table (§4) with the same `<<<OWNED_PATHS>>>` values you used in role prompts. Three sources should agree: role prompt, process.md §4, and your team's mental model.

**Sanity check:** search the prompts for any remaining `<<<...>>>` placeholders and replace them:

```bash
grep -r "<<<" docs/prompts/ memory/CLAUDE.md
# Expect: empty (or only matches in commented examples)
```

---

## Step 3 — Write your first plan (3 minutes)

Copy the plan template and fill it in:

```bash
cp docs/plans/_template.md docs/plans/$(date +%Y-%m-%d)-bootstrap.md
```

Edit the new file. For a greenfield project: list the 3-5 highest-leverage things to build in the first week. For an existing project: pick one workstream you're about to start.

Don't over-plan. The architect session will refine this. You want ~10 minutes of writing, not 2 hours.

---

## Step 4 — Write your first Dispatch (2 minutes)

Open `docs/tasks/current.md`. The Dispatch block at the top has placeholders — replace them with:

- A status snapshot (1-3 lines): "Just installed ADP. Bootstrap plan in `docs/plans/2026-06-01-bootstrap.md`. No tasks dispatched yet."
- Developer session pickup: name 1-2 tasks. If the project is greenfield, those tasks might be "T1: scaffold project structure per bootstrap plan §3".
- Designer session pickup (if applicable): same.
- User actions pending: anything only the human can do right now.

Then write your first task block (T1) below the Dispatch using the template already in the file. Be concrete — files to create, acceptance criteria.

---

## Step 5 — Initialize git tracking (1 minute)

```bash
git add docs/prompts/ docs/tasks/ docs/plans/ .agentic-protocol/
git status --short    # confirm only ADP files staged
git commit -m "chore: install Agentic Development Protocol 1.1

Adds role prompts, process.md, dispatch-block skeleton, and plan
template. See .agentic-protocol/VERSION."
```

Note the `git status --short` step. That's the habit you want from day 1.

---

## Step 6 — Start your first architect session (now)

Open your AI coding host (Claude Code, Cursor, etc.). Start a new session.

**First message to paste** (literally — copy from the file):

```
[Paste the body of docs/prompts/architect.md here — everything inside the triple-backtick block]
```

The session will boot, read `process.md`, read `current.md` Dispatch, and stand by.

Your first conversation with it: "Read the bootstrap plan. Verify it's coherent. Refine the T1 task spec if needed. Then I'll start a developer session."

---

## Step 7 — Start a parallel developer session (when ready)

Same AI host, second session (or second terminal). Paste `docs/prompts/developer.md`.

The session will read Dispatch, find T1, set Status: IN_PROGRESS, and start working.

Now you have two sessions running. Watch them for the first task — confirm they don't step on each other's files. The exact-path staging rule and `git status --short` habit should make this a non-event.

---

## What success looks like at week 1

- `docs/tasks/current.md` Dispatch block has been rewritten 5+ times
- `docs/tasks/archive/` has 3-7 archive files (closed tasks)
- `docs/plans/` has 2-4 active plans
- You (the human) appear in chat to (a) accept proposals, (b) deploy, (c) clarify spec ambiguity — not to relay information between sessions
- `git log --oneline` shows commits with clean conventional-commits prefixes and task IDs

---

## Troubleshooting

**"Two sessions tried to commit the same file."**
→ One of them skipped `git status --short` before commit. Read process.md §4a Hard Rule #5. The recovery: `git reset HEAD <unintended-file>`, re-commit the intended subset, write a handoff task for the file that needed cross-lane work.

**"Architect keeps trying to write code."**
→ Re-paste the architect prompt. The "Never implement code directly" rule is in the HARD rules block; if the session drifted, a re-paste with explicit reminder fixes it. If it keeps drifting, your architect session is too small a model — bump it to Opus or Sonnet.

**"`current.md` grew to 1500 lines and sessions are slow to boot."**
→ Run an architect cleanup pass. Archive stubs that are >1 round old. Move family-bundle insights to the archive-index section. See process.md §10.

**"A bug investigation ate the whole day and turned out to be local-stack staleness."**
→ Gate 0 was skipped. The pattern is the cost; the rule fires next time. Log the miss in `current.md` § "Process misses log".

**"I'm running ADP solo with one session."**
→ Fine. You'll skip the parallel-session commit hygiene rules (they're free anyway — exact-path staging is good habit) and you may collapse architect + developer into one role. The Dispatch block still helps you remember what you were doing across sessions.

---

## Next steps

- Read `PROTOCOL.md` §6-§9 to internalize the process / lifecycle.
- Once you've shipped your first 5 tasks, do an architect retrospective: open the archive files, look for patterns that should become "Architecture rules ratified" in `current.md`.
- Star the ADP repo, file issues for anything that didn't work in your context.

Welcome to multi-agent development. Build something good.
