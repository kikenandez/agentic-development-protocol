# OpenShell lane-sandbox trial — 2026-10-21

**What this is:** the boundary half of candidate #8 in
`proposals/ADP-1.2-candidates.md` (lane-scoped sandbox per role), run once.
**Scope:** n=0 by install. The tests ran against a throwaway clone of one ADP
install (a static site plus a Firebase-functions backend). They ran shell
commands only. No agent session ran inside the sandbox, and the install's real
work tree was never mounted. Nothing here advances an n-counter.

## Setup

| Item | Value |
|---|---|
| Host | macOS 15.8, **Intel** (x86_64), Docker Desktop 29.8 |
| OpenShell | 0.1.5 (gateway, supervisor and sandbox images pinned to `0.1.5`) |
| Sandbox kernel | Docker Desktop VM, Linux 7.0 (linuxkit), Landlock enabled |
| Workload image | `node:22-bookworm` + `jq`, project clone at `/sandbox`, user `node` (uid 1000) |

**Intel Macs are not on the support matrix.** The CLI, gateway and VM driver ship
only `aarch64-apple-darwin` builds for macOS, and the Homebrew formula requires
arm64. The trial used a route that NVIDIA doesn't list:

1. Run the gateway as a container, from the official `deploy/docker` Compose file.
   Changes: the data directory moved under `$HOME` (Docker Desktop can't bind
   `/var/lib`). The bind address inside the container became `0.0.0.0` (the
   published port stays on `127.0.0.1`). `supervisor_network_mode = "bridge"`
   (host mode needs Docker Desktop host networking). Images pinned to 0.1.5.
2. Run the Linux CLI (`openshell-x86_64-unknown-linux-musl`, checksum verified)
   inside an `alpine` container that shares the gateway container's network
   namespace.

The sandboxes themselves run on the Docker Desktop Linux VM, which meets the kernel
requirements. The "Running the Gateway as a Container" doc page is behind 0.1.5:
the supervisor image no longer contains `/openshell-sandbox`, and the gateway
pulls the sandbox and supervisor images itself. `sandbox upload` from the alpine
CLI fails (it shells out to `git`). Piping the script into `sandbox exec … sh -s`
works.

## Policy (designer lane, from the install's `process.md` §4)

```yaml
version: 1
filesystem_policy:
  include_workdir: false
  read_only: [/usr, /lib, /lib64, /bin, /sbin, /etc, /proc, /dev/urandom, /sandbox]
  read_write:
    - /tmp
    - /dev/null
    - /sandbox/site
    - /sandbox/web
    - /sandbox/docs/tasks/current.md
    - /sandbox/.git            # variant A only; removed in variant B
landlock:
  compatibility: hard_requirement   # best_effort would run WITHOUT rules on failure
```

No network rules, so all egress is denied. The project files are owned by the
workload user with mode 755/644, so every refusal below came from the sandbox, not
from Unix permissions. The ADP hooks were not involved: no agent host ran, so no
hook ran.

## Results

| Test | A: `.git` writable | B: `.git` read-only |
|---|---|---|
| Read a file outside the lane | allowed | allowed |
| Write in `site/`, `web/`; append to `current.md` | allowed | allowed |
| `git commit` of a lane change | allowed | **refused** |
| **V1** write outside the lane: shell, python, node, architect lane, `firebase.json` | refused (5/5) | refused (5/5) |
| **V1** `git checkout <old> -- firebase.json` | work tree refused, **old version staged in the index** | refused |
| **V2** edit or delete `.claude/hooks/*`, `.claude/settings.json` | refused (3/3) | refused (3/3) |
| **V3** commit `functions/plumbed.js` with git plumbing (`hash-object` → `update-index` → `commit`) | **allowed: the commit landed** | refused |
| **V3** write `.git/hooks/pre-commit` | **allowed** | refused |
| **V4** read `~/.fake-credentials` (outside the policy) | refused | refused |
| **V4** read OpenShell's `/.openshell` | refused | refused |
| **V4** HTTPS to example.com; raw TCP to 1.1.1.1:443 | refused | refused |
| **V4** `sudo` | refused | refused |

## Findings

1. **The filesystem boundary holds for every write route tried**: shell, python,
   node and git's work-tree writes. That includes the hook scripts and
   `.claude/settings.json`, which §6.4 says hooks cannot protect. Egress and
   credential reads are refused with no extra configuration.
2. **A writable `.git` is a lane bypass.** Git objects, the index and refs are
   not lane-scoped. With `.git` writable, the sandbox can commit any path in
   history without writing it to the work tree, can stage outside-lane content,
   and can replace git hooks. Path-level isolation cannot express "commits may
   touch only these paths."
3. **Variant B closes it, at a cost:** no commits inside the sandbox. The session
   edits its lane, and the commit happens outside the sandbox, by pathspec (§6.4
   rule 1), where ADP's hooks and the orphan check run. Another option is a
   lane-path check in CI or a pre-receive hook on the shared remote. Either way,
   the commit gate leaves the sandbox.

## Against candidate #8's prune rule

"Prune if any of the four violations gets through." **Variant A fails V3.**
**Variant B passes all four.** The candidate survives only as variant B: a
read-only `.git` and commits made outside the sandbox. The rest of the pilot is
still unrun: the two weeks of normal work, blocked-legit-work counts and setup
time.

## Not tested

- An agent host (Claude Code) inside the sandbox. That needs an Anthropic provider
  credential, which the operator must create. The trial didn't handle keys.
- Whether ADP's own hooks run correctly inside the sandbox, and how they behave
  with `.claude/` read-only.
- MicroVM runtime, mTLS gateway, the policy prover, network policies with
  allow-rules.
- The real work tree mounted with bind mounts (needs `enable_bind_mounts`, which
  the docs warn can bypass filesystem policy).
