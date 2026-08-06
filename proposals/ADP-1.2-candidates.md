# ADP 1.2 — candidate deltas (PROPOSAL, not ratified)

**Status:** pilot review complete at **n=1** (one production system, ~11-day window,
~214 commits, ~60 tasks). **Not merged into `PROTOCOL.md`.** Per ADP's promotion
rule, portable spec changes graduate only at **n=2** — a second independent project
must reproduce the win. This document records the candidates, the early evidence,
and the caveats, so the eventual 1.2 grade doesn't inherit a false-GREEN.

Grades below: **Graduate-candidate** (fired with concrete wins, n=1) · **Keep**
(cheap, low-signal, worth carrying) · **Pruned** (killed in pilot).

---

## Graduate-candidates (strong n=1 evidence)

### 1. Simplification as a first-class task type (context hygiene)
A task *type* whose deliverable is **subtraction**: collapse shipped-task stubs,
move logs / archive indexes / backlog *out* of standing context, keep the live
dispatch and read-layer memory small. Makes "the corpus should shrink, not grow"
an enforceable unit of work rather than a good intention.

- **Evidence (n=1):** the live task file dropped ~85% (≈66K → ≈10K tokens) in-window.
- **Caveat — the real verdict is unproven.** That reduction was largely a *one-off*
  cleanup (it shrinks the file whether or not the recurring mechanism works). The
  *institutionalization* — generating simplification tasks on a cadence — showed
  **0 recurring uses** after the first. Carry to n=2 as "one-off win proven,
  recurring mechanism unproven"; do **not** treat the 85% as evidence it recurs.

### 2. `Functional-change:` commit trailer
Every commit body carries a one-line trailer stating whether behaviour changed
(e.g. `Functional-change: none — refactor, byte-identical output`). Makes the
behaviour-vs-refactor distinction explicit, greppable, and reviewable.

- **Evidence (n=1):** ~114 commits carried it; the "none" case was load-bearing for
  framing refactors as byte-identical.
- **Reframe for the portable spec:** aim it at *fingerprinting the deterministic
  surfaces* (the unit-tested engines/pure functions), not as a blanket replacement
  for the Check phase.

### 3. Two-verdict CHECK (acceptance + blast radius)
The Check phase produces **two** verdicts: (a) does the task meet acceptance
criteria, and (b) a blast-radius/adjacency read — which *adjacent* subsystems this
change could affect. Directly targets the "semantic conflict across lanes" gap.

- **Evidence (n=1):** on a real task the blast-radius verdict named 3 adjacent
  subsystems that would otherwise have been missed.

### 4. Task taxonomy + recurrence counters
A `Class` field on tasks (New / Adjacent / Duplicate-class / …) plus counters that
**trip an investigation when a class recurs** (e.g. n=3 refactors of the same area →
spawn a consolidation task; a doc-sync counter → schedule a docs refresh).

- **Evidence (n=1):** the refactor counter spawned a real consolidation task — and
  the review *caught the counter over-counting* (6 sites → 2 primitives), i.e. the
  mechanism earned its keep by forcing the investigation.

### 5. Decision-sharing as a named core pattern *(from the market comparison)*
Elevate ADP's already-practiced "upfront decision-sharing" to a named pattern in
`PROTOCOL.md`, with two enforcement legs: **verify-before-claim** (specs ship
verified `file:line` primitives, or a `HYPOTHESIS` tag) and the **single-source-of-
truth engine** rule (one derivation per capability; lanes never re-derive it). This
is what actually answers the "parallel agents make conflicting decisions" critique —
the mechanism exists in production but isn't *named* in the spec.

---

## Keep (cheap, carry to n=2, don't ratify yet)

- **Reject-bound / kill-criteria** — a rule can be *un-adopted* on review and pruned;
  cheap, sound, already used to prune a delta this pilot.
- **Bail-early / prune exploratory reads** — real but modest; overlaps existing
  default-deny-archive + context-budget rules. If proposed at n=2, measure it
  objectively first (files-read-per-Check before/after), not on impression.
- **`.git-blame-ignore-revs`** — a git-archaeology safety net for bulk reformats;
  zero standing cost.

## Pruned in pilot

- **Effort-band header** (per-task effort/token-budget envelope) — **0 uses** across
  ~15 tasks / 11 days. Un-adopted, not merely un-triggered → ceremony under the
  kill-criteria. Failure mode for the record: "optional convention never adopted"
  (not "mechanism tested and failed") — may still merit a scoped trial on a
  model-tier-sensitive install.

---

## n=2 project has arrived (evidence in review, not yet folded)

The second independent install the promotion gate asks for now exists: a
**deterministic embedded C++ / PlatformIO system** — the deliberate opposite of the
n=1 pilot's LLM web stack. Its ~80-round proto-ADP was retrospectively harvested
(cross-map + a drop-in reviewer note for the 2026-07-04 review; both maintained
privately — the project is not public). Recorded here so the gate is visible;
**candidate grades above are unchanged pending the review** (this is n=2 *evidence*,
not a graduation).

Per-candidate n=2 signal (deterministic-stack second occurrence):

- **#1 Simplification** — corroborated as a *concept* (the second install
  independently ratified "coverage-theatre tests are negative-value"); the
  *recurring-mechanism* caveat is untested here too. No change to the caveat.
- **#2 Functional-change / fingerprint** — corroborated **with a precondition**: a
  fingerprint over a *self-consistent mock* is green-forever-wrong-forever (an
  "internally-consistent-but-wrong" hazard observed in the field: host decoder +
  host structs agreed with each other while both diverged from the real device
  wire). The golden suite must exercise the **production path**, not a self-authored
  mock. The install's own fingerprint surface (hash of test output + per-env binary
  size) meets this.
- **#4 Taxonomy + recurrence counters** — corroborated + calibrated: the install's
  promotion ladder shows the **n=1 candidate tier is sweep-fragile** and the
  threshold is **risk-weighted** (high-blast-radius spec rules ran to n=4–6, not n=2).
- **#5 Decision-sharing / verify-before-claim** — **deepened, not just corroborated.**
  The second install shows identifier-level "verify the primitive" is insufficient;
  the real failure class is **semantic** (right name, wrong value / operator /
  mirror-count / arg-order / cardinality — 6 sub-modes), caught in six distinct real
  incidents. Its ratified semantic-verification checklist is a portable, worked
  implementation. This is the one item proposing a **structural addition**: a
  PLAN-side verification pillar. A pre-registered question is on the review table:
  does it graduate now (n=1-install exception) or run the second install's own
  measurement window first.

## Promotion gate

Each graduate-candidate enters `PROTOCOL.md` as **1.2** only when a **second
independent project (n=2)** reproduces its win, carrying the caveats above. Until
then this stays a proposal and the spec stays **1.1**.
