# Evidence

Published so the numbers in the protocol and the paper can be audited rather than believed.

Everything here is derived by scripts in [`current/scripts/`](../current/scripts/) and pinned to a specific commit of the install it was run against. Re-run them against your own install and you get the same shape of output — that is the point.

> **Why this directory exists separately.** Per-project working notes, drafts and fit analyses stay unpublished (`paper/` is ignored). But the receipts are what an auditor needs, and a claim that evidence is public has to be true. This is that evidence.

## What has been redacted, and why

Each receipt row originally carried the **text of the line** the verdict was recorded on. That column has been removed.

The reason is that it bought nothing. The source install is a private repository, so no third party can resolve a `file:line` reference against it regardless of what is published here. The excerpts therefore added no verifiability while quoting internal module names, source-file line numbers and architectural detail from a commercial product.

**What remains is everything the counts rest on:** the verdict class, the task, the archive file and line where it was recorded, and the date. The distribution, the totals and the traceability are intact and independently checkable against the totals the scripts print.

Full excerpts can be provided to a reviewer or editor on request, under the usual terms for restricted supplementary data.

---

## Contents

| File | What it is |
|---|---|
| `claim_receipts_webapp_2026-08-17.csv` | **855 rows.** Every terminal verdict on a claim counted by `adp_claims.py`: its verdict class, the task it belongs to, and the archive file, line and date it was recorded at. The backing data for **249 accepted / 43 falsified** |
| `claim_receipts_webapp_2026-08-17.md` | The same receipts as a readable table, grouped by verdict class |
| `claim_receipts_embedded_cpp_2026-08-17.md` | The cross-install run. Near-empty by design — see below |
| `history_analysis_webapp_2026-08-19.md` | Source-control analysis: corpus composition, churn distribution, commit cadence, convention adherence |

## The runs these came from

| | Source install | Cross-install |
|---|---|---|
| Stack | LLM-backed web application (Python / JavaScript) | Deterministic embedded C++ |
| Chosen because | where the protocol was developed | deliberately opposite on every axis that could matter |
| Pinned commit | `d006a752` (claims) · `1f79af15` (history) | `37e1ef6` |
| Date | 2026-08-17 / 2026-08-19 | 2026-08-17 |
| Adoption level | full install with enforcement | **L1, prose-only** |

## Headline figures, and where each comes from

| Figure | Source |
|---|---|
| 249 accepted / 43 falsified claims | `adp_claims.py`, lower bound (distinct claim units); mentions upper bound is 422 / 61 |
| 855 receipt rows | the CSV in this directory |
| 3,618 non-merge commits over 6.5 months | `adp_history.py` at `1f79af15` |
| 64.4% of the standing corpus is tests or documentation | `adp_history.py` — 33.0% tests, 31.4% docs, 31.5% code |
| Coordination file touched in 51% of commits | `adp_history.py` churn analysis — 1,857 of 3,618 |
| 80.8% task-ID coverage vs 35.4% for an unenforced convention | `adp_history.py` |
| **159 miss-ledger entries, #7–#170** | the source install's ledger, parsed by `adp_ledger_migrate.py` (see the correction below) |
| Misses per month: May 42 · Jun 13 · Jul 5 · Aug 87 | same, from the 147 entries carrying a date |
| Escape classification present on 34 of 159 (21%) | same — the convention was ratified 2026-08-07 and was never backfilled |

## Reproducing this

```bash
python3 current/scripts/adp_claims.py  /path/to/your/install --table receipts.md --csv receipts.csv
python3 current/scripts/adp_history.py /path/to/your/install
```

Both are stdlib-only. Both print their own blind spots. Neither is tuned to reproduce a previously published figure — when the counts disagreed with what had been published, the published numbers were corrected, twice.

## Read these limits before quoting anything here

- **Lines added is a proxy for effort.** It rewards verbosity and ignores deletion, review and thought. It is used because git records it without extra bookkeeping, not because it is the right measure.
- **Generated artifacts are excluded and this materially changes the answer.** Before exclusion, three debug JSON dumps carried 144,000 lines and recorded test output ~130,000 more; counting them would have shown tests at 32.5% and code at 26.1% — a flattering result and a false one. The exclusion list is in the script.
- **Claim counts are a range, not a point.** Distinct claim units (lower bound) under-count because one task can falsify several claims; mentions (upper bound) over-count because task files restate their own verdicts. The lower bound is cited throughout.
- **The cross-install run returns almost nothing, and that is a finding.** At L1 the protocol produces very few machine-readable receipts, so this evidence is adoption-level-bound rather than universal.
- **Two of the four metrics in `adp_metrics.py` currently report false zeros** — the parsers look for conventions this install does not write. Published rather than repaired, because a reader finding it unaided would be entitled to a harsher reading.
- **The miss-ledger count was wrong, and has been corrected — see below.**
- **All of it is self-reported by the protocol's author.** The audit that settles any of it is an independent install, not this directory.

## Correction — the miss-ledger count (2026-08-22)

Earlier material, including the preprint, states **121 entries, #7–#129**. The correct figure is **159 entries, #7–#170**, with five gaps in the numbering (#65, #101–#103, #105) and one duplicate opener at #38.

The cause is the same one this project keeps finding. The ledger was written over six months and accumulated **four** entry formats — the date and session moved in and out of the bold, the punctuation between them changed. Every count anyone had taken was a count of one format or another, and the answer moved with the pattern: 66, 121, 136, 159.

The migration tool got it wrong too, twice, before it got it right. Its first version knew two of the four formats and reported 66 — silently, with no error. An independent line count disagreed, which is the only reason anyone looked. That is now recorded in the script's own header.

**`adp_ledger_migrate.py` now agrees with an independent count of the same file, exactly.** That agreement, not the number, is what makes 159 quotable.

### What this changed

Structuring the ledger produced things prose could not:

| | |
|---|---|
| Misses per month | May 42 · Jun 13 · Jul 5 · **Aug 87** |
| Escape classification coverage | 34 of 159 (21%) — **all of them August** |
| August adherence to a convention ratified 2026-08-07 | 34 of 87 ≈ **39%** |

That last row is the interesting one. An unenforced convention in the same repository — the `Functional-change:` commit trailer — sits at **35.4%**. A convention the workflow actually depends on, the task ID, sits at **80.8%**. Two conventions introduced without mechanical enforcement, in different artefacts, months apart, both landing near 35–39%.

That is not a controlled experiment and should not be reported as one. But it is a second, independent instance of the finding the miss ledger produced by hand: **a rule that depends on someone remembering it decays to roughly a third.**

### Why `misses.yml` is not published here

The structured ledger holds 159 miss summaries from a private commercial repository. Publishing it would expose the same product internals that were redacted from the receipts, for the same absence of audit value. The aggregates above are published instead, and `adp_ledger_migrate.py` ships with the protocol so any install can produce its own.

## If you run it on your own install

Open an [install report](../.github/ISSUE_TEMPLATE/install-report.md). Disconfirming results are graded and published on the same scorecard as the author's own claims — two of which have already been published as false.
