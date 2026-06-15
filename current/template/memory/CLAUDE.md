# Memory — read layer (ADP §10.3)

<!-- HARD CAP: 200 lines. This file survives /compact and is re-injected on
     every compaction — every line here is paid for repeatedly. Reference,
     never inline. The architect curates; prune on every retro. -->

## Pointers (keep ≤5 lines each)

- **Active plan:** docs/plans/<<<ACTIVE_PLAN>>>.md
- **Dispatch:** docs/tasks/current.md (wire mirror: .adp/dispatch.wire)
- **Context budget:** stop at ≤70% utilization (process.md §6)
- **Role prompts:** docs/prompts/ — referenced, not inlined

## Current Dispatch summary (≤5 lines, architect-maintained)

<<<DISPATCH_SUMMARY>>>

## Standing facts (per-fact detail lives in memory/*.md — write layer)

<!-- One line per fact, linking the write-layer file:
- Baseline test suite is non-deterministic re: dates → memory/test_baseline_drift.md
-->
