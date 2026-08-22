# Source-control analysis — the source install

**Run 2026-08-19 · HEAD `1f79af15` · `current/scripts/adp_history.py` + ad-hoc queries**

The product repository, measured from git. Generated artifacts excluded throughout — dependency trees, build output, debug dumps, recorded test output, replay fixtures, and `get-pip.py`. Read the exclusion list in the script before quoting any figure here.

---

## 1. Scale

| | |
|---|---|
| Commits (all refs, merges excluded) | **3,618** |
| Period | 2026-02-02 → 2026-08-19 (**6.5 months**) |
| Human authors | 1 |
| Files tracked at HEAD | **1,958** |
| Lines at HEAD | **484,094** |
| Lines added over all history | 635,833 |
| Lines deleted over all history | 140,499 |
| Files ever created / ever deleted | 2,357 / 388 |

Roughly **18 commits per day**, every day, for six and a half months, from one person.

---

## 2. The standing corpus is almost exactly thirds

| Category | Files | Lines at HEAD | Share |
|---|---|---|---|
| **Tests** | 741 | 159,517 | **33.0%** |
| **Production code** | 366 | 152,361 | **31.5%** |
| **Documentation** | 598 | 151,994 | **31.4%** |
| Other | 201 | 10,506 | 2.2% |
| Config | 52 | 9,716 | 2.0% |

**At rest, the repository is one third tests, one third code, one third documentation.** That is a cleaner and more defensible statement than the lines-added ratio, and it is trivially reproducible by anyone who clones it.

### Standing corpus vs flow — and why they differ

| | At HEAD (standing) | Lines added (flow) |
|---|---|---|
| Tests | 33.0% | 26.5% |
| Code | 31.5% | 38.6% |
| Docs | 31.4% | 34.9% |

Code is a larger share of what was *written* than of what *remains*: it is rewritten more than the other two. Documentation and tests accumulate; code churns. Both views are true and they answer different questions — "where did the effort go" is the flow; "what is this repository made of" is the standing corpus. Quote whichever you mean, and say which.

**Top extensions by file count:** `.py` 748 · `.md` 580 · `.js` 234 · `.jsx` 69 · `.json` 45 · `.yaml` 27.

---

## 3. The 25,000-line file was real — and understated

The article says the codebase had "files past 25,000 lines." Measured:

| Lines | File |
|---|---|
| **29,654** | `<largest source module>` |
| 8,768 | `<largest UI component>` |
| 6,524 | `docs/tasks/results/developer.md` |
| 5,236 | `<validation module>` |
| 5,010 | `<service entrypoint>` |

`intake.py` is nearly 30,000 lines and has taken **419 commits and 44,108 lines of churn**. The claim in the article is safe; if anything it undersells the problem.

---

## 4. 🔑 The most-churned file in the product is not code

| Lines churned | Commits | File |
|---|---|---|
| **112,442** | **1,857** | `docs/tasks/current.md` |
| 44,108 | 419 | `<largest source module>` |
| 19,830 | 123 | `<service entrypoint>` |
| 19,792 | 213 | `<largest UI component>` |
| 7,500 | 110 | `<validation module>` |

`current.md` — the protocol's coordination and dispatch file — is touched in **1,857 of 3,618 commits: 51% of everything.** It carries 2.5× the churn of the largest source file in the product.

This is the strongest single piece of evidence in this analysis. The claim that in agentic development the durable artifact is the specification rather than the code is usually an assertion. Here it is a measurement: **the busiest file in a 484,000-line product is the one where the work is planned, dispatched and ruled on.** Nobody designed it that way; it is what the history recorded.

### Coordination load by month

| Month | Commits touching `current.md` |
|---|---|
| 2026-04 | 270 |
| 2026-05 | 377 |
| 2026-06 | 586 |
| **2026-07** | **60** |
| 2026-08 | 563 |

July again — the month the protocol was reviewed and extracted rather than exercised. Product commits fell to 96 and coordination fell with them. The process work displaced the product work; that is a real cost and it is visible.

---

## 5. Process discipline, measured

| | |
|---|---|
| Commits whose message carries a task ID (`T###`) | **2,927 of 3,624 — 80.8%** |
| Commits carrying a `Functional-change:` trailer | 1,284 — 35.4% |
| Delete-to-add ratio | **0.22** (140,499 deleted / 635,833 added) |
| Files deleted / created | 388 / 2,357 — 16% |

**80.8% task-ID coverage** is the number to be proud of. It means four commits in five are traceable to a numbered, specified unit of work with an archived verdict — and it is what makes every other count in this project derivable at all. Convention adherence is the instrumentation.

The `Functional-change:` trailer at 35.4% is the counter-example: introduced as a convention, adopted by a third of commits, never enforced. A convention that is not mechanically checked decays, and here is the decay rate.

**One line deleted for every 4.5 added.** For a repository built almost entirely by generation, that is meaningful pruning rather than pure accretion.

---

## 6. Cadence

| Month | Commits | |
|---|---|---|
| 2026-02 | 32 | start |
| 2026-03 | 176 | |
| 2026-04 | 701 | |
| 2026-05 | 518 | |
| 2026-06 | 868 | |
| **2026-07** | **96** | protocol review + extraction |
| 2026-08 | 1,227 | highest |

---

## 7. 🔴 The published commit count does not reconcile

The paper states **1,768 commits**. No definition of this repository's history produces it:

| Definition | Count |
|---|---|
| HEAD, all commits | 3,627 |
| HEAD, merges excluded | 3,617 |
| All refs, merges excluded | **3,618** |
| Before 2026-08-09 | 2,794 |
| Before 2026-07-01 | 2,294 |
| Before 2026-06-20 | 2,066 |
| Before 2026-06-01 | 1,426 |
| Carrying a `Functional-change:` trailer | 1,284 |

1,768 falls between the 1 June and 20 June cuts and matches no clean rule.

**Decision taken 2026-08-19: the published paper stands.** Its figures supported a perception held at the time and were labelled as self-reported. This is recorded so the next publication uses **3,618 at `1f79af15`**, derived by script, rather than carrying the number forward.

---

## 8. Method and limits

`git log --all --no-merges --numstat`. **Lines added** is a proxy for effort and an imperfect one: it rewards verbosity, ignores deletion, review and thought, and says nothing about quality.

Excluding generated artifacts materially changes the answer. Three debug JSON dumps alone carried 144,000 lines; recorded test output added roughly 130,000 more. Counting them would have shown tests at 32.5% and code at 26.1% — a flattering result and a false one.

Classification is by path and extension, tests before docs before code. `<exported marketing assets>` contains exported marketing HTML classified as docs; it is a few thousand lines and does not move the thirds.

Counts move as the repository moves. **Quote the commit, not the date.**
