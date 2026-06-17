# Agentic Development Protocol (ADP)

**An open standard for shipping production software with AI agent teams — verified, not trusted.**

ADP is a plug-and-play protocol for running multi-agent AI development teams in
parallel without commits colliding, scope drifting, or sessions losing track of
what they were doing. It is stack-agnostic and AI-host-agnostic, with optional
Claude Code-native conveniences. It installs into **any** repository.

It is distilled from a real, shipped production system that ran a multi-agent team
— architect, developer, designer, business, comms — in parallel for ~80 deploy
rounds and ~200 archived tasks, with a process-miss log past #65. Every rule earned
its place through a documented miss. The protocol grades its own claims honestly:
what production validated, what it discarded, and why.

## Repository layout

| Path | What it is |
|------|-----------|
| [`current/`](./current/) | The ratified **ADP 1.1** bundle (tooling **1.1.1**) — spec, scripts, and the template ADP installs into your repo. **Start here.** |
| [`current/PROTOCOL.md`](./current/PROTOCOL.md) | The canonical specification. Read this first. |
| [`current/template/`](./current/template/) | The files ADP installs into a target repository. |

## Prerequisites

- **git** and **bash** — required.
- **python3** — for `scripts/generate_map.py` and `scripts/adp_metrics.py`.
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
repository.

> The names "ADP" and "Agentic Development Protocol" name the standard. The licenses
> above grant copyright permissions, not trademark rights. You may always state that
> your work implements or is based on ADP.
