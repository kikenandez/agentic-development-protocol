# Agentic Development Protocol (ADP) 1.1

A plug-and-play protocol for running multi-agent AI development teams in parallel without commits colliding, scope drifting, or sessions losing track of what they were doing. Stack-agnostic, AI-host-agnostic, with optional Claude Code-native conveniences.

Distilled from a real, shipped production system that has run multi-agent (architect + developer + designer + business + comms) in parallel for ~80 deploy rounds, ~200 archived tasks, and a process-miss log currently past #65 — every rule earned its place through documented misses.

**What ADP 1.1 codifies, beyond the five core patterns:** PDCA Check discipline ("verified, not trusted") as the closing pillar; a two-living-logs Act phase that turns every miss into a numbered rule; an n-counter rule-promotion threshold so rules don't get adopted on a single anecdote; a subsystem hotspot map for the by-subsystem cross-cut the chronological archives don't give you; the codebase-index AST skill pattern; a four-archetype skill model with progressive disclosure; a deploy ladder with waiver ledger; and an *optional* token-efficient wire format for agent-to-agent state. Everything is graded honestly — what production validated, what production discarded, and why.

---

## What's in this bundle

This is the **ratified 1.1** bundle. Candidate 1.2 material (audits and draft
module specs) is maintained separately and folded in as it reaches ratification.

```
current/
├── PROTOCOL.md            # The canonical ADP 1.1 spec — read this first
├── README.md              # You are here
├── scripts/
│   ├── init.sh            # Installer into a target repo
│   ├── wire-sync.sh       # prose Dispatch → wire format converter (optional)
│   ├── adp_metrics.py     # protocol metrics snapshot
│   └── generate_map.py    # codebase-index AST skeleton generator
└── template/              # The files ADP installs into your repo
    ├── docs/
    │   ├── prompts/       # Host-agnostic role prompts + process.md
    │   │   ├── architect.md
    │   │   ├── developer.md
    │   │   ├── designer.md
    │   │   ├── reviewer.md   # optional
    │   │   ├── analyst.md    # optional (greenfield only)
    │   │   └── process.md    # Shared process — single source of truth
    │   ├── tasks/
    │   │   ├── current.md    # Living: Dispatch + tasks + the two living logs
    │   │   └── archive/
    │   ├── plans/
    │   │   ├── _template.md
    │   │   └── archive/
    │   └── skills/_README.md # Four scoped knowledge bundles per archetype
    ├── .claude/               # Optional Claude Code convenience layer
    │   ├── hooks/             # git-hygiene.sh (battle-tested in production)
    │   └── settings.json      # PreToolUse / PostToolUse wiring
    ├── .adp/                  # Optional wire format (see caveat below)
    │   ├── README.wire        # Syntax key
    │   ├── proc.wire / roles.wire / dispatch.wire / tasks.wire
    │   ├── results.jsonl      # Append-only event log
    │   └── status             # One-liner heartbeat per role
    ├── .agentic-protocol/
    │   ├── VERSION
    │   └── GETTING_STARTED.md
    └── .gitignore
```

---

## Quick start

```bash
./scripts/init.sh /path/to/your/repo
```

Or manual: `cp -r template/. /path/to/your/repo/`.

Next: read `.agentic-protocol/GETTING_STARTED.md` and fill the `<<<PLACEHOLDERS>>>` in `docs/prompts/*.md` (≈5 minutes). Then start your first architect session by pasting `docs/prompts/architect.md` into your AI host.

---

## The five-role cast — what production proved

The proven cast is **architect / developer / designer / business / comms** — *not* architect / dev / designer / reviewer / analyst as earlier drafts suggested.

Two reasons the source production diverged:

1. **PDCA Check at the architect makes a standalone reviewer redundant.** The "verified, not trusted" gate is the architect's closing phase on every task. A separate Haiku-tier reviewer adds a handoff without adding a check.
2. **Ideation flows through real demo signal in the business role**, continuously, rather than through a one-shot analyst at kickoff.

**Reviewer and analyst remain documented as optional variants.** Keep them only if your architect genuinely can't carry the Check phase, or you have a true greenfield bootstrap.

---

