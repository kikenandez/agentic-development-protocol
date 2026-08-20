# The Protocol Review — a recurring improvement ritual for ADP installs

**Status:** TOOL, v0.1 — extracted 2026-08-20 from a full review run on the n=1
production install (nexus_pmo). One complete execution; every step below carries
a receipt from that run. Portable by design; graded honestly where it is not.
**Companion docs:** `proposals/ADP-1.2-candidates.md` (what a review can graduate),
`stockfish-ideas-for-adp.md` (the external-import method, worked),
`proposals/semantic-verification-checklist.md` (a review import that reached n=2).

---

## What it is

A protocol review is a session whose **subject is the protocol, not the product**.
The install's own experience shows why it must be scheduled rather than hoped for:
rules accumulate per-mistake and are rarely removed; miss logs grow while their
meaning inverts (better detection reads as worse quality); the standing context
files bloat until they degrade every session that boots from them; and indexing
errors between short-term memory (the dispatch file) and long-term memory (the
archive) accumulate silently — because no ordinary task ever has them as its subject.

**Cadence:** every 2–4 weeks, or triggered early by any of: the dispatch file
breaching its size target · a user-observed quality dip · a review-window with
zero rule disposals two times running (see step 3d — the corpus is supposed to
shrink sometimes).

**Precondition:** run it at a round boundary with lanes quiet. A protocol review
on a bloated dispatch file is reviewing the wrong artifact — do the hygiene
INSIDE the review (step 4), not before it.

---

## The seven steps

### 1. Read the miss ledger for QUALITY, not detection

Compute the **north-star: rework-rate** — misses that ESCAPED into shipped code,
filed specs, or closed verdicts, over the window. Count CAUGHT misses separately;
they are detection diagnostics. **Never read the raw miss count as quality in
either direction** — the n=1 install measured rising counts with collapsing
per-miss cost, the signature of better detection, and nearly read it as decline.

> Receipt (2026-08-20): 44 misses in 5 days, exactly 2 ESCAPED. The correct
> verdict was "detection healthy, recall failing" — the opposite of what the
> raw count suggested.

### 2. Family analysis — fix at the ACT, not the artifact

Group the window's misses by recurring shape. For each family ask: **where does
the fix have to live so it fires at the moment of the error?** The ladder, best
to worst: a mechanical check at the act that produces the error → a line in the
artifact template → a remembered lesson. A family that keeps recurring despite a
documented fix is almost always fixed one level too far from the act.

> Receipt: one miss repeated an earlier miss *five hours after the author quoted
> that miss at themselves in a commit message*. The fix that finally landed was a
> six-question pre-flight card run at the single act all the failures shared
> (writing dispatch/spec/ruling text forward) — one card indexing six families,
> instead of six more rules.

### 3. Rules-corpus audit — four checks, all mechanical

**(a) Reachability.** Grep the protocol for its own claim about where the rules
live; open that location. A rules corpus can be swept into an archive by an
ordinary cleanup and *nothing notices*, because no task reads "the rules block"
as its input.
> Receipt: the n=1 install's numbered-rules block had been swept into a
> default-deny archive **the day before** the review — every session since had
> booted without its rules reachable. Restored to a dedicated ledger file that
> no cleanup cadence is permitted to touch.

**(b) Count derivability.** Can the corpus size be re-derived by counting? If the
prose says "N rules" and the block holds fewer with unexplained gaps, the count
is a figure nobody can check — the exact failure the protocol bans elsewhere.
Fix: a **retirement ledger** (retired/absorbed rules move to a RETIRED section
with date, reason, and where their mechanical checks went — never deleted).

**(c) Contradiction scan — across ALL layers.** Enumerate every layer that issues
rules to a session (project protocol · role prompts · user-global config ·
org templates), then scan for the same topic ruled differently. Do it
mechanically: published evaluation work shows models *detect* instruction
conflicts well but **silently pick a side rather than flagging them** — so an
undetected contradiction does not announce itself, it just makes sessions
inconsistent.
> Receipt: the user-global workflow file taught "the executing agent fills the
> Result field" — the project protocol had ratified the exact opposite after a
> real shared-file sweep. Fixed with a **precedence clause** in the global file:
> *a project's own protocol overrides this file entirely; this file is the
> default only where no project protocol exists.* That clause is the portable
> fix for every layered-rules install.

