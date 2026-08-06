# ADP 1.2 — Proposal (spec deltas vs 1.1)

**Version target:** 1.2
**Status:** PROPOSED — not yet ratified. Keep `PROTOCOL.md` at 1.1 until these are accepted.
**Date:** 2026-06-20
**Source DNA:** A code review of an external exemplar — `official-stockfish/stockfish` (master) — whose entire culture is ADP's own thesis taken to its limit: *nothing merges on opinion; every change is gated by a measured number.* Plus first principles. See `stockfish-ideas-for-adp.md` for the underlying review.

**Honest grade up front.** Every change below is **candidate, n=1 by analysis** — derived from one external exemplar and sound principle, not from ADP production receipts the way §1–§15 of `PROTOCOL.md` are. This is the same posture as the existing §16 scaling extensions. None is binding until the retrospective (§6.11) promotes it at n=2 from real use. The proposal is written so each delta is independently acceptable or rejectable — adopt the cheap, high-impact ones first and let the rest earn their place.

---

## 0. What 1.2 is

1.1 was about *structure* (lanes, Dispatch, skills, wire format, hooks). 1.2 is about **two things that compound**:

1. **Measured verdicts over human verdicts.** ADP already says "verified, not trusted," but it verifies by an architect *reading and judging*. Stockfish verifies by *comparing a number to a threshold*. Wherever a cheap measurement can replace a judgment call, 1.2 makes that swap — that is the literal mechanization of CHECK.
2. **Token economy without losing rigor.** A chess engine is a machine for maximizing decision quality per unit of compute. The same patterns — prune what can't change the answer, cache what you've already derived, update incrementally, warm-start from last time — map directly onto context budget. Several of these *also* tighten verification, which is why they belong in the same release.

1.2 also **absorbs the already-drafted §16 scaling extensions** (multi-team, SoW→WBS, competition mode, honeycomb) into the same version line. This proposal does not restate §16; it adds the verification + economy layer beneath it.

**The through-line:** replace "the architect read it and it looks right" with "the number says it's right, and the number was cheap to produce."

---

## 1. The change set (14 deltas)

Mirrors the 1.0→1.1 "14 improvements" framing. Each delta lists: the idea, the Stockfish evidence, the **§ it amends**, the concrete spec text to add, **token impact**, and grade. Two clusters — Verification (V) and Economy (E) — but several span both.

### Token-impact legend
- **🔻🔻 direct** — cuts tokens on most sessions immediately.
- **🔻 compounding** — shrinks standing overhead over time.
- **▪ neutral** — correctness/process value, not cost.

---

### V1 — Functional/non-functional declaration + golden fingerprint  🔻🔻
**Evidence.** Stockfish classifies every commit: non-functional ones literally say `No functional change`; functional ones ship a new **bench** (a node count from a fixed ~50-position suite). If behavior changed at all, the number changes. A constant-size proxy for a huge computation.
**Amends:** §6.4 (commit hygiene), §6.1 (CHECK), §6.4 second wall (CI).
**Spec delta:**
- Conventional-commit convention gains a trailer: `Functional-change: yes|no`.
- For any stack where it's feasible, ship a **golden fingerprint**: a fixed scenario/fixture suite whose combined output hashes to one value (the ADP analog of `bench`). The architect picks the suite at install (e.g. "run these N representative inputs through the pipeline, hash the outputs").
- **CHECK diffs the fingerprint instead of re-reading the diff to judge behavior change.** A commit tagged `Functional-change: no` whose fingerprint moved is auto-flagged.
- CI second wall (§6.4) fails the build on that contradiction.
**Token impact:** High and direct — replaces "read the diff + reason about whether behavior changed" (hundreds–thousands of tokens per CHECK) with comparing one number. This is the single most token-positive change in 1.2.
**Grade:** Candidate. The most ADP-shaped import — turns a trust statement into a measurement.

### V2 — Non-regression as a standing CHECK verdict  ▪
**Evidence.** A real Stockfish *bugfix* still had to pass an SPRT proving it loses no Elo elsewhere (`non-reg` band `<-1.75, 0.25>`). "Did it work" and "did it cost anything elsewhere" are two separate, both-mandatory gates.
**Amends:** §6.1 (CHECK).
**Spec delta:** The `🔎 ARCHITECT ACCEPT` block splits into two always-present verdicts: **(1) Acceptance** — criteria met; **(2) Non-regression** — measured-no-cost-elsewhere (baseline diff per §6.1, perf/latency unchanged where relevant, blast radius not broadened). A change cannot close with verdict 1 alone.
**Token impact:** Neutral (one extra heading).
**Grade:** Candidate. Elevates an existing discipline into a non-skippable gate.

