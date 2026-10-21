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
5. **Graph-backed codebase index** *(added 2026-10-19; graphify or equivalent —
   a local tree-sitter knowledge graph exposed through a skill, hooks and ~10 MCP
   tools such as `query_graph`, `shortest_path`, `god_nodes`).* **Delta:** an
   alternative implementation of §7.3 for repos `generate_map.py` cannot read
   (it is Python-only; the spec already names ast-grep + FTS5 as the non-Python
   route, so this is a second named option, not a new pattern). Two optional feeds
   ride on it, each only if the first measures well: `god_nodes` as a *candidate
   source* for §10.4 hotspot rows (a row still needs n=2 and a human-verified seam;
   centrality is a lead, not a hotspot), and graph queries in the Reviewer's
   "context-indexing (read)" slot (§8.3). **Costs, stated up front:** (a) MCP
   tool-listing tokens — at §8.3's own estimate (~100–500 tokens per tool) ~10 tools
   is roughly 1–5K tokens, paid every session whether or not a query is made, so the
   saving has to clear that standing cost first; (b) hook interplay — its PreToolUse hooks
   would sit beside ADP's own, and which one wins is exactly what the *plugin-aware
   precedence* candidate (#4 above) asks the install to write down; installing it
   without that host table is the failure shape that candidate describes; (c) a
   non-stdlib dependency (`uv tool install graphifyy`), against an ADP tooling line
   that is stdlib-only; (d) the vendor's ~71.5x token-saving figure is
   **self-reported** and measured on the vendor's corpus — it is a reason to run
   the pilot, not a number ADP carries. **Bounded pilot (n=0, one install, never a
   rule):** pick one non-Python (or mixed) install and ~10 tasks of ordinary size.
   Run them in two arms on the same task kinds: the install's current route
   (`generate_map.py` where it applies, else ast-grep) versus the graph. Record per
   task **tokens consumed** and **files opened** (from the harness transcript —
   `scripts/adp_metrics.py` does not derive either today: it reads cycle time,
   rework, check-catch and miss trend, so those four run as the *guard*, and the
   two new counts are logged by hand in the Result block until a second use earns
   a script). Count the MCP listing overhead inside the graph arm's tokens, not
   beside them. **Prune if** any of: graph-arm median tokens-per-task is not lower
   than the baseline arm *after* the listing overhead; files-opened does not fall;
   rework rate or check-catch count worsens in the graph arm (a navigation aid that
   makes Check miss more is a net loss whatever it saves); or hook precedence has to
   be resolved by hand more than once. A mixed result (fewer files, same tokens)
   is recorded as such and does not graduate. Honest scope: ten tasks on one install
   cannot separate the tool from the task mix, and a measurement run by the
   install's own harness is self-reported — this narrows the question, it does not
   answer it.

**Rejected in the same scan, with reasons:** an auto-commit snapshot of the whole
tree on every `Stop` (bypasses the PreToolUse hook entirely and contradicts §6.4
rule 1 — the five rules stay on even for a solo operator); a push-refusing hook
(ADP is a published repo; CI is the second wall); static `permissions.ask` lists as
the primary control (a pattern is bypassed by form; ADP's `ask` is a hook decision
on the parsed command, with a test suite behind the parser — and the parser was
bypassed too until it normalised quoting like the shell); per-session model and
effort advice (harness setting; §5.3's perishability note already says the names
rot fastest).

## MCP scan (2026-10-20; n=0 by install)

A scan of open-source MCP servers currently suggested for Claude Code (the
`modelcontextprotocol/servers` reference set, community code-intelligence and
coordination servers, vendor plugins), read against §8.3 and the shipped hooks.
No install was involved, so **nothing below advances an n-counter**. It found one
defect in the spec, one stale cost figure, and two bounded pilots.

**Defect — §8.3 recommends an MCP route around the git hooks.** The §8.3 role table
puts a `git` MCP server in every role. But the shipped PreToolUse and PostToolUse
hooks match `"Bash"` only (`template/.claude/settings.json` and
`settings.node.json` both). A commit made through an MCP tool (the reference git
server exposes `git_add` / `git_commit`, for example) never reaches
`git-hygiene` or `post-commit-orphan-check`: the five §6.4 rules do not run, the
orphan check does not run, and nothing says so. That is the failure shape tooling
1.1.7 fixed for missing jq (*a missing control must say so*), arriving by a
different door. The reference server's `git_commit` also commits the index and has
no pathspec form, so it cannot express §6.4 rule 1 at all. A recommendation in the
spec is the cheapest way to open this door, so this is a defect, not a candidate.
**Fix direction (for the next tooling pass, not applied here):** (a) drop `git`
from the §8.3 table, or mark it read-only (status, diff, log, show) and say that
writes go through Bash, where the hooks are; (b) add a PreToolUse hook on
`mcp__.*` tool names that matches git-write tools (`commit`, `add`, `reset`,
`checkout`, `push` in the tool name) and answers `ask` with the reason. It must
not deny silently (the plugin-aware-precedence failure shape, #4). (c) add the
case to `verify-hooks`: deliberately commit through an MCP git tool once and
confirm the hook fires (§11.1 step 6). The bypass reaches beyond git: any MCP
server that writes files or runs commands sits outside the `Bash` matcher, and
§6.4's critical limitation (hooks are discipline, not a sandbox) should name MCP
tools explicitly.
**Status: fix applied in tooling 1.1.9 (unreleased)** — §8.3/§6.4 text,
`mcp-git-guard.{sh,mjs}`, `verify-hooks`, `test_mcp_git_guard.py`; see CHANGELOG.

**Correction — the §8.3 listing-cost watch-out is host-dependent now.** §8.3 says
MCP tool definitions cost ~100–500 tokens per tool, paid every session. On Claude
Code that has not been the default since tool search shipped as the default
(anthropics/claude-code#12836, closed as shipped 2026-03-11): only tool *names*
are sent up front, and full schemas load on demand. `ENABLE_TOOL_SEARCH=false`
restores the old behaviour, and `auto:N` defers only above N% of context. It still
loads everything up front on older models, on a non-first-party
`ANTHROPIC_BASE_URL`, and on hosts other than Claude Code. That covers ADP's
prose-only and other-model installs, so the watch-out is still true there.
**Fix direction:** keep the sentence, scope it ("on hosts without deferred tool
loading…"), and add one line on how to check (`/context` on Claude Code). The same
correction applies to cost (a) of import-scan candidate #5 (graph-backed index):
on a Claude Code install with tool search on, the standing cost is the names plus
the search tool's own overhead, not 1–5K tokens. The pilot design is unchanged.
It already counts the listing overhead inside the graph arm, which is the right
way to measure it whatever the host does.

**New candidates at n=0 (bounded pilots, never rules):**

6. **Dynamic file reservations (MCP Agent Mail or equivalent).** *Delta:* the lane
   table in `process.md` §4 is static. Two sessions in the same lane, or a task that
   crosses lanes, have no machine-visible claim on files. Agent Mail
   (`Dicklesworthstone/mcp_agent_mail`) offers advisory, TTL-bound reservations on
   paths and globs (`file_reservation_paths`, `release_file_reservations`). Each one
   is written as a JSON artifact in git, stale leases are released automatically,
   and an **optional pre-commit guard blocks a commit that touches another agent's
   exclusive reservation**. That guard is a git hook, so it holds whatever tool
   made the commit. That closes, for this one rule, the door the defect above
   opens. **Pilot only the reservations.** The messaging half (inbox, threads,
   acks) is a second coordination channel beside the Dispatch. It contradicts
   "Dispatch is the handoff, not chat" (§8.4) and the single-source rule (#5), so
   the pilot leaves it unused. **Costs:** a non-stdlib dependency (Python package
   plus a local server), against the stdlib-only tooling line. Another set of MCP
   tools. A pre-commit hook beside ADP's own, which needs the host table from #4.
   And advisory leases add ceremony, the pruning cause in this pilot's history.
   **Bounded pilot:** one install that already runs ≥2 implementing sessions in
   parallel, over ~2 weeks of normal work. Log every reservation conflict the guard
   raises, every commit collision or orphan that still happens, and every lease
   that had to be cleared by hand. **Prune if** no conflict is caught that the
   static lanes would have missed. Also prune if a lease blocks legitimate work
   more than once, or if sessions skip reserving (an unused control is ceremony).
   Honest scope: a solo operator running one implementing session at a time has
   nothing for this to catch. The pilot needs real parallelism or it measures
   nothing.

7. **Mechanical blast radius for the CHECK (code-review-graph or equivalent).**
   *Delta:* graduate-candidate #3 (two-verdict CHECK) asks the checker for a
   blast-radius verdict, which today comes from reading the diff.
   `tirth8205/code-review-graph` builds a local tree-sitter graph (SQLite, many
   languages) and answers "what callers, dependents and tests does this change
   reach". It does so as an MCP tool (`get_impact_radius_tool`) and also as a plain
   CLI (`code-review-graph detect-changes --brief --base main`). **Pilot through the
   CLI, not the MCP server.** That keeps it out of the tool listing and the hook
   precedence question, and makes it a script the checker runs, not a tool the
   implementer leans on. Do not install its PreToolUse hooks during the pilot. They
   steer Grep and Glob toward graph queries, which would confound the measurement
   and sit beside ADP's hooks. **Bounded pilot:** ~10 CHECKs on one install,
   non-Python or mixed preferred. The checker writes the blast-radius verdict
   first, then runs the CLI and records what it added: affected files or tests not
   named in the verdict, and whether any turned out to matter (a failing or missing
   test, a caller needing change). **Prune if** across the run the CLI names nothing
   the checker missed that mattered, or if its false leads cost more check time
   than they save. *Overlap:* this also implements import-scan candidate #5's index.
   If both pilots run on one install, use one graph tool for both and report the two
   measurements separately. #5 measures navigation tokens. This one measures
   check-catch. The vendor's token-saving figures are self-reported and are not
   carried. Honest scope: ten checks cannot tell a tool effect from an easy batch.
   A catch counts only when the issue was confirmed, not merely flagged.

**Considered and not entered:** a project-tracker MCP in the architect row of §8.3
(Linear and the like) would be a second task store beside `docs/tasks/current.md`,
and two stores always diverge (#5). The §8.3 row should say "read-only, if any". The
reference *Memory* server (a knowledge graph) would be a second memory beside the
`memory/` layer, for the same reason. The reference *Sequential Thinking* server is
superseded by native model thinking (§5.3 already treats such settings as harness
matters). Multi-model review servers (PAL / zen) were weighed as an implementation
of import-scan candidate #1 (blind second route). A second model reading the same
artifact is a second *reader* on the same route, not an independent route, so it
does not meet #1's bar. It could still serve as an outside reviewer, but that is
§8.3's Reviewer slot, not a new candidate.

## Runtime scan (2026-10-21; n=0 by install)

A desk read of NVIDIA OpenShell (Apache-2.0, v0.1.5 at the time of reading) and the
Nemotron 3 open-weight models, set against §6.4's critical limitation, §8.5 and
§5.3. Sources were the vendor docs, the support matrix, the Nemotron 3 Super
technical report and third-party reviews. Nothing was installed or run, so
**nothing below advances an n-counter**.

8. **Lane-scoped sandbox per role (OpenShell or equivalent).** *Delta:* §8.5 already
   says that hard guarantees need "a container/devcontainer with a filesystem mount
   limited to its lane", and that the lane table "doubles as the mount spec". It
   names no implementation and no test. §6.4's critical limitation is the gap this
   fills: hooks run inside the agent's own tool loop, so an Edit can rewrite them,
   and any tool outside their matcher (the MCP door the defect above closed for git
   only) goes around them. OpenShell enforces outside the agent workload:
   - **Files:** Landlock path policy, fixed when the sandbox is created.
   - **Commands:** seccomp, and an unprivileged process identity.
   - **Network:** an egress allow-list that can be reloaded while the sandbox runs.
   - **Credentials:** the gateway resolves placeholder credentials only at
     authorised endpoints, so the agent never holds a live key.

   Policies are YAML that can be version-controlled. Per the vendor docs, Claude
   Code, Codex, OpenCode and Copilot CLI run inside it unmodified, which keeps ADP
   host-agnostic. The mapping: one sandbox per role session. Its worktree (the
   worktree-per-session candidate) is writable only on the role's lane paths from
   `process.md` §4. The rest of the tree, **including `.claude/` and the hook
   scripts**, is read-only. Egress is limited to the model endpoint and the git
   remote. That turns three §6.4 "discipline" items into enforced ones: lane
   edits, self-editing hooks, and writes through tools the matcher cannot see.
   **Costs:** Docker Desktop (or Podman or a microVM) on every operator machine.
   On macOS the kernel controls run inside Docker's Linux VM. Also a young project
   (weekly stable releases, interfaces marked Experimental can change in a patch),
   a gateway process to run, and one more policy file per role that drifts if the
   lane table changes without it. The pilot generates the policy from the lane
   table rather than hand-writing it, or drift is guaranteed.
   **Bounded pilot:** one install, one role first (reviewer, then developer), for
   ~2 weeks of normal work. Before any normal work, run §11.1 step 6 inside the
   sandbox: edit a file outside the lane, edit a hook script, commit through an MCP
   git tool, and read a credential file. Each must be refused **by the sandbox**,
   with the hooks disabled for the test so they don't take the credit. Then log
   every legitimate action the policy blocked, the setup time per session, and
   every policy edit forced by a lane-table change. **Prune if** any of the four
   violations gets through. Also prune if legitimate work is blocked more than
   twice a week, or if per-session setup costs more than a few minutes. *Overlap:*
   this holds candidate #6's reservations as hard boundaries for static lanes
   only. Dynamic, cross-lane claims stay #6's job. Honest scope: this guards
   against an agent's mistake, a prompt injection or a hook bypass. It does not
   guard against a wrong change made inside the lane, which is still the CHECK's
   job.

   **Boundary trial run 2026-10-21 (n=0; `evidence/openshell_lane_trial_2026-10-21.md`):**
   one designer-lane sandbox ran on a throwaway clone, with shell commands only and
   no agent session. Intel macOS is not on the support matrix. It ran through the
   gateway container plus the Linux CLI in a container.
   - Writes outside the lane were refused on every route tried (shell, python,
     node, git work tree). Edits to hooks and `settings.json` were refused, and
     so were egress and credential reads.
   - **V3 got through with `.git` writable.** Git plumbing committed an
     outside-lane file without touching the work tree, and `.git/hooks` was
     writable. A path-level sandbox cannot scope commits.
   - With `.git` read-only, all four violations were refused. The cost is that
     commits move out of the sandbox, onto a pathspec commit where the hooks run.

   **Design amended:** `.git` is read-only inside a lane sandbox, and the commit
   gate sits outside it. The two-week pilot is still unrun.

**Considered and not entered — Nemotron 3 as a model tier.** ADP is a protocol, not a
model consumer, and §5.3 recommends tiers, not vendors.

| Model | Size (total / active) | Published result |
|---|---|---|
| Nemotron 3 Nano | 30B | — |
| Nemotron 3 Super | 120B / 12B | SWE-bench Verified ~60% (OpenHands), about 6 points behind Qwen3.5-122B |
| Nemotron 3 Ultra | ~550B / ~55B | ~48 on the Artificial Analysis index |

All three are open-weight under the NVIDIA Open Model License, which allows
commercial use. None is near the frontier tier ADP's roles run on today. The one
real use is a data-sovereign install: a non-Claude host, a local model in the
cheap "locate" slot (§5.3, locate-don't-extract), and OpenShell's privacy router
keeping code on the machine. That is a deployment option for a client who needs
it, not a protocol delta. It enters only if such an install exists and measures the
locate tier's miss rate.

**Correction — the §5.3 tier table is stale.** It names Opus/Sonnet/Haiku 4.x and
the 2026-06 prices. The current generation is the Claude 5 family. Its own
perishability note asks for re-verification. **Fix direction (next tooling pass,
not applied here):** re-verify names and prices, along with the pinned `model:`
strings in `template/.claude/agents/*.md`.

## Promotion gate

Each graduate-candidate enters `PROTOCOL.md` as **1.2** only when a **second
independent project (n=2)** reproduces its win, carrying the caveats above. Until
then this stays a proposal and the spec stays **1.1**. *(Status 2026-10-02: the
pathspec-commit delta above is still the only one to clear the gate; no result
from the second install's forward measurement window — the blocker for the rest —
is recorded yet. Protocol review run 2 added evidence on one install and graduates nothing.)*
