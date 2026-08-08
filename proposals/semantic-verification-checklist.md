# The semantic verification checklist (six classes)

**Status:** CANDIDATE — n=2 by install for the PLAN-side pillar, not yet ratified into
`PROTOCOL.md`. Published standalone so any team can run it today and report results.
**Companion:** `proposals/ADP-1.2-candidates.md` (candidate #5 and the n=2 section).
**The fastest single test of ADP** (per the preprint, §8): apply this checklist to the
next ten task specifications your team writes and count the catches. If it catches
nothing on your stack, that is exactly the result we want reported — open an
install report (see `.github/ISSUE_TEMPLATE/install-report.md`).

---

## The problem it closes

Referential verification asks: *does the symbol exist?* The failures this checklist
targets pass that check and fail anyway, because the question that matters is:
**is the symbol what the spec assumes?** A spec whose identifiers are all real can
still be wrong about what they mean — and the implementer then builds correctly
against a false premise. Across two independent installs on opposite stacks
(an LLM web system and a deterministic embedded C++ system), this was the dominant
recurring failure mode, and it was not bad code.

## When it runs (the scope gate)

At **spec-author time**, before the spec ships — by the person or session writing the
spec, not the implementer. It fires **only** when the spec cites existing
dispatchers, constants, wire formats, data structures, or function signatures as
load-bearing primitives. Pure-additive work (new files, docs, logs, tests that
touch nothing existing) is exempt. The scope gate is what keeps the cost bounded:
the checklist runs on primitives the change actually touches, not on everything
the spec mentions. Measured cost in the source install: ~2–5 minutes per spec;
measured cost of skipping: 5–30 minute implementer reframe loops and occasional
wrong-direction implementation.

## The six classes

For **each named primitive within the change's scope**, check against repository
ground truth (open the file; do not trust memory, a prior audit doc, or a filtered
search tool):

| # | Class | The check | Real failure it names |
|---|---|---|---|
| S1 | **Wrong value** | The constant's VALUE is read, not assumed from its declared type or name. | Right constant name, different value than the spec assumes — callsites silently broken. |
| S2 | **Wrong operator** | The dispatcher/comparison OPERATOR is read (`==` vs `>=`, and/or vs precedence). | A frame routed through a `>=` size-ladder the spec modeled as exact-match. |
| S3 | **Wrong mirror count** | Every PARALLEL SITE of the structure/decoder/map is enumerated by grep, not recalled. | A change assumed to land in one place actually has parallel sites; tests go green against a mirror production never runs. |
| S4 | **Wrong argument rule** | Units, ordering, defaults and nullability are read from the signature and the language's rules. | A defaulted argument placed where the language forbids it — non-compilable as written. |
| S5 | **Wrong signature** | The prose claim and the actual signature are compared side by side. | Prose says "fills id"; the function has no `id` parameter — the implementer guesses authority. |
| S6 | **Wrong cardinality** | Any count derived from a FILTERED search is re-derived unfiltered. | A content-filtered grep returned 6 of 11; the spec then instructed deleting real history. |

**Verdict per primitive:** cite `file:line` evidence in the spec, or tag the claim
`⚠️ HYPOTHESIS` so the implementer verifies it first. A spec may ship with
hypotheses; it may not ship with unmarked ones.

## The companion form: the VERIFY field (candidate, n=1 by install)

The checklist verifies a spec's *primitives*; the VERIFY field pre-registers its
*premises*. The spec names the **single** premise the author is least certain of —
selection heuristic, with receipts: *which claim makes the problem look simplest?*
The implementer checks that premise **first** and reports CONFIRMED or FALSIFIED;
a falsified VERIFY is a gate **success**, not a complaint. `— none (no existing
primitive cited)` is a legal value; an empty field is not. One pillar, two forms —
if you adopt both, count them once in your ledger.

## Reporting

Log every catch as a numbered miss with the class (S1–S6), whether it was CAUGHT
(falsified before code) or ESCAPED (reached code or later), and what it would have
cost uncaught. Ten specs, zero catches is a publishable result; so is ten specs,
four catches. Both go in an install report.
