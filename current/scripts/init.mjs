#!/usr/bin/env node
// init.mjs — cross-platform ADP installer (companion to init.sh).
//
// Same behavior as init.sh, but runs anywhere `node` runs — including Windows
// with no bash and no jq (the gap the Codex install-retro found). JSON merging is
// native, so it never needs jq. On --host=claude-code it wires the *Node* hooks
// (they need only node). init.sh stays the canonical Unix installer.
//
// Usage:
//   node init.mjs /path/to/repo                 # prose only
//   node init.mjs --host=claude-code /path      # + .claude enforcement infra (Node hooks)
//   node init.mjs --ci /path                    # + CI workflow (opt-in)
//   node init.mjs --dry-run /path               # preview, write nothing
//   node init.mjs --yes /path                   # non-interactive (auto when no TTY)
import { execSync } from 'node:child_process';
import * as fs from 'node:fs';
import { join, dirname, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createInterface } from 'node:readline';

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const TEMPLATE_DIR = join(SCRIPT_DIR, '..', 'template');

// ---- args -------------------------------------------------------------------
let HOST = '', YES = false, CI = false, DRY = false, target = '';
for (const a of process.argv.slice(2)) {
  if (a.startsWith('--host=')) HOST = a.slice(7);
  else if (a === '--yes' || a === '-y') YES = true;
  else if (a === '--ci') CI = true;
  else if (a === '--dry-run' || a === '--plan') DRY = true;
  else target = a;
}
const isCC = HOST === 'claude-code';
const die = (m) => { console.error(m); process.exit(1); };

if (!fs.existsSync(TEMPLATE_DIR)) die(`Error: template directory not found at ${TEMPLATE_DIR}`);
target = target || process.cwd();
if (!fs.existsSync(target) || !fs.statSync(target).isDirectory()) die(`Error: target directory does not exist: ${target}`);
target = fs.realpathSync(target);

const have = (cmd) => { try { execSync(process.platform === 'win32' ? `where ${cmd}` : `command -v ${cmd}`, { stdio: 'ignore' }); return true; } catch { return false; } };
const HAVE_JQ = have('jq'), HAVE_NODE = true; // we are node

const VERSION = (() => { try { return fs.readFileSync(join(TEMPLATE_DIR, '.agentic-protocol', 'VERSION'), 'utf8').split('\n')[0]; } catch { return 'ADP'; } })();
console.log('==> Installing Agentic Development Protocol (init.mjs)');
console.log(`    Version: ${VERSION}`);
console.log(`    Into: ${target}`);
if (DRY) console.log('    MODE: DRY RUN — previewing only, nothing will be written.');
console.log('');

// ---- clean-tree check -------------------------------------------------------
if (!DRY) {
  try {
    execSync('git rev-parse --git-dir', { cwd: target, stdio: 'ignore' });
    const dirty = execSync('git status --porcelain', { cwd: target, encoding: 'utf8' }).trim();
    if (dirty) {
      console.log(`  WARN: ${target} has uncommitted changes.`);
      console.log('        Installing now mixes ADP files with your pending work. Recommended:');
      console.log('          git stash   (or commit)   then   git checkout -b adopt-adp');
      console.log('        Tip: re-run with --dry-run to preview without writing anything.\n');
      if (!YES && process.stdin.isTTY) {
        const rl = createInterface({ input: process.stdin, output: process.stdout });
        const ans = await new Promise(r => rl.question('  Proceed onto a dirty tree anyway? [y/N] ', x => { rl.close(); r(x); }));
        if (!/^y(es)?$/i.test(ans.trim())) { console.log('Aborted.'); process.exit(0); }
      }
    }
  } catch { /* not a git repo — skip */ }
}

// ---- prereq check -----------------------------------------------------------
console.log('==> Checking prerequisites...');
if (!have('git')) console.log('  WARN: git not found.');
if (!have('python3') && !have('python')) console.log('  WARN: python not found — generate_map.py / adp_metrics.py will not run.');
console.log('');

// ---- confirm ----------------------------------------------------------------
if (!DRY && !YES && process.stdin.isTTY) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  const ans = await new Promise(r => rl.question('Proceed? [y/N] ', x => { rl.close(); r(x); }));
  if (!/^y(es)?$/i.test(ans.trim())) { console.log('Aborted.'); process.exit(0); }
} else if (!DRY) {
  console.log('Proceeding non-interactively (--yes or non-TTY).');
}

