# Active Tasks

**All sessions read this file on startup.** The Dispatch block below tells each session what to pick up next. See `docs/prompts/process.md` for the full protocol (§3 task dispatch, §3a Dispatch block, §4a commit hygiene, §5a Gate 0, §9 session lifecycle, §10 archive convention).

---

## Dispatch — architect-maintained (updated YYYY-MM-DD)

### Status snapshot
- (Architect: replace this with a 3-5 line snapshot of where the project stands today. Example: "T1 scaffold landed in `abc1234`; T2 first feature dispatched to dev; T3 design-system tokens in REVIEW. No P0 blockers. Architect inbox: empty.")

### Developer session (next)
- **Pick up:** T1 — (replace with your first task)
- **After T1:** T2 → T3
- **Do not start:** (list anything blocked, with reason)
- **Context budget:** end session at ≤30% remaining
- **Standing reminders:** Gate 0 on every bug. Stage by exact path; `git status --short` before every commit.

### Designer session (next)
- **Pick up:** (replace with your first design task, or "no pickup pending")
- **After:** (next task or "—")
- **Context budget:** end session at ≤30% remaining
- **Standing reminders:** Preserve load-bearing test selectors. New i18n strings land in all locales in the same commit.

### Reviewer queue (optional — delete if not using reviewer role)
- (list tasks awaiting reviewer verdict, in order)

### User actions pending (no session needed)
- (list items only the human can do: domain registration, console toggles, manual deploys, etc.)

---

## Architecture rules ratified
(Architect: as the project ratifies rules over time, list them here for free lookup. Each rule should be a one-liner with a date and a brief rationale. Example: "2026-06-01: All new strings must use the translation hook (no hardcoded en-only). Reason: post-launch i18n audit caught 14 hardcoded strings.")

---

## Process misses log
(Architect: when a session skips a process rule and it costs time, log it here so the pattern is visible. Format: "MISS YYYY-MM-DD: {what was skipped} → {cost in time/effort} → {rule that should have caught it}". Keeps the rules honest.)

---

## Active tasks

(Tasks live here. Use the format below — see process.md §3 for the canonical spec.)

### T1: (Your first task title)
- **Agent:** developer | designer | architect
- **Status:** NEW
- **Plan:** docs/plans/YYYY-MM-DD-bootstrap.md
- **Priority:** P1
- **Created:** YYYY-MM-DD

**Instruction:**
(What to do — specific files, functions, line numbers, guard rails. Be concrete; vague tasks waste sessions.)

**What NOT to change:**
(Explicit guard rails — files/functions to leave alone.)

**Acceptance criteria:**
- [ ] (Concrete verification — test passes, behavior confirmed)
- [ ] (Another verification step)

**Result:**
(Filled by the executing agent when DONE.)

---

## Archive index (last 10 closed tasks — free lookup)

(Architect: after archiving a task, add a one-line entry here so future sessions can answer "what did T-X do?" without opening the archive file.)

- (none yet)

---

*End of current.md.*