## The five core patterns (the floor)

These survive every successful round:

1. **Stable role prompts, dynamic dispatch.** Role prompts never change per round; Dispatch block in `current.md` tells each session what to do today.
2. **Single source of truth for "what's next."** Dispatch is architect-maintained. 3-5 tasks per session, what NOT to start, context budget, standing reminders.
3. **File ownership lanes.** Each role owns non-overlapping paths. Cross-lane work requires a handoff task.
4. **Parallel-session commit hygiene.** Five hard rules: exact-path staging; `git status --short` before commit; verify "committed" with `git branch --contains`; no hard reset without stash; hook failures → new commit, not `--amend`.
5. **Session lifecycle with a hard cap.** Stop at ≤70% context utilization. Hand off via Dispatch, not chat. Terse wrap-up.

The rest of the protocol — including the load-bearing additions below — is consequences of these five.

---

## What 1.1 adds on top of the five

The substantive additions that turn ADP from a rule list into a learning system:

1. **PLAN → DO → CHECK → ACT (PDCA) as the task lifecycle.** The familiar five mechanical steps (plan → progress → test → document → commit) live *inside* DO. CHECK re-verifies against evidence rather than trusting the implementer's summary, with the literal heading `🔎 ARCHITECT ACCEPT (PDCA — verified, not trusted)` followed by numbered evidence items. ACT writes every miss back into two living logs.
2. **The two living logs.** A numbered **process-miss log** (chronological — the source production is past #65) and a positionally-numbered **architecture-rules-ratified log** (rules become citable: "per the 32nd rule"). Both live at the top of `current.md`, always in context. ACT made concrete.
3. **The n-counter rule-promotion threshold.** Rules don't get adopted on a single anecdote. Candidate at n=1, ratified at n=2 (low-risk patterns), promoted to template at n=4-5 (high-risk / high-friction). Naming a candidate at n=1 makes the threshold visible.
4. **Architect's two hard rules.** *"Verify existing primitives before the spec lands"* (every named function / endpoint / file:line grep-confirmed before paste; `⚠️ HYPOTHESIS` tag for unverified) and *"spec the symptom, not the root"* (for multi-site subsystems the architect's hypothesized root is repeatedly wrong; let Gate-1 determine it).
5. **Baseline-per-session test discipline.** The pre-existing-failure count is not a memorized number — it drifts. Stash → run → record → un-stash → re-run. Zero NEW failures vs the freshly-measured baseline is the bar.
6. **Subsystem hotspot map (§10.4 — net new).** The archive index is chronological-by-task; it answers "what did T-N do?" but not "if I touch subsystem X, what *else* does it touch?" A single curated map cross-cuts: one row per fragile/multi-site subsystem → all touch-points + the canonical fix seam + tasks where detail lives. Default-deny read (one line in the always-loaded layer; you open the table only before touching a listed subsystem). **Function-name anchors, not line numbers.** Earns a row at n=2.
7. **Deploy ladder + waiver ledger (§6.10).** Four gates: ≤1 deploy / 24h hard, local verification as the default gate, bundling discipline, pre-deploy parity check. Every supported entry path must reach the "done" event in pre-deploy verification. Waivers tracked in a running ledger.
8. **Codebase-index skill + four archetypes.** The AST skeleton skill (`scripts/generate_map.py`) is the highest-leverage single addition. The four archetype model (index, operational quick-ref, contract enforcement, design principles) covers what skills are actually used for.
9. **The protocol retrospective — the lessons-learned sanity check (§6.11, side process).** Every 2 weeks (max 4), the architect and the human step back to review the protocol *itself*: process-miss log delta, rules log delta (including rules to retire, not just promote), hotspot map updates, skill usage, dispatch hygiene, deploy waivers, roadblocks no rule has yet named. Outputs are mandatory — a protocol change committed, a dated retro archive entry, dispatch action items — even if the verdict is "no change needed." Per-task ACT (§6.1) is the inner loop; the retro is the outer loop. The retro is what keeps the protocol from over-fitting to recent misses or drifting into a rule graveyard.

Full rationale, citations, and the applied/discarded log are maintained in the
project's audit notes (folded into PROTOCOL.md as each item reaches ratification).

