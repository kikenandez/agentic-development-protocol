# Memory — read layer (ADP §10.3)

<!-- HARD CAP: 200 lines. This file survives /compact and is re-injected on
     every compaction — every line here is paid for repeatedly. Reference,
     never inline. The architect curates; prune on every retro. -->

## Project (identity — every role reads this on startup)

<<<PROJECT_NAME>>> — one-line description of what this repository is.

## Pointers (keep ≤5 lines each)

- **Active plan:** docs/plans/{{RUNTIME:ACTIVE_PLAN}}.md
- **Dispatch:** docs/tasks/current.md (wire mirror: .adp/dispatch.wire)
- **Context budget:** stop at ≤70% utilization (process.md §6)
- **Role prompts:** docs/prompts/ — referenced, not inlined

## Current Dispatch summary (≤5 lines, architect-maintained)

{{RUNTIME:DISPATCH_SUMMARY}}

<!-- {{RUNTIME:...}} markers are filled by the architect AT RUNTIME, not at install.
     They are intentionally NOT `<<<...>>>`, so `grep -r '<<<'` only flags the
     install-time placeholders you must fill before first use. -->>

## Standing facts (per-fact detail lives in memory/*.md — write layer)

<!-- One line per fact, linking the write-layer file:
- Baseline test suite is non-deterministic re: dates → memory/test_baseline_drift.md
-->
