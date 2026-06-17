#!/usr/bin/env node
// uninstall.mjs — cross-platform ADP uninstaller (companion to uninstall.sh).
//
// Runs anywhere node runs (Windows without bash). Same safety model as
// uninstall.sh: safe by default (remove scaffolding, keep your authored work),
// --dry-run preview, --purge for a full rollback. Reverses the .gitignore block
// and un-wires settings.json (native JSON — no jq). Everything is git-tracked,
// so `git restore .` is the ultimate undo.
//
// Usage:  node uninstall.mjs [--dry-run] [--purge] /path/to/repo
import * as fs from 'node:fs';
import { join, dirname, sep } from 'node:path';
import { createInterface } from 'node:readline';

let DRY = false, PURGE = false, target = '';
for (const a of process.argv.slice(2)) {
  if (a === '--dry-run' || a === '--plan') DRY = true;
  else if (a === '--purge') PURGE = true;
  else target = a;
}
target = target || process.cwd();
const die = (m) => { console.error(m); process.exit(1); };
if (!fs.existsSync(target) || !fs.statSync(target).isDirectory()) die(`Error: not a directory: ${target}`);
target = fs.realpathSync(target);
if (!fs.existsSync(join(target, '.agentic-protocol', 'VERSION'))) die(`Error: no ADP install at ${target}.`);

const P = (r) => join(target, r.split('/').join(sep));
const rm = (r) => { const p = P(r); if (!fs.existsSync(p)) return; if (DRY) { console.log(`  WOULD REMOVE  ${r}`); return; } fs.rmSync(p, { recursive: true, force: true }); console.log(`  REMOVED  ${r}`); };
const rmdirIfEmpty = (r) => { const p = P(r); if (!fs.existsSync(p)) return; try { if (fs.readdirSync(p).length === 0) { if (DRY) console.log(`  WOULD REMOVE  ${r}/ (empty)`); else { fs.rmdirSync(p); console.log(`  REMOVED  ${r}/ (was empty)`); } } } catch {} };

console.log('==> Uninstalling Agentic Development Protocol (uninstall.mjs)');
console.log(`    From: ${target}`);
if (DRY) console.log('    MODE: dry-run — nothing will be written.');
if (PURGE) console.log('    MODE: PURGE — your plans/tasks/memory will ALSO be removed.');
console.log('');

if (!DRY && process.stdin.isTTY) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  const ask = (q) => new Promise(r => rl.question(q, x => r(x)));
  const c = await ask('Proceed? [y/N] ');
  if (!/^y(es)?$/i.test(c.trim())) { rl.close(); console.log('Aborted.'); process.exit(0); }
  if (PURGE) { const c2 = await ask("PURGE also deletes authored ADP content. Type 'purge' to confirm: "); if (c2.trim() !== 'purge') { rl.close(); console.log('Aborted.'); process.exit(0); } }
  rl.close();
  console.log('');
}

// 1) scaffolding (always)
console.log('==> Removing protocol scaffolding...');
rm('.adp'); rm('.agentic-protocol'); rm('.github/workflows/adp-checks.yml');
for (const h of ['git-hygiene', 'dispatch-freshness', 'post-commit-orphan-check', 'stop-cleanup']) { rm(`.claude/hooks/${h}.sh`); rm(`.claude/hooks/${h}.mjs`); }
rm('.claude/settings.node.json'); rm('.claude/HOOKS-cross-platform.md');
for (const a of ['architect', 'developer', 'designer', 'reviewer']) rm(`.claude/agents/${a}.md`);
for (const p of ['architect', 'developer', 'designer', 'reviewer', 'analyst', 'business', 'comms', 'process', 'initialize']) rm(`docs/prompts/${p}.md`);
for (const s of ['codebase-index', 'contract-enforcement', 'design-principles', 'operational-quick-ref']) rm(`docs/skills/${s}`);
rm('docs/skills/_README.md'); rm('docs/plans/_template.md'); rm('docs/retros/_template.md');
rm('docs/tasks/archive/_README.md'); rm('memory/_README.md');
for (const s of ['generate_map.py', 'wire-sync.sh', 'adp_metrics.py', 'verify-hooks.sh', 'verify-hooks.mjs']) rm(`scripts/${s}`);
rm('codebase_index.txt'); rm('codebase_tests_index.txt');

