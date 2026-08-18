# Agentic Development Protocol (ADP)

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21982389.svg)](https://doi.org/10.5281/zenodo.21982389)
[![Code: MIT](https://img.shields.io/badge/code-MIT-blue.svg)](./LICENSE-CODE-MIT.txt)
[![Docs: CC BY 4.0](https://img.shields.io/badge/docs-CC%20BY%204.0-lightgrey.svg)](./LICENSE-DOCS-CC-BY-4.0.txt)

**An open standard for shipping production software with AI agent teams — verified, not trusted.**

ADP is a plug-and-play protocol for running multi-agent AI development teams in
parallel without commits colliding, scope drifting, or sessions losing track of
what they were doing. It is stack-agnostic and AI-host-agnostic, with optional
Claude Code-native conveniences. It installs into **any** repository.

It is distilled from a real, shipped production system that ran a multi-agent team
— architect, developer, designer, business, comms — in parallel for ~80 deploy
rounds and 226 archived tasks, with a numbered process-miss log of 121 entries.
Every rule earned its place through a documented miss. The protocol grades its own
claims honestly: what production validated, what it discarded, and why —
**249 claims accepted, 43 falsified and published as falsified**, counted by a
re-runnable script against a pinned commit.

## Repository layout

| Path | What it is |
|------|-----------|
| [`current/`](./current/) | The ratified **ADP 1.1** bundle (tooling **1.1.5**) — spec, scripts, and the template ADP installs into your repo. **Start here.** |
| [`current/PROTOCOL.md`](./current/PROTOCOL.md) | The canonical specification. Read this first. |
| [`current/template/`](./current/template/) | The files ADP installs into a target repository. |
| [`MEASUREMENT.md`](./MEASUREMENT.md) | How every number ADP publishes about itself is counted. |
| [`paper/`](./paper/) | The preprint and the published claim receipts (855 rows). |

## Prerequisites

- **git** and **bash** — required.
- **python3** — for `scripts/generate_map.py`, `scripts/adp_metrics.py` and
  `scripts/adp_claims.py`. Stdlib only; no packages to install.
- **jq** — required by the default (bash) hooks; without it they silently no-op.
  (`brew install jq` · `apt install jq` · Windows `winget install jqlang.jq`)
- **node** — only if you use the cross-platform **Node hooks** (`.mjs`), which need
  neither jq nor bash. Recommended on Windows.

## Quick start

```bash
git clone https://github.com/kikenandez/agentic-development-protocol.git
cd agentic-development-protocol/current

# Recommended: install on a branch so you can review before merging.
cd /path/to/your/repo && git checkout -b adopt-adp && cd -

./scripts/init.sh --dry-run /path/to/your/repo          # preview — writes nothing
./scripts/init.sh --host=claude-code /path/to/your/repo # install with enforcement
#   omit --host=claude-code for a prose-only install; add --ci for the CI workflow
```

**Windows, or any host without bash?** Use the cross-platform Node installer — same
flags, needs only `node` (no bash, no jq):

```bash
node ./scripts/init.mjs --host=claude-code /path/to/your/repo
node ./scripts/uninstall.mjs --purge /path/to/your/repo   # full rollback
```

The installer is non-destructive (no-clobber + merge), writes an
`INSTALL_MANIFEST`, reports the actual enforcement status when it finishes, and
ships an `uninstall.sh`. Then read
`current/template/.agentic-protocol/GETTING_STARTED.md`, set the project name in
`memory/CLAUDE.md`, fill the `<<<PLACEHOLDERS>>>` in `docs/prompts/*.md`
(~5 minutes), and start your first architect session by pasting
`docs/prompts/architect.md` into your AI host.

The full walkthrough — the five core patterns, adoption levels (L1–L4), and the
comparison to BMAD / ChatDev / Cursor rules / Anthropic's harness — is in
[`current/README.md`](./current/README.md).

## How proven is it?

Honestly: n is small. One production system and one public LLM benchmark. The
protocol marks what it has falsified and uses an n-counter so rules aren't adopted
on a single anecdote. Read the spec and the commit history before trusting a word
of it — that transparency is the point.

Two limits worth stating before you install anything. The evidence above comes
from a **full (L3–L4) install**; a prose-only **L1** install produces almost no
machine-readable receipts, so the numbers are adoption-level-bound, not universal.
And every count to date is self-reported by the protocol's author — the audit that
settles them is your install, not this repository.

The full argument, the evidence and the limits are in the preprint:
**[The Agentic Development Protocol](https://doi.org/10.5281/zenodo.21982389)**
(v0.5, August 2026). Its §5 publishes the metrics snapshot *with its instrument
defects intact*, and the claim receipts — 855 rows, each with the file and line
the verdict was recorded at — ship in this repository so any number here can be
disputed row by row.

How every published number is counted — units, the claim-acceptance procedure,
the recurrence and escape-classification rules, what does and does not count as a
false accept — is specified in [`MEASUREMENT.md`](./MEASUREMENT.md), and executed
by [`current/scripts/adp_claims.py`](./current/scripts/adp_claims.py). Run it
against your own install; it prints the count as a range with its blind spots
listed. The fastest
single test of the protocol is the
[six-class semantic checklist](./proposals/semantic-verification-checklist.md):
run it against your team's next ten specs and
[report what it caught](./.github/ISSUE_TEMPLATE/install-report.md) — zero catches
is a result we want published too.

## Roadmap

**Spec 1.1 is the current stable standard** (tooling 1.1.5). A set of **1.2 candidate
deltas** is in pilot — one cut a production system's live context ~85%, one was
pruned for being unadopted ceremony. Per ADP's own rule, none graduate into the spec
until a *second* project reproduces them (n=2). See [`ROADMAP.md`](./ROADMAP.md) and
[`proposals/ADP-1.2-candidates.md`](./proposals/ADP-1.2-candidates.md).

## Citing ADP

If ADP is useful to you, cite the preprint:

> Blanco, G. (2026). *The Agentic Development Protocol: A Self-Falsifying Process
> Standard for Shipping Production Software with AI Agent Teams* (v0.5) [Preprint].
> Zenodo. https://doi.org/10.5281/zenodo.21982389

```bibtex
@misc{blanco2026adp,
  author    = {Blanco, Guillermo},
  title     = {The Agentic Development Protocol: A Self-Falsifying Process
               Standard for Shipping Production Software with {AI} Agent Teams},
  year      = {2026},
  month     = aug,
  publisher = {Zenodo},
  version   = {0.5},
  doi       = {10.5281/zenodo.21982389},
  url       = {https://doi.org/10.5281/zenodo.21982389},
  note      = {Preprint}
}
```

Machine-readable metadata is in [`CITATION.cff`](./CITATION.cff); GitHub's
**Cite this repository** button reads it directly.

## License

ADP is open and **dual-licensed**:

- **Documentation & specification → [CC BY 4.0](./LICENSE-DOCS-CC-BY-4.0.txt)** (attribution required)
- **Code, scripts & templates → [MIT](./LICENSE-CODE-MIT.txt)**

See [`LICENSE`](./LICENSE) for the exact file scope and the attribution string.
You may use ADP commercially; just credit the spec.

## Author & contact

Created and maintained by **Guillermo Blanco** — 25 years of project management
paired with hands-on agentic production.

Questions, issues, and proposals: please open a GitHub Issue or Discussion on this
repository. **Install reports are the contribution that matters most** — whether
ADP helped, did nothing, or got in the way. Disconfirming reports are as welcome
as confirming ones and are published either way; that is what the protocol is for.

> The names "ADP" and "Agentic Development Protocol" name the standard. The licenses
> above grant copyright permissions, not trademark rights. You may always state that
> your work implements or is based on ADP.