### V3 — Two-bound + inconclusive rule promotion, with linked evidence  ▪
**Evidence.** SPRT decides accept / reject / **keep testing** against two Elo bounds; every merge links its test (`tests/view/...`).
**Amends:** §6.9 (n-counter).
**Spec delta:** Reframe promotion from a raw count to a band: a **reject** bound ("does the rule actually prevent the miss, or just add ceremony?") and an **accept** bound ("clearly load-bearing?"), with an explicit **INCONCLUSIVE** verdict. A candidate that recurred twice but where the rule *wouldn't have changed the outcome* does **not** auto-ratify. Every ratification carries a **linked evidence artifact** (process-miss IDs, archive files), so "per the 32nd rule" resolves to receipts.
**Token impact:** Neutral.
**Grade:** Candidate. Honest caveat: ADP's n is tiny — adopt the *shape* (two bounds + neutral zone + linked evidence), not SPRT's statistics.

### V4 — Decaying, bounded rule confidence  🔻
**Evidence.** Stockfish history stats update as `val + bonus − val·|bonus|/D` (bounded, diminishing returns) and age down each iteration (`(val+5)·789/1024`) so stale signal fades automatically.
**Amends:** §6.9, §6.11 (retirement).
**Spec delta:** Each ratified rule / hotspot row carries a numeric **confidence**: bumped (with diminishing returns) on each citation, **decayed each retro window if not cited**. The §6.11 "not cited in 3 retros → retire" rule becomes a computed threshold, not a thing the retro must remember to notice.
**Token impact:** Compounding — automates retirement, which shrinks the always-loaded rules log.
**Grade:** Candidate. Pairs with V3; together they make the rule corpus self-pruning.

### V5 — "Simplification" as a first-class task type  🔻
**Evidence.** A large share of Stockfish merges *remove* code/parameters. A simplification only needs to pass **non-regression** (it may be strength-neutral) — simpler at equal strength ships, because it is strictly better.
**Amends:** §6.3 (task format), §13 (anti-patterns), §6.13 (metrics).
**Spec delta:** Add a **Simplification** task type with an intentionally *lighter* bar — *prove no regression* (the rule/skill/hook/parameter/file can be removed and nothing breaks), not *prove a gain*. Track a **simplification-to-addition ratio** in §6.13; a protocol (or codebase) that only ever grows is a smell. Makes subtraction continuous, not a once-a-retro afterthought.
**Token impact:** Compounding — every removed rule/skill/hook is tokens saved on every future session start. Same lever as the wire format, applied to the corpus.
**Grade:** Candidate. Directly attacks ADP's own named "add-more-rules reflex" (§6.11) with a mechanism instead of a reminder.

### V6 — `.git-blame-ignore-revs` convention  ▪
**Evidence.** Stockfish ships `.git-blame-ignore-revs` and sets `blame.ignoreRevsFile` so mass-format commits don't poison `git blame`.
**Amends:** §6.4, template.
**Spec delta:** Ship `.git-blame-ignore-revs` in the template + a one-line `process.md` rule: mechanical reformats go in their own commit and get appended to the ignore file. Protects the git archaeology the hotspot map (§10.4), archive anchors, and CHECK diffs all depend on.
**Token impact:** Minor — avoids wasted reads chasing reformat noise in blame/diff.
**Grade:** Candidate. Trivial cost, pure upside.

### V7 — Default-NO scope posture  ▪
**Evidence.** Stockfish's `CONTRIBUTING.md` twice states development is "not focused on adding new features"; feature PRs may be closed without discussion. Scope discipline as a stated *default*.
**Amends:** §12 (operating principles).
**Spec delta:** Add a principle: the protocol's default answer to new scope is *no, unless it earns its place* — the same evidence burden every rule faces (§6.9). Gives the architect/business roles a default to push against.
**Token impact:** Neutral (very indirectly: less scope → smaller codebase → smaller index).
**Grade:** Candidate, cultural. One sentence.

### V8 — Rework-rate as the north-star metric  ▪
**Evidence.** Stockfish collapses all judgment to one measured scalar (Elo) — which is *what makes a sequential gate possible at all*.
**Amends:** §6.13 (metrics).
**Spec delta:** Designate **rework-rate** (commits citing a T{N} after its close — the false-accept rate) as ADP's Elo-equivalent north-star; the other three §6.13 metrics become diagnostics. Prerequisite for V3's two-bound gating to mean anything.
**Token impact:** Neutral.
**Grade:** Candidate.

---