// ---- helpers ----------------------------------------------------------------
const rel = (p) => p.split(sep).join('/');
function walk(dir) {
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, e.name);
    if (e.isDirectory()) out.push(...walk(full));
    else out.push(full);
  }
  return out;
}
const isEnforcementInfra = (r) =>
  r.startsWith('.claude/agents/') || r.startsWith('.claude/hooks/') ||
  r === '.claude/settings.json' || r === '.claude/settings.node.json' || r === '.claude/HOOKS-cross-platform.md';
const isCI = (r) => r === '.github/workflows/adp-checks.yml';

// ---- copy loop --------------------------------------------------------------
console.log('==> Copying files (existing files are preserved)...');
const manifest = [], merges = [];
let added = 0, skipped = 0;
for (const src of walk(TEMPLATE_DIR)) {
  const r = rel(src.slice(TEMPLATE_DIR.length + 1));
  // init.mjs wires settings.json itself (Node flavor) — never copy the bash one.
  if (r === '.claude/settings.json') continue;
  if (!isCC && isEnforcementInfra(r)) { console.log(`  SKIP  ${r} (enforcement infra — use --host=claude-code)`); skipped++; continue; }
  if (!CI && isCI(r)) { console.log(`  SKIP  ${r} (CI is opt-in — use --ci)`); skipped++; continue; }
  const dst = join(target, r.split('/').join(sep));
  if (fs.existsSync(dst)) { console.log(`  SKIP  ${r} (already exists)`); skipped++; continue; }
  if (DRY) { console.log(`  WOULD ADD  ${r}`); added++; continue; }
  fs.mkdirSync(dirname(dst), { recursive: true });
  fs.copyFileSync(src, dst);
  console.log(`  ADD   ${r}`); manifest.push(r); added++;
}
console.log('');
console.log(DRY ? `==> Plan: would add ${added}; would skip ${skipped}.` : `==> Done. Added ${added}; skipped ${skipped}.`);

// ---- settings.json wiring (Node hooks — no jq needed) -----------------------
if (isCC) {
  const SET = join(target, '.claude', 'settings.json');
  const TPL_NODE = join(TEMPLATE_DIR, '.claude', 'settings.node.json');
  if (fs.existsSync(TPL_NODE)) {
    console.log('\n==> Wiring Node hooks into .claude/settings.json...');
    const tplHooks = JSON.parse(fs.readFileSync(TPL_NODE, 'utf8')).hooks;
    if (fs.existsSync(SET)) {
      const cur = readJson(SET);
      if (cur && JSON.stringify(cur.hooks || '').includes('git-hygiene')) {
        console.log('  OK: settings.json already wires ADP hooks.');
      } else if (cur && cur.hooks) {
        if (!DRY) fs.copyFileSync(TPL_NODE, SET + '.adp-hooks');
        console.log('  WARN: settings.json has its own "hooks" key — NOT modified. See settings.json.adp-hooks.');
      } else if (cur) {
        if (DRY) console.log('  WOULD MERGE Node hooks (backup .adp-bak).');
        else { fs.copyFileSync(SET, SET + '.adp-bak'); cur.hooks = tplHooks; fs.writeFileSync(SET, JSON.stringify(cur, null, 2) + '\n');
          console.log('  MERGED Node hooks into settings.json (keys preserved; old kept .adp-bak).'); merges.push('merge: .claude/settings.json (Node hooks; backup .adp-bak)'); }
      } else {
        if (!DRY) fs.copyFileSync(TPL_NODE, SET + '.adp-hooks');
        console.log('  WARN: settings.json is not valid JSON — wrote reference to settings.json.adp-hooks.');
      }
    } else {
      if (DRY) console.log('  WOULD WRITE settings.json wiring the Node hooks.');
      else { fs.mkdirSync(dirname(SET), { recursive: true }); fs.copyFileSync(TPL_NODE, SET);
        console.log('  WROTE settings.json wiring the Node hooks.'); manifest.push('.claude/settings.json'); }
    }
  }
}
function readJson(p) { try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return null; } }

