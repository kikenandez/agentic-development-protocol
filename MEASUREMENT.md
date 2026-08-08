# MEASUREMENT.md — how ADP counts what it claims

**Purpose:** every number ADP publishes about itself (commits, tasks, deploy rounds,
accepted/falsified claims, the four metrics) is a hypothesis with a measurement
procedure attached. This file is the procedure. Reproducing our counts is the weaker
exercise; running the procedure on **your** install is the audit that matters
(see `.github/ISSUE_TEMPLATE/install-report.md`).

**Status:** v1 — definitions extracted from the source install's working practice.
Where a definition has known looseness, it is marked. Report any place a definition
does not survive contact with your workflow; that is itself a finding.

---

## 1. Units of count

**Task.** A T-numbered unit of work with a written spec, an owner lane, and a
terminal verdict. A task *counts* when it has an archive record; a task closed
without one is invisible to the metrics. **Known looseness:** this makes every
count a floor estimate — deliberate: if the metrics look wrong, the first finding
is that convention adherence slipped, which is retro input.

**Deploy round.** One production deploy plus its full gate sequence (pre-deploy
verification through post-deploy production check). An aborted deploy that ships
no revision is not a round; it is logged as an incident on the round that follows.

**Claim.** A specific, falsifiable assertion given a verdict at a review gate —
task acceptance verdicts, rule ratifications, and protocol-audit findings all count.
Claims are counted at the verdict, not at the assertion.

**Miss.** A numbered entry in the process-miss ledger: a defect of the *process*
(a wrong premise, a skipped gate, a rule that failed to fire), not merely a code
bug. Every miss names its cost and its mechanical fix, and (since 2026-08) carries
an escape classification (§3).

## 2. The claim-acceptance procedure (evidence-based CHECK)

A task is accepted only by a role that did not implement it, against evidence:

1. **Verdict 1 — acceptance:** does the work meet the written acceptance criteria?
   Judged against receipts (test output with counts compared — not just pass/fail —
   file diffs, log lines, reproduction runs), never against the implementer's
   summary. No evidence, no acceptance.
2. **Verdict 2 — blast radius:** which *adjacent* subsystems could this change
   affect? Named explicitly, even when the answer is "none".
3. Possible outcomes: **ACCEPT** (both verdicts recorded), **RETURN-FOR-FIX**
   (counted as a Check-catch), or **PROVISIONAL** (accepted contingent on a named
   outstanding check — e.g. a suite that could not run; the contingency must be
   discharged before the next release ships).

**Counting rule:** "529 accepted / 22 falsified" counts terminal verdicts on claims.
FALSIFIED means a claim was accepted-then-overturned or asserted-then-disproven at
a gate, and is published as such.

## 3. Recurrence counting (the n-counter) and the escape classification

- A rule enters as **candidate at n=1** (one miss motivates it; not enforced).
- **Ratified at n=2** on *independent* recurrence — a second incident not caused by
  the first, in a different task or subsystem. Same-task re-occurrences do not
  advance the counter.
- **Risk-weighted thresholds:** high-blast-radius rules (those that would change
  what many sessions do) are held to **n=4–6** before ratification.
- **Promoted to the portable standard** only when a **second independent install**
  reproduces the win (cross-project step). This gate has fired once to date:
  pathspec-scoped commits (see `proposals/ADP-1.2-candidates.md`).
- **Escape classification (2026-08):** every miss is tagged **CAUGHT** (falsified at
  a gate before any code was written against it — a gate success) or **ESCAPED**
  (reached code, a commit, production, or a closed verdict). **Only ESCAPED entries
  advance a rule's n-counter.** Rationale: as detection improves, the raw miss count
  rises while cost-per-entry collapses; undifferentiated, that reads as quality
  collapse and over-mints rules.
- **Counter design rule (falsification-record entry):** a recurrence counter that
  resets on the activity it is meant to force will never fire. Counters count the
  **backlog** (uncorrected instances), not the touches; only the corrective action
  reduces the count.
- **Un-adoption (kill-criteria):** a rule is removed when a review finds it costs
  more than it catches — the operative test is the reject-bound: *would the rule
  have changed the outcome of the incidents since adoption?* Zero uses across a
  review window = ceremony. Removals are recorded, not deleted.

## 4. Reopen-reason classification (what is and is not a false accept)

A reopened task counts against the gate (rework) **only** when the reopen reason is
a defect that existed at acceptance time and the receipts should have shown it.
Classification at reopen, recorded on the task:

| Class | Counts as false accept? |
|---|---|
| Defect present at accept, visible in the receipts reviewed | **Yes** |
| Defect present at accept, invisible to the gate that ran (wrong environment; mechanism inert where verified) | Yes — and additionally logs a gate-coverage miss |
| Changed requirements or product decision after accept | No |
| External dependency change (API, platform, library) | No |
| New scope discovered that the original criteria never covered | No |

## 5. The four derived metrics

Produced by `current/scripts/adp_metrics.py` from existing artifacts — no
per-session bookkeeping:

| Metric | Source | Read as |
|---|---|---|
| Cycle time | task `Created:` date → archive filename date | Throughput; watch the **median** (one research spike skews means) |
| Rework rate | commits citing a task ID *after* its close date | *Candidate* false-accept proxy — only after §4 classification |
| Check-catch count | RETURN-FOR-FIX verdicts in archives | Read jointly with rework: high catches + low rework = the gate works; low catches + high rework = the gate rubber-stamps |
| Process-miss trend | the miss ledger, bucketed by review window | Only meaningful after the §3 escape split |

**Baseline discipline.** A number without a baseline is marketing. Capture 2–4 weeks
of pre-ADP history where git supports the reconstruction; where it doesn't, the
first two weeks post-install are the baseline and the claim is a **trend**, not a
before/after. State which one you are using, in writing.

**Deliberately not measured:** deploy frequency as a virtue (the deploy ladder caps
it by design); lines of code or token volume as output (both are costs); per-person
metrics (misses are numbered by entry, not by author).

## 6. Honest limits

These procedures produce floor estimates from conventions. A miss never noticed is
never logged (the ledger bounds failure from below, never above); the successes of
preventive checks are structurally invisible in a miss-only ledger and must not be
cited as evidence a discipline is unnecessary; and all counts to date are
self-reported by the protocol's author — the audit that settles them is the next
independent install, not this file.
