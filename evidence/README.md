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
| 121 miss-ledger entries, #7–#129 | the source install's ledger, counted by `adp_claims.py` |

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
- **The miss ledger is still prose**, so its counts vary slightly with the pattern used to read them. Converting it to a structured ledger is the next fix.
- **All of it is self-reported by the protocol's author.** The audit that settles any of it is an independent install, not this directory.

## If you run it on your own install

Open an [install report](../.github/ISSUE_TEMPLATE/install-report.md). Disconfirming results are graded and published on the same scorecard as the author's own claims — two of which have already been published as false.
