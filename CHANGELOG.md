# Changelog

All notable changes to the Agentic Development Protocol (ADP) are documented here.
This project versions the *standard*, not a software package.

## Versioning policy

ADP versions read `<spec-major>.<spec-minor>.<tooling-patch>`:

- **Spec major/minor** (e.g. `1.1`) — the standard itself: core patterns, roles,
  lifecycle, ratified rules in `PROTOCOL.md`. A new pattern or rule bumps the
  **minor** (1.1 → 1.2). The spec changes conservatively, earned through a
  documented miss.
- **Tooling patch** (the third digit, e.g. `1.1.2`) — the installer, scripts,
  template wiring, and docs. Fixes and new tooling features bump the **patch**
  and leave the spec version untouched.

Rule of thumb: if it changes `PROTOCOL.md`, it's a minor (1.2). If it changes the
installer/template/docs, it's a patch (1.1.x). Pure doc tweaks can ride along
without their own bump.

## [1.1.3] — 2026-06-17 (initialize helper + polish)

Patch release. **The 1.1 spec is unchanged.**

### Added
- **`docs/prompts/initialize.md`** — a shipped, one-time "first architect session"
  bootstrap. Pair it with `docs/prompts/architect.md` to write the first plan +
  Dispatch and propose ownership lanes. Previously this lived only in external docs.
- **Versioning policy** documented (see the "Versioning policy" section above):
  spec = `<major>.<minor>`, tooling = the third digit.

### Fixed
- Install artifacts (`*.adp-bak`, `*.adp-hooks`, `settings.json.pre-uninstall-*`)
  are now git-ignored so they can't be accidentally committed (Codex init.mjs retro).
- The `active` enforcement-status note now reminds you to reload/restart the session
  to *arm* hooks that were merged into a live `settings.json`.

[1.1.3]: https://github.com/kikenandez/agentic-development-protocol/releases/tag/v1.1.3

## [1.1.2] — 2026-06-17 (cross-platform installer)

Patch release. **The 1.1 spec is unchanged.** Driven by a Codex install/removal
retro that found the installer was bash-only (couldn't run on Windows without bash).

### Added
- **Cross-platform Node installer** — `scripts/init.mjs` + `scripts/uninstall.mjs`
  run with only `node` (no bash, no jq) — for Windows and other bash-less hosts.
  Native JSON merge; wires the Node hooks; full feature parity (generic /
  `--host=claude-code` / `--ci` / `--dry-run` / dirty-tree / manifest / status).
  `init.sh` remains the canonical Unix installer.
- **Index-size guard** — `generate_map.py` warns when an index exceeds ~25k tokens
  and suggests scoping it (excluding benchmark/generated dirs).

### Fixed
- **Reversible `.gitignore`** — `uninstall` now removes the ADP `.gitignore` block
  (round-trips to an identical file), and `--purge` is a true rollback (removes an
  ADP-created `settings.json` + backups). Un-wire works via `jq` **or** `node`.
- `uninstall.sh` no longer exits non-zero on a successful run.

[1.1.2]: https://github.com/kikenandez/agentic-development-protocol/releases/tag/v1.1.2

## [1.1.1] — 2026-06-17 (installer & tooling hardening)

Patch release. **The 1.1 spec is unchanged** — these are installer/tooling fixes,
derived from real install tests and retrospectives on Windows + Linux.

### Fixed
- **Silent-inert enforcement** — `init.sh` now *merges* the hooks into an existing
  `.claude/settings.json` (and appends missing `.gitignore` lines) instead of a
  silent `SKIP` that left the hooks on disk but never wired.
- **Generic install was not prose-only** — all `.claude/` enforcement infra (hooks,
  `settings.json`, `settings.node.json`) now ships only with `--host=claude-code`.
- **Over-confident output** — the installer now reports the *actual* enforcement
  status (active / inert-no-jq / not-wired / prose-only), not a generic checklist.

### Added
- `--dry-run` / `--plan` (preview, write nothing); `--yes` / non-TTY; `--ci` (CI
  workflow is now opt-in); prerequisite check (jq/bash/python3); a warning before
  installing onto a repo with uncommitted changes.
- `.agentic-protocol/INSTALL_MANIFEST` and `scripts/uninstall.sh` (safe / `--dry-run` / `--purge`).
- **Cross-platform Node hooks** (`.claude/hooks/*.mjs` + `settings.node.json`) that
  need neither `jq` nor `bash` — for Windows and jq-less hosts.
- **jq-less auto-wiring** — with `--host=claude-code` on a host that has Node but no
  `jq`, `init.sh` now wires the Node hooks automatically (merging into an existing
  `settings.json` via node, or switching a fresh one), so enforcement is live with
  no manual step. The enforcement-status report distinguishes bash vs Node wiring.
- `scripts/verify-hooks.sh` and `scripts/verify-hooks.mjs` — offline self-tests that
  prove the hook chain without a host restart.

### Changed
- `PROJECT_NAME` is set once in `memory/CLAUDE.md`; role prompts are now generic
  ("this repository").

[1.1.1]: https://github.com/kikenandez/agentic-development-protocol/releases/tag/v1.1.1

## [1.1] — 2026-06-15 (first public release)

First public release of ADP, distilled from a real multi-agent production system
(~80 deploy rounds, ~200 archived tasks, process-miss log past #65).

### Added (1.1 over the internal 1.0)
- **PDCA task lifecycle** with an evidence-based Check phase ("verified, not trusted").
- **Two living logs** — a numbered process-miss log and a positionally-numbered
  architecture-rules-ratified log — turning every miss into a citable rule.
- **n-counter rule-promotion threshold** so rules aren't adopted on a single anecdote.
- **Subsystem hotspot map** (§10.4) for the by-subsystem cross-cut the chronological archives miss.
- **Codebase-index AST skill** (`scripts/generate_map.py`) plus a four-archetype skill model with progressive disclosure.
- **Deploy ladder + waiver ledger** (§6.10) and the protocol retrospective outer loop (§6.11).
- **Optional Claude Code conveniences** — `.claude/hooks/`, `settings.json`, and an
  optional token-efficient `.adp/*.wire` format (~5.3× compression for agent-to-agent state).

### Repository
- Reorganized into `current/` (ratified 1.1) and `improvements/` (1.2 candidates).
- Dual licensing: documentation/spec under **CC BY 4.0**, code/scripts/templates under **MIT**.

### Honest scope
Validation is still small-n: one production system and one public LLM benchmark.
The protocol marks what it has falsified and grades its own claims. See
`improvements/` for the audits.

[1.1]: https://github.com/kikenandez/agentic-development-protocol/releases/tag/v1.1