---

## Adoption levels — honest grading

ADP scales from "just markdown" to "Claude Code-native conveniences." Pick your level based on what production actually validated:

| Level | What you get | Effort | Production verdict |
|---|---|---|---|
| **L1 — Prose only (default)** | Role prompts + Dispatch + commit hygiene by discipline. Works on any host. | Install + fill placeholders (~15 min). | **Validated.** This is the floor. Most teams run here forever and ship cleanly. |
| **L2 — `.claude/hooks/` for commit hygiene** | Add the git-hygiene hook + `.claude/settings.json` (deny bulk-add, surface staged set on `git commit`, ask on destructive git). | ~10 min — the hook is in `template/.claude/`. | **Validated in production** (closes process-miss #65 directly). Highest-leverage L1→L2 step. |
| **L3 — `.claude/agents/*.md` wrapping** | Frontmatter-wrapped role prompts for Claude Code auto-discovery. | ~5 min per role. | **Convenience only, NOT enforcement.** Production evaluated and chose not to rely on it: (a) gitignored by default so it's not version-controlled, (b) subagent ≠ main interactive persona, (c) `tools:` is tool-type scoping, not path scoping — it cannot enforce the code/docs lane. Use if your team likes the `/agent <name>` invocation; do not expect it to enforce the protocol. |
| **L4 — Wire format (optional)** | Compact `.adp/*.wire` files for repeated session-to-session reads. Measured ~3-5× compression on protocol overhead. | Run `init.sh --wire-first`. | **Conditional.** For a discipline-strong team, bloat is a *pruning-discipline* problem (archive-stub convention §6.7 + backlog split) before it's a *compression-format* problem. Adopt the pruning discipline first; measure your prose token cost; reach for wire only if it's still high. |

L1 + L2 is the proven sweet spot. L3 and L4 are honest extensions, not requirements.

---

## How ADP compares to known patterns

| Pattern | ADP relationship |
|---|---|
| [BMAD-method](https://docs.bmad-method.org/) | Same intent, smaller role set (5 vs 12+). |
| [ChatDev / MetaGPT](https://github.com/OpenBMB/ChatDev) | Adopted: structured artifacts as session-to-session communication. |
| [Claude Code subagents + skills + hooks](https://code.claude.com/docs/en/sub-agents) | Skills + hooks: yes, first-class. Subagents (`.claude/agents/`): host-native convenience, not enforcement (see L3 verdict above). |
| [Cursor rules](https://cursor.com/docs/rules) | Compatible. `process.md` ≈ `core.mdc`; role prompts ≈ scoped `.mdc` files. |
| [CrewAI / AutoGen](https://www.crewai.com/) | Different layer — those are runtimes; ADP is a process. |
| [Anthropic three-agent harness](https://www.anthropic.com/engineering/harness-design-long-running-apps) | Strongest convergence. ADP's Plan/Generate/Evaluate = Architect/Dev+Designer/Architect-running-PDCA-Check, with explicit file lanes + commit hygiene the harness doesn't address. |

See [PROTOCOL.md §3](./PROTOCOL.md) for the full benchmark.

---

## When NOT to use ADP

- **Solo dev, single session, hobby project.** Use a TODO list. ADP is overhead below ~3 sessions per week.
- **You need programmatic orchestration.** ADP is human-orchestrated by default. If you want a runtime, use CrewAI / Agent Framework / LangGraph and treat ADP as a process layer on top.
- **Your project's lifecycle is unusual** (research notebook, one-shot script, exploratory data analysis). ADP assumes a real codebase with tests and commits.

---

## License

ADP is open, dual-licensed: **documentation and specification under CC BY 4.0**,
**code, scripts, and templates under MIT**. Adapt, fork, and redistribute freely;
attribution is required for the spec (CC BY 4.0). See [`../LICENSE`](../LICENSE) for
the exact file scope and attribution string.

## Credits

Author: Guillermo Blanco, 2026. Distilled from a multi-agent production codebase.
1.0 → 1.1 distillation, market benchmark, audit, and applied-fold log: this bundle.
Sources cited in PROTOCOL.md.