**(d) Citation-decay disposal.** Each rule carries a citation baseline; each
review counts *fresh* citations over material added since the previous review
(`git log --since=<last review> --name-only`, grepped for the rule's citation
forms). **Two windows uncited ⇒ the review MUST dispose: retire, subsume, or
record in the rule's entry why it stays.** Silence is not a disposition. Rules
enforced by code (a hook, a script, a test) are exempt — the enforcement is the
citation — and are the first candidates for absorbing into the mechanism's own
documentation. This converts "the corpus should shrink" from a good intention
into arithmetic (the Stockfish history-decay import, B3).

### 4. Memory-layer integrity — short-term and long-term

**Short-term (the dispatch file):** measure raw size against the target; find
blocks still claiming authority after being superseded; then collapse — with the
install's own safety rails (obligation-marker scan before deleting any stub;
archive guards run BEFORE the cut, because the cut removes their input; removed
content moved **verbatim** with provenance markers, never summarised).
**Long-term (the archive):** regenerate the index *after* staging new files
(generation order has produced orphans twice); run the closed-task-has-a-record
guard; any reachability check must be a **transitive closure over all roots** —
one-hop checks have twice reported alarming orphan counts that were actually zero.

> Receipt: dispatch file 3,757 → 839 lines in one pass, zero obligations lost
> (the pre-deletion scan re-homed every live one), guards green before and after.
> Treat size as a **quality input, not only a cost**: an oversized dispatch file
> degrades every session that reads it — the user independently observed the
> quality dip before the size was measured.

### 5. External import scan

Pick one high-discipline comparable (a mature OSS project, another ADP install,
this repo's candidates list) and grade each transferable idea against what the
install already has: **sharpens-existing / new / rejected — with receipts.**
Import the *shape* of a mechanism, never its scale (SPRT's 70k-trial statistics
don't transfer; its two-bounds-plus-inconclusive verdict shape does).

> Receipt: of the Stockfish shortlist, five items were already adopted in prior
> reviews (trailer, two-verdict check, reject-bound, simplification type,
> blame-ignore-revs); this review adopted B3 (citation decay) and B5 (north-star
> metric) and imported the semantic checklist's two missing classes (S2 wrong
> operator, S4 wrong argument rule) as sub-cases of an existing rule — no new
> rule number minted.

### 6. Fold and ratify — under subsume-or-don't

Every change the review makes obeys the install's own ratification discipline:
prefer generalizing an existing rule in place, then absorbing as a sub-case with
mechanical checks kept **verbatim**, and only then a new number with a sentence
on why both cheaper routes fail. Every ratification names its evidence (miss
IDs, archive files, measured figures). Simplification work discovered by the
review is **filed as first-class tasks** with the lighter prove-no-regression
bar — never left as intentions.

### 7. The handover ritual — the review ends in commits, not chat

The review's last act is the same session-end ritual as any architect session,
and it is load-bearing here because a protocol review changes the very files the
next session boots from:

1. **Commits named** — every protocol edit, collapse, and ratification with its
   hash; the handover is IN the repository, not in the conversation.
2. **The owed list REGENERATED, never copied** — every task the handover names
   gets its current status read in the same act that writes the list (the
   copied-forward owed list is the single most repeated staleness vector on the
   n=1 install: three misses in one week).
3. **What this session got wrong** — logged with the same honesty as any round;
   a review session's own errors are miss-ledger entries like any other.
4. **The next review's trigger stated** — a date, or the measurable condition
   that fires early.

---

## Outputs checklist (what a completed review leaves behind)

- [ ] Rework-rate stated for the window (escaped vs caught, separately)
- [ ] Each recurring family matched to a fix AT THE ACT (or an explicit decision not to)
- [ ] Rules home verified reachable; count derivable or ledger-reconstruction filed
- [ ] Cross-layer contradiction scan run; each hit fixed or precedence-claused
- [ ] Citation-decay pass run; every flagged rule disposed (retire/subsume/keep-with-reason)
- [ ] Short-term memory at target size; long-term guards green; index regenerated in order
- [ ] External imports graded with receipts; adopted ones ratified under subsume-or-don't
- [ ] Simplification tasks filed (not intended)
- [ ] Handover committed: hashes, regenerated owed list, own-misses, next trigger

## Kill criteria (this tool must obey its own rules)

- If **two consecutive reviews** produce zero disposals, zero contradictions, and
  zero adopted imports, the cadence lightens (the checklist runs, the deep steps
  sample) — a review that always finds nothing is ceremony.
- If review outputs go **unadopted** (ratified mechanisms uncited by the next
  review), prune the step that produced them — the same un-adopted-ceremony bar
  that pruned the effort-band candidate in the 1.2 pilot.
- n=1 caveat, stated per ADP's own promotion rule: this tool has run **once**.
  A second install running it and reporting what fired — especially what did
  NOT — is what graduates it. Open an install report either way.