// ---- .gitignore append ------------------------------------------------------
const GI = join(target, '.gitignore'), TPL_GI = join(TEMPLATE_DIR, '.gitignore');
if (fs.existsSync(TPL_GI) && fs.existsSync(GI)) {
  const have = new Set(fs.readFileSync(GI, 'utf8').split(/\r?\n/));
  const add = fs.readFileSync(TPL_GI, 'utf8').split(/\r?\n/).filter(l => l.trim() && !l.startsWith('#') && !have.has(l));
  if (add.length) {
    if (DRY) console.log(`\n==> .gitignore: WOULD append ${add.length} ADP pattern(s).`);
    else { fs.appendFileSync(GI, '\n# --- added by Agentic Development Protocol ---\n' + add.join('\n') + '\n');
      console.log(`\n==> .gitignore: appended ${add.length} ADP pattern(s).`); merges.push(`merge: .gitignore (appended ${add.length} pattern(s))`); }
  }
}

// ---- install scripts --------------------------------------------------------
console.log('\n==> Installing scripts...');
let scripts = ['generate_map.py', 'wire-sync.sh', 'adp_metrics.py'];
if (isCC) scripts = scripts.concat(['verify-hooks.sh', 'verify-hooks.mjs']);
for (const s of scripts) {
  const srcS = join(SCRIPT_DIR, s); if (!fs.existsSync(srcS)) continue;
  const dstS = join(target, 'scripts', s);
  if (fs.existsSync(dstS)) continue;
  if (DRY) { console.log(`  WOULD ADD  scripts/${s}`); continue; }
  fs.mkdirSync(dirname(dstS), { recursive: true }); fs.copyFileSync(srcS, dstS);
  console.log(`  ADD   scripts/${s}`); manifest.push(`scripts/${s}`);
}

if (DRY) { console.log('\n==> DRY RUN complete — nothing was written.'); process.exit(0); }

// ---- manifest ---------------------------------------------------------------
const MAN = join(target, '.agentic-protocol', 'INSTALL_MANIFEST');
fs.mkdirSync(dirname(MAN), { recursive: true });
fs.writeFileSync(MAN, [
  '# ADP INSTALL_MANIFEST — generated by init.mjs; do not edit by hand.',
  `# Version: ${VERSION}`, `# Installed: ${new Date().toISOString()}`,
  `# Host: ${HOST || 'generic'}`, '# Reverse with: uninstall.mjs / uninstall.sh.',
  '', '[files-added]', ...manifest.slice().sort(), '', '[merges-performed]', ...merges, '',
].join('\n'));
console.log('\n==> Wrote install manifest: .agentic-protocol/INSTALL_MANIFEST');

// ---- enforcement status -----------------------------------------------------
let enf = 'none';
if (isCC) {
  const SET = join(target, '.claude', 'settings.json');
  const txt = fs.existsSync(SET) ? fs.readFileSync(SET, 'utf8') : '';
  if (txt.includes('git-hygiene.mjs')) enf = 'active_node';
  else if (txt.includes('git-hygiene.sh')) enf = HAVE_JQ ? 'active_bash' : 'inert_nojq';
  else enf = 'notwired';
}
console.log('\n==> ENFORCEMENT STATUS:');
const msg = {
  none: '  Prose-only install — no L3 hooks. Add later with --host=claude-code.',
  active_node: "  Hooks WIRED (Node) — no jq needed. If you merged into a live session, reload/restart it to ARM the hooks. REQUIRED: in Claude Code try 'git add -A' and confirm it is BLOCKED.",
  active_bash: "  Hooks WIRED (bash) + jq present. If you merged into a live session, reload/restart it to ARM the hooks. REQUIRED: in Claude Code try 'git add -A' and confirm it is BLOCKED.",
  inert_nojq: '  Hooks wired (bash) but INERT — no jq. Use Node hooks: cp .claude/settings.node.json .claude/settings.json',
  notwired: '  Hooks NOT wired — see .claude/settings.json.adp-hooks, or use the Node hooks.',
}[enf];
console.log(msg);
console.log('\nNext: read .agentic-protocol/GETTING_STARTED.md, fill <<<placeholders>>>, run a first architect session.');
process.exit(0);
