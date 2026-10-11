#!/usr/bin/env node
// session-end-latch.mjs — SessionEnd hook, ADP §6.2 (Node port). Never fails.
// Releases this session's dispatch-freshness latch so the next session faces the
// gate again. SessionEnd, not Stop: Stop fires at the end of every turn.
import { rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

let raw = '';
try {
  for await (const chunk of process.stdin) raw += chunk;
  let session = '';
  try { session = JSON.parse(raw || '{}')?.session_id || ''; } catch {}
  if (/^[A-Za-z0-9_-]{1,128}$/.test(session)) {
    rmSync(join(tmpdir(), `.adp-dispatch-ok-${session}`), { force: true });
  }
} catch { /* never fail */ }
process.exit(0);
