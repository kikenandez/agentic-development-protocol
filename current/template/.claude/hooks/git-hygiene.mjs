#!/usr/bin/env node
// git-hygiene.mjs — PreToolUse(Bash) hook, ADP §6.4 (cross-platform Node port).
//
// No jq, no bash — runs anywhere `node` runs (macOS/Linux/Windows). This retires
// the two silent-failure modes of the .sh version (missing jq, no bash on Windows).
// Behaviour is identical to git-hygiene.sh:
//   bulk staging (add -A/./--all, commit -a/--all) -> DENY
//   destructive (reset --hard, push --force, branch -D) -> ASK
//   plain git commit -> ALLOW + inject `git status --short` as context
// Fails SAFE: if the hook itself errors, it ASKS (visible) rather than silently
// allowing — a hygiene gate must never quietly disable itself (retro #2).
//
// Kill switch: ADP_GIT_HOOK_DISABLE=1
import { execSync } from 'node:child_process';

if (process.env.ADP_GIT_HOOK_DISABLE === '1') process.exit(0);

function emit(decision, reason, context) {
  const o = { hookSpecificOutput: { hookEventName: 'PreToolUse', permissionDecision: decision, permissionDecisionReason: reason } };
  if (context) o.hookSpecificOutput.additionalContext = context;
  process.stdout.write(JSON.stringify(o));
  process.exit(0);
}

async function readStdin() {
  const chunks = [];
  for await (const c of process.stdin) chunks.push(c);
  return Buffer.concat(chunks).toString('utf8');
}

try {
  const raw = await readStdin();
  let cmd = '';
  // On parse failure, scan the RAW payload rather than go blind (a bulk-stage
  // command in a malformed envelope must still be caught).
  try { cmd = JSON.parse(raw || '{}')?.tool_input?.command || ''; } catch { cmd = raw || ''; }
  if (!cmd.includes('git')) process.exit(0);

  // Strip quoted substrings so a commit MESSAGE can't trip the structural rules.
  const s = cmd.replace(/'[^']*'/g, '').replace(/"[^"]*"/g, '');

  // §6.4 rule 1 — bulk staging -> DENY
  if (/git\s+add\s+(-A(\s|$)|--all(\s|$)|\.(\s|$))/.test(s))
    emit('deny', "BLOCKED (ADP §6.4 rule 1): 'git add -A/./--all' bulk-stages the shared working tree and sweeps other sessions' files. Stage by exact path: git add <path1> <path2>. Need a file outside your lane? Write a handoff task.");
  if (/git\s+commit\s+(-a(\s|$)|-[a-zA-Z]*a[a-zA-Z]*\s|--all(\s|$))/.test(s))
    emit('deny', "BLOCKED (ADP §6.4 rule 1): 'git commit -a/--all' stages every tracked change. Stage by exact path first, then 'git commit -m'.");

  // §6.4 rule 4 + destructive-op -> ASK
  if (/git\s+reset\s+.*--hard/.test(s))
    emit('ask', "CONFIRM (ADP §6.4 rule 4): 'git reset --hard' discards work irreversibly. Prefer --soft/--mixed; 'git stash' first if you must. Authorize this instance?");
  if (/git\s+push\s+.*(--force([^-]|$)|--force-with-lease|-f(\s|$))/.test(s))
    emit('ask', "CONFIRM: force-push rewrites remote history. Authorize this instance?");
  if (/git\s+branch\s+.*-D(\s|$)/.test(s))
    emit('ask', "CONFIRM: 'git branch -D' force-deletes a branch (may drop unmerged work). Authorize this instance?");

  // §6.4 rule 2 — surface the staged set at every commit -> ALLOW + context
  if (/git\s+commit(\s|$)/.test(s)) {
    let status = '';
    try { status = execSync('git status --short', { encoding: 'utf8' }); } catch { status = '(git status unavailable)'; }
    if (!status.trim()) status = '(working tree clean — nothing staged?)';
    emit('allow', 'git commit allowed; staged set surfaced for §6.4 rule 2 review.',
      'ADP §6.4 rule 2 — review the staged set BEFORE this commit lands.\n`git status --short`:\n' + status +
      '\n\nStaged entries (M/A/D left column) MUST be only files you own. Un-stage strays: git reset HEAD <path>. If a stray already committed, fix forward with a new commit (rule 5), never --amend.');
  }

  process.exit(0);
} catch (e) {
  // FAIL SAFE (retro #2): surface the failure instead of silently allowing.
  process.stdout.write(JSON.stringify({ hookSpecificOutput: {
    hookEventName: 'PreToolUse', permissionDecision: 'ask',
    permissionDecisionReason: 'ADP git-hygiene hook errored — cannot verify staging hygiene. Proceed only if you have checked `git status --short` yourself. (' + (e?.message || e) + ')'
  } }));
  process.exit(0);
}
