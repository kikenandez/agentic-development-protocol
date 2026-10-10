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
- **Caveat UPDATE (post-pilot, 2026-08-08):** in the five weeks after the review,
  the mechanism fired repeatedly **without external forcing** on the same install —
  an in-place trim of a standing process section, a multi-commit fold of the
  doc-debt ledger into the canonical docs, and a spawned repair task after
  measuring an archive index ~22% unreachable. Recurrence is now **proven within
  the n=1 install**; still awaiting any second-install recurrence.

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
- **Calibration UPDATE (post-pilot, 2026-08-08) — a counter DESIGN failure mode:**
  the doc-sync counter as adopted **could not fire** — it reset on any touch to the
  breadcrumb ledger, i.e. on the very activity it was built to force. Found five
  weeks later with a 10-entry unfolded backlog and the trigger never having fired.
  Portable rule for any recurrence counter: **a counter that resets on the activity
  it is meant to force will never fire — count the BACKLOG (unfolded entries), not
  the touches.** Only the corrective action (a fold) reduces the count.

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
- **#5, single-source-engine leg — UPDATE (protocol review run 2, 2026-10-02).**
  The n=1 install recorded **5 ESCAPED instances, 3 of them reaching production**,
  of a second derivation of one capability drifting from the first
  (2026-09-19 → 10-02). Repeated incidents on **one install**: stronger evidence for
  the leg, not a graduation. Receipt:
  [`evidence/protocolreview_run2_webapp_2026-10-02.md`](../evidence/protocolreview_run2_webapp_2026-10-02.md).

## First candidate at n=2: explicit-pathspec commits

One commit-hygiene delta has now been **independently ratified by both installs,
from real sweep incidents on opposite stacks** (embedded C++ shared-worktree; LLM
web shared-worktree): with parallel sessions on one working tree, a bare
`git commit` snapshots the entire shared index and sweeps a co-session's staged
files — exact-path *staging* and pre-commit status checks on the victim's side
cannot prevent it. Both installs converged on the same remedy:

> **Always commit with an explicit pathspec: `git commit -- <paths>`.** A hygiene
> rule that depends on *when* you look is weaker than one that constrains *what
> the command can touch*. (Obviated above worktree-per-session; required below it.)

This is the promotion gate satisfied as written — ratifiable into `PROTOCOL.md`
§6.4 at the next spec pass, independent of the pending measurement window.

**Its boundary, found immediately by the first install:** pathspec commits (and
every other hygiene rule) operate at **file** granularity, so none can see two
lanes' content inside ONE legitimately-shared file — see the shared-file candidate
below.

---

## Post-pilot deltas from the n=1 install (harvested 2026-08-08; n=1 by install)

The n=1 install kept running the graduated deltas for five weeks after its review
and ratified three further mechanisms from live incidents. Recorded here as new
candidates awaiting their own n=2:

1. **Escape-classified miss log** *(extends #4 and the two-bound rule).* When
   detection improves, the miss count **rises** while cost-per-entry collapses —
   and a naive one-rule-per-miss reflex then over-mints rules on a corpus whose
   binding constraint is recall. Rule: tag every miss `Escape: CAUGHT` (falsified
   before any code was written against it — a gate *success*) or `ESCAPED`
   (reached code/commit/prod/a closed verdict); **only ESCAPED entries advance a
   candidate rule's n-counter**; a repeated CAUGHT shape produces a one-line
   spec-body **`VERIFY:` field** — the architect names the single premise they are
   least certain of, and the implementing session checks it FIRST, reporting
   CONFIRMED/FALSIFIED. Selection heuristic with real receipts: *flag the claim
   that makes the problem look simplest* — across six consecutive misses the
   tidier reading was wrong every time. (Converges with candidate #5's PLAN-side
   verification pillar from the opposite direction: a per-task named-uncertainty
   bet vs a semantic checklist — one pillar, two forms; do not double-count.)

2. **Subsume-or-don't-ratify** *(extends #1's subtraction ethos to the rule corpus
   itself).* Tracking a simplification-to-addition ratio is not enforcement — one
   week ran 6 rule additions / 0 simplifications on a ~50-rule corpus. Rule: a
   ratification note MUST name what the new rule subsumes, replaces, or downgrades
   — or state why nothing is subsumable. Preference: generalize an existing rule
   in place → absorb as a sub-case (keeping its mechanical check verbatim) → only
   then a new number, with a sentence on why the first two fail. Guard: subsuming
   must never replace a mechanical check with a judgment call — generalization
   adds a *trigger* that indexes existing checks, never deletes them.

3. **Shared-file ownership follows EDIT SHAPE** *(closes the gap above the
   pathspec rule).* When two lanes legitimately edit one file, every file-granular
   hygiene rule is blind. Resolution keys on the file's edit shape, not its
   directory: **narrative, edited-in-place** shared files get a **single writer**
   (lanes deliver content through their session handoff instead); **append-only /
   row-oriented ledgers** stay lane-writable in-commit (centralizing would
   recreate the staleness they exist to prevent), and their residual sweep
   exposure is neutralized by scoping the commit's *label* to the file's purpose
   rather than to the committer's task. Diagnostic that picks the right fix:
   "two lanes touched one file" is **two** failure modes — content *lost* vs
   content *mislabelled* — and partitioning fixes only the first.

## From protocol review run 2 (2026-10-02; n=1 by install)

