# ADP Roadmap

ADP versions the *standard*: `<spec-major>.<spec-minor>.<tooling-patch>` (see
`CHANGELOG.md` → Versioning policy).

## Current: spec **1.1**, tooling **1.1.5** (stable)

`current/PROTOCOL.md` is the ratified 1.1 specification. The 1.1.x line has been
hardened across multiple real installs (cross-platform installer, one-file
configuration, clean uninstall, honest enforcement status). **This is the version
to adopt today.**

## Next: spec **1.2** — candidates in pilot, not yet ratified

A set of 1.2 candidate deltas is being piloted in a production system. See
[`proposals/ADP-1.2-candidates.md`](./proposals/ADP-1.2-candidates.md) for the list,
the early evidence, and — importantly — the honest caveats.

**Why 1.2 is not shipped yet.** ADP promotes a portable spec change only at **n=2**
— i.e. after a *second* independent project confirms it, not on the first success.
The current pilot is **n=1**. A delta that worked once is a strong signal, not a
ratified rule. So `PROTOCOL.md` stays on 1.1 until a second project reproduces the
wins. (This is ADP applying its own "verified, not trusted" bar to itself.)

**Status 2026-08-08.** A second install exists and its retrospective harvest is
in review; its forward measurement window has not yet run — that window is the
blocker for ratification. One delta has already cleared the n=2 gate from real
incidents on both installs (explicit-pathspec commits, `git commit -- <paths>`)
and is ratifiable at the next spec pass. The n=1 install's five post-pilot weeks
also upgraded two candidate caveats and contributed three new candidates — see
`proposals/ADP-1.2-candidates.md`.

One candidate was already **pruned** in the pilot for being unadopted ceremony —
evidence the review mechanism isn't self-preserving.

**Want to help reach n=2?** If you run ADP on a real project and try any of the 1.2
candidates, please open an Issue/Discussion with what fired and what didn't —
especially disconfirming evidence.
