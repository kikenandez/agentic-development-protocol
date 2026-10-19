#!/usr/bin/env node
// mcp-git-guard.mjs — PreToolUse(mcp__.*) hook, ADP §6.4 / §8.3 (Node port of
// mcp-git-guard.sh; tooling 1.1.9).
//
// git-hygiene and post-commit-orphan-check match the Bash tool only, so a git
// write made through an MCP tool skips the five §6.4 rules without a word. This
// hook names the gap instead of enforcing what it cannot parse:
//   tool name has a `commit` word                               -> ASK
//   tool name contains `git` and an add/reset/checkout/push word -> ASK
//   everything else (git_status, git_diff, git_log, non-git MCP) -> no-op
// It never denies. Fails SAFE: on an internal error it ASKS (visible).
//
// Kill switch: ADP_GIT_HOOK_DISABLE=1 (shared with git-hygiene)
if (process.env.ADP_GIT_HOOK_DISABLE === '1') process.exit(0);

function ask(reason) {
  process.stdout.write(JSON.stringify({ hookSpecificOutput: {
    hookEventName: 'PreToolUse', permissionDecision: 'ask', permissionDecisionReason: reason } }));
  process.exit(0);
}

async function readStdin() {
  const chunks = [];
  for await (const c of process.stdin) chunks.push(c);
  return Buffer.concat(chunks).toString('utf8');
}

try {
  const raw = await readStdin();
  let name = '';
  try { name = JSON.parse(raw || '{}')?.tool_name || ''; }
  catch { name = (/"tool_name"\s*:\s*"([^"]*)"/.exec(raw || '') || [])[1] || ''; }
  name = String(name).replace(/[^A-Za-z0-9_.-]/g, '');

  if (!name) {
    if ((raw || '').includes('git'))
      ask('ADP mcp-git-guard cannot read the tool name of this MCP call, so it cannot tell whether it writes to git. The git-hygiene hooks do not run on MCP tools. Proceed only if this call does not stage, commit, reset, checkout or push.');
    process.exit(0);
  }

  const lower = name.toLowerCase();
  const words = new Set(lower.split(/[_.-]+/));
  const isWrite = words.has('commit') ||
    (lower.includes('git') && ['add', 'reset', 'checkout', 'push'].some((w) => words.has(w)));
  if (!isWrite) process.exit(0);

  ask(`CONFIRM (ADP §6.4): ${name} looks like a git write through an MCP tool. The git-hygiene and orphan-check hooks match the Bash tool only, so the five §6.4 rules do NOT run on this call, and an MCP commit usually takes the whole index with no pathspec form. Prefer Bash: git status --short; git add <paths>; git commit -m '...' -- <paths>. Authorize this instance only if you have checked the staged set yourself.`);
} catch (e) {
  ask('ADP mcp-git-guard errored, so it cannot tell whether this MCP call writes to git. The git-hygiene hooks do not run on MCP tools. Proceed only if this call does not stage, commit, reset, checkout or push. (' + (e?.message || e) + ')');
}