// 2) authored content (purge only)
if (PURGE) {
  console.log('\n==> PURGE: removing authored ADP content...');
  rm('docs/tasks/current.md'); rm('docs/tasks/archive'); rm('docs/plans'); rm('docs/retros'); rm('memory/CLAUDE.md');
  const memDir = P('memory');
  if (fs.existsSync(memDir)) for (const f of fs.readdirSync(memDir)) if (f.endsWith('.md')) rm(`memory/${f}`);
}

// 3) un-wire settings.json (native JSON; never delete it here)
console.log('\n==> Un-wiring hooks from .claude/settings.json...');
const SET = P('.claude/settings.json');
if (fs.existsSync(SET) && /git-hygiene/.test(fs.readFileSync(SET, 'utf8'))) {
  if (DRY) console.log('  WOULD remove the ADP "hooks" block (other settings preserved).');
  else { try { const c = JSON.parse(fs.readFileSync(SET, 'utf8')); fs.copyFileSync(SET, SET + '.pre-uninstall-' + Date.now()); delete c.hooks; fs.writeFileSync(SET, JSON.stringify(c, null, 2) + '\n'); console.log('  UN-WIRED hooks (backup settings.json.pre-uninstall-*).'); }
    catch { console.log('  WARN: settings.json not valid JSON — remove the "hooks" block by hand.'); } }
} else console.log('  No ADP hooks wired — nothing to un-wire.');

// 3b) reverse the ADP .gitignore block
const GI = P('.gitignore');
if (fs.existsSync(GI) && fs.readFileSync(GI, 'utf8').includes('added by Agentic Development Protocol')) {
  if (DRY) console.log('  WOULD reverse the ADP .gitignore block.');
  else { const lines = fs.readFileSync(GI, 'utf8').split(/\r?\n/); const i = lines.findIndex(l => l.includes('added by Agentic Development Protocol')); let kept = lines.slice(0, i); while (kept.length && kept[kept.length - 1].trim() === '') kept.pop(); fs.writeFileSync(GI, kept.join('\n') + (kept.length ? '\n' : '')); console.log('  REVERSED the ADP block in .gitignore (your patterns kept).'); }
}

// 3c) purge: remove an ADP-created settings.json ("{}" after un-wire) + backups
if (PURGE && !DRY) {
  if (fs.existsSync(SET) && !fs.existsSync(SET + '.adp-bak') && fs.readFileSync(SET, 'utf8').replace(/\s/g, '') === '{}') rm('.claude/settings.json');
  const cdir = P('.claude');
  if (fs.existsSync(cdir)) for (const f of fs.readdirSync(cdir)) if (f.startsWith('settings.json.pre-uninstall-') || f === 'settings.json.adp-hooks') fs.rmSync(join(cdir, f), { force: true });
}

// 4) tidy empty dirs
console.log('\n==> Tidying empty directories...');
for (const d of ['.claude/hooks', '.claude/agents', '.claude', 'docs/prompts', 'docs/skills', 'docs/tasks/archive', 'docs/tasks', 'docs/plans', 'docs/retros']) rmdirIfEmpty(d);

// 5) report
console.log('');
if (!PURGE) {
  console.log('==> Done (safe mode). Anything still under docs/ or memory/ is YOUR work, kept on purpose.');
  console.log('    (Re-run with --purge to remove those too.)');
} else console.log('==> Done (purge). All ADP files removed.');
console.log('\nNotes:');
console.log('  - The ADP .gitignore block was reversed (your own patterns kept).');
console.log("  - Everything was git-tracked: review with 'git status', then commit — or undo with 'git restore .'.");
if (DRY) console.log('  - DRY RUN: nothing was actually changed.');
process.exit(0);