### E1 — Aspiration scoping: expected-effort band + escalate-on-breach  🔻🔻
**Evidence.** Stockfish searches a *small* window around the expected score and only re-searches wider (costlier) when the result "fails high/low" — falls outside the band. Cost is spent reactively, on surprise.
**Amends:** §5.3 (model tiering), §6.3 (task format), §16.3 (competition mode).
**Spec delta:** Every task carries an **expected-effort band** (rough token/step/file-count envelope). Coming back *outside* it is the **explicit, logged trigger** to escalate — Sonnet→Opus, single-agent→competition mode, or hand back to the architect. Default narrow and cheap; widen only on a measured breach. Breaches are a retro input (§6.11), not silent overruns.
**Token impact:** High and direct — stops paying max context (Opus, full reads, N× competition) on routine work; reserves it for tasks that prove they need it.
**Grade:** Candidate. Gives §5.3/§16.3 a crisp trigger instead of a vibe.

### E2 — Pruning before retrieval (futility gate + bail-early)  🔻🔻
**Evidence.** Stockfish's whole search is "prove a branch is irrelevant *cheaply* and never expand it" (futility, null-move, late-move pruning). Lazy/early-exit everywhere.
**Amends:** §10.1 (JIT retrieval), §6.7 (archive-access protocol).
**Spec delta:** Before opening any Level-3 skill, archive file, or extra source file, apply a **futility check**: *given what's already loaded, can this read change my acceptance verdict?* If no, prune it. And **bail early** — stop loading the moment acceptance is determined, rather than reading everything that might be relevant. Formalizes ADP's default-deny (§6.7) and JIT (§10.1) into an active stop-condition.
**Token impact:** High and direct — the most ADP-native economy principle Stockfish offers. Targets the single largest variable cost (exploratory reads).
**Grade:** Candidate.

### E3 — Transposition cache of derived facts (keyed, shared across sessions)  🔻🔻
**Evidence.** Stockfish caches each expensive sub-search result keyed by a position hash, in **one global table shared by all threads** — it even allows racy writes (`tt.h:34`) because re-deriving costs more than an occasional stale read.
**Amends:** §9 (wire format — new file), §10.4 (hotspot map composition).
**Spec delta:** Add a small **keyed facts cache** — new wire artifact `.adp/facts.jsonl` (append-only, hash/anchor-keyed): "contract shape of subsystem X," "the seam where fixes for Y go," "where Z is wired" — written once, looked up by key. Parallel sessions **read each other's** derived facts instead of re-deriving them (the developer reuses what the architect just found). The codebase-index (§7.3) is the *static* version of this; the facts cache is the *dynamic memo*. Read-mostly + append-keyed keeps it compatible with file-ownership lanes (like `results.jsonl`).
**Token impact:** High — biggest *multi-session* win. Avoids the same files being read and reasoned over by every session that touches a subsystem.
**Grade:** Candidate. Watch-out: a stale fact is worse than none — every cache entry is anchor-stamped and grep-revalidated before trust (same discipline as the hotspot map, §10.4).

### E4 — Incremental index + "what changed since last session" diff  🔻
**Evidence.** NNUE never recomputes the full evaluation; it updates an **accumulator** by the one feature that changed.
**Amends:** §7.3 (codebase-index), `scripts/generate_map.py`.
**Spec delta:** Make `generate_map.py` **incremental** — update only changed symbols, and emit a small **"index delta since last run"**. A session reads the delta (what moved since last time) instead of re-ingesting the whole index. Compresses both regeneration and per-session re-read.
**Token impact:** Compounding — shrinks the recurring index-read cost, largest on big repos.
**Grade:** Candidate.

### E5 — Value-based archive/memory eviction  🔻
**Evidence.** Stockfish's TT overwrites "less valuable entries (cheapest checks first)" — scored by depth, PV-ness, and *relative age* (generation). Age is one input, not the whole rule.
**Amends:** §6.7 (archive-stub), §10.3 (memory hygiene).
**Spec delta:** Prune memory/archive by a cheap **value score** — `citation-recency × insight-depth × load-bearing?` — not by date alone. Keep an old-but-load-bearing fact; drop a recent-but-never-cited one. Feed §6.11's existing citation-distribution tracking into eviction.
**Token impact:** Compounding — keeps the loadable corpus small and high-signal.
**Grade:** Candidate.

### E6 — Warm-start handoff (carry the load-bearing files)  🔻
**Evidence.** Each Stockfish iteration seeds from the previous one's best move/PV (`bestPreviousScore`, `previousPV`) instead of starting cold.
**Amends:** §6.2 (Dispatch), §6.6 (session-end ritual).
**Spec delta:** The session-end ritual records the **2-3 files the session found load-bearing**; Dispatch carries them forward so the next session skips rediscovery. Cheap addition to the handoff that already exists.
**Token impact:** Compounding — grep/index exploration is a real chunk of every task's tokens; warm-start removes the repeat.
**Grade:** Candidate.

---

## 2. Token-budget summary

The user's priority is reducing token usage without losing efficiency. Ranked by token leverage:

| Delta | Token effect | Why |
|---|---|---|
| **V1** fingerprint | 🔻🔻 direct | CHECK compares one number instead of reading the diff. |
| **E2** prune-before-retrieval | 🔻🔻 direct | Cuts the largest variable cost — exploratory reads. |
| **E3** facts cache | 🔻🔻 direct (multi-session) | Same fact never re-derived across sessions. |
| **E1** aspiration scoping | 🔻🔻 direct | Expensive context spent only on proven-hard tasks. |
| **V5** simplification type | 🔻 compounding | Every removed rule/skill = tokens off every session start. |
| **V4** decaying confidence | 🔻 compounding | Auto-retires rules → smaller standing log. |
| **E4** incremental index | 🔻 compounding | Read the delta, not the whole index. |
| **E5** value-based eviction | 🔻 compounding | Smaller, higher-signal corpus. |
| **E6** warm-start handoff | 🔻 compounding | No rediscovery of last session's files. |
| V2, V3, V6, V7, V8 | ▪ neutral | Verification/process value, not cost. |

**Net:** the four 🔻🔻 items (V1, E2, E3, E1) are the token-reduction core and should land first regardless of the rest. They reduce cost by spending less on *verification reading*, *exploration*, *cross-session re-derivation*, and *over-provisioned tiers* respectively — four distinct cost centers, not the same saving counted four times. None trades away rigor; V1 and E2 *increase* it.

---

## 3. Template / tooling implementation scope (for the build pass after ratification)

Spec-only for now. When ratified, 1.2 will need:

- **`Functional-change:` trailer** in the commit convention + a `fingerprint.sh` (golden-suite hash) + a CI check (V1).
- **`.adp/facts.jsonl`** wire file + syntax-key row in `README.wire` + `wire-sync.sh` support (E3).
- **`scripts/generate_map.py --incremental`** + delta output (E4).
- **`.git-blame-ignore-revs`** in the template + `process.md` rule (V6).
- **Task format additions** in §6.3: `Type: simplification` and `Effort-band:` fields (V5, E1).
- **CHECK template** updated with the two-verdict block (V2) and the futility/bail-early checklist (E2).
- **Rules-log schema** gains a `confidence:` column (V4) and `evidence:` link column (V3).
- **`adp_metrics.py`** gains simplification-ratio and rework-rate-as-headline (V5, V8).

None of these is large individually; the risk is interaction, so implement and run the §11.1 deliberate-violation test per enforcement add.

---

## 4. Migration: 1.1 → 1.2

1.2 is **additive**, like 1.1 before it. Nothing in 1.1 is removed.

1. Drop the new template artifacts in (facts cache, fingerprint script, blame-ignore file, incremental index flag).
2. Add the `Functional-change:` trailer and `.git-blame-ignore-revs` first — they're free and protect everything else.
3. Add the two-verdict CHECK block and the task-format fields.
4. Adopt the four 🔻🔻 economy items (V1, E2, E3, E1) and **measure** against the §6.13 baseline before adding the rest — prove the token saving is real, in the protocol's own "measure, don't impress" spirit.
5. Seed the rules-log `confidence:`/`evidence:` columns from existing entries; let decay run for two retro windows before trusting auto-retirement.
6. Pick an adoption level (§11.2) and hold it two weeks before raising.

**The honest test of 1.2:** re-run the §9.1 protocol-overhead baseline (`wc -c <protocol files> / 4`) and a per-session `/cost` sample before and after. If the four 🔻🔻 items don't move the number, they haven't earned their place — log it as a process-miss and reconsider, exactly as the protocol demands of any unproven rule.

---

## 5. Open questions for ratification

1. **Fingerprint feasibility (V1).** Not every stack has a cheap deterministic golden suite. Is a partial fingerprint (one critical pipeline path) enough, or does it need full coverage to be trustworthy? Lean: partial-but-stable beats none.
2. **Facts-cache staleness (E3).** What's the revalidation cadence — every read, or trust-with-timestamp like the hotspot map? Lean: grep-revalidate on read for load-bearing facts, timestamp-trust for navigation hints.
3. **Confidence decay rate (V4).** One retro window or two before a rule decays past the floor? Lean: two, to avoid retiring a rule that's simply between occurrences.
4. **Does V5's lighter bar get gamed** — "simplifications" that quietly drop needed guardrails? Mitigation: a simplification still passes non-regression (V2) and the fingerprint (V1).

---

*This proposal is candidate 1.2 material, n=1 by analysis. It composes with the existing §16 scaling extensions (also candidate 1.2). The retrospective (§6.11) is the loop that promotes, refines, or retires each delta from real production use. Grounding for every Stockfish claim is in `stockfish-ideas-for-adp.md` and the cited `src/` files.*