4. **Plugin-aware precedence** *(extends the layered-rules precedence clause).*
   Installed plugins issue rules through hooks and skills that no protocol layer
   lists — one blocked a commit call on the night it was found. Rule: the
   precedence clause names plugins explicitly, and the install keeps a host table
   of the hooks that fire (event, matcher, what it blocks). Folded into
   `protocolreview.md` step 3c as a review check; awaiting a second install for
   the spec.

## Import scan (2026-10-10; n=0 by install — convergence notes, not counter advances)

Material from outside ADP installs, graded under `protocolreview.md` step 5, with the
scan itself rechecked adversarially before anything was edited (step 5, v0.3). None
of it comes from an install with a measurement window, so **nothing below advances
an n-counter** (MEASUREMENT.md §3 requires a second *install*); what it adds is
convergence notes on existing candidates, two tooling fixes, four notations, and
new candidates at n=0.

**Shipped as tooling (1.1.7), no rule minted:**
- `scripts/adp_bounds.py` + tests — mechanical caps on `current.md` (lines, bytes,
  Dispatch block) and the memory read layer. "Keep it small" was advice; it is now
  a check a hook or CI can run, with the advice left in `process.md`.
- **Hooks fail visible** — the bash hooks now say so (ask / context line) when jq
  is missing instead of exiting 0. This was a documented ADP limit (README: "without
  it they silently no-op") that no review had graded as a defect; the simpler rule
  it failed is *a missing control must say so*.

**Folded as notations / sub-cases (PROTOCOL §6.3, §6.8, §5.3, §13; template):**
- `Supersedes:` field on tasks and plans — the one of six memory-audit questions
  ("how does a decision make the previous one obsolete?") ADP answered weakly.
- Provenance tags `[read: …] [calc: …] [hyp: …]` as the Result-block short form of
  the HYPOTHESIS discipline for values.
- Locate-don't-extract line in §5.3 + a §13 anti-pattern: a cheap tier's count or
  list is a pointer, not a fact — indexes `protocolreview.md` step 5 and S6 rather
  than adding a check.
- BLOCKED body shape in the template rules table: question · candidate answers ·
  what each changes.
- Rule 1 of §6.4 generalised in place to the **pathspec commit form** — the one
  delta that had already cleared the n=2 gate (see above); folded now rather than
  numbered as a sixth rule, per subsume-or-don't.

**Convergence notes on existing candidates (qualitative, from outside installs):**
- **#3 two-verdict CHECK** — an evidence-reuse-by-risk table (what must be rerun
  for docs / normal code / security / user-visible changes) reaches the same goal
  without a separate non-regression verdict.
- **#4 recurrence counters / plugin-aware precedence** — the same plugin failure
  shape reported independently: a ready-made rules plugin that blocked without
  telling the model why, replaced by a small script of the operator's own.
- **#5 single-source engine** — restated independently as "two memories carrying
  the same facts always diverge"; and a one-spec-copy, installed-layer-only layout
  in a prose-only install.
- **Model routing by task class** — an economy-by-default matrix with no silent
  escalation and no retry on failure, seen in a prose-only install on other
  models; the pruned effort-band header (E1) was the wrong *form* of this idea, not
  the wrong idea. Re-enter as a candidate only with a cost receipt from an install.

**New candidates at n=0 (enter as template questions or bounded pilots, never as
rules — protocolreview step 6):**
1. **Blind second route for published counts.** Before a count is published, a
   verifier that has **not seen the value** finds it by an **independent route** (a
   different script, a hand grep, a different artifact — re-running the same script
   at the pinned commit is reproduction, not a second route) and returns value ·
   route · *independence* · status. Two values differ → stop, log a miss. Run it in
   a read-only worktree (§8.5), not merely with write tools removed — a verifier
   with Bash can still write. Honest scope: a verifier run by the author's own
   harness is still self-reported; this narrows one error class, it does not answer
   the README's limit, which only an outside install answers.
2. **Labelled self-check.** When one session both implements and checks, the
   verdict heading says `SELF-CHECK`, never `ACCEPT` — so a role switch cannot pass
   as independent review. Cheap; enters as a template heading variant for solo
   operators.
3. **Approval preflight.** Before a task goes IN_PROGRESS, the permissions and
   credentials it needs are confirmed present — never launch a run to discover a
   missing permission. Enters as a Dispatch standing reminder.
4. **Supervised run-in before unattended automation.** Entered as a VERIFY question
   in the retro template (§7), with **no fixed N**: how many supervised runs did the
   automation have, and what did its last deviation change? Earns a number only if
   an install logs an ESCAPED miss from an un-run-in automation.

**Rejected in the same scan, with reasons:** an auto-commit snapshot of the whole
tree on every `Stop` (bypasses the PreToolUse hook entirely and contradicts §6.4
rule 1 — the five rules stay on even for a solo operator); a push-refusing hook
(ADP is a published repo; CI is the second wall); static `permissions.ask` lists as
the primary control (a pattern is bypassed by form; ADP's `ask` is a hook decision
on the parsed command, with a test suite behind the parser — and the parser was
bypassed too until it normalised quoting like the shell); per-session model and
effort advice (harness setting; §5.3's perishability note already says the names
rot fastest).

## Promotion gate

Each graduate-candidate enters `PROTOCOL.md` as **1.2** only when a **second
independent project (n=2)** reproduces its win, carrying the caveats above. Until
then this stays a proposal and the spec stays **1.1**. *(Status 2026-10-02: the
pathspec-commit delta above is still the only one to clear the gate; no result
from the second install's forward measurement window — the blocker for the rest —
is recorded yet. Protocol review run 2 added evidence on one install and graduates nothing.)*
