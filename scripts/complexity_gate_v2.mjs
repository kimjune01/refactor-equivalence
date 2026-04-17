#!/usr/bin/env node
/**
 * v2 ship-time complexity gate.
 *
 * Compares mean cognitive complexity across scoped functions between C_test
 * and the final C_llm candidate. Gate: mean_cog(C_llm) <= mean_cog(C_test) + 0.05.
 *
 * Scope: union of source files touched by C_test or C_llm (in their allowed
 * edit set). Tests, docs, generated files excluded (caller passes pre-filtered
 * paths).
 *
 * Usage:
 *   node complexity_gate_v2.mjs \
 *     --c-test-dir /tmp/refactor-eq-workdir/cleanroom-v2/24460 \
 *     --c-llm-dir  /tmp/refactor-eq-workdir/cleanroom-v2-llm/24460 \
 *     --scope-files path1.ts,path2.ts,... \
 *     --delta 0.05 \
 *     --out /path/to/gates/complexity-gate.json
 *
 * Exit codes:
 *   0  — gate passes (C_llm is within delta of C_test)
 *   1  — gate fails (C_llm > C_test + delta) — caller must fall back to C_test
 *   2  — measurement error (e.g., file missing in one snapshot)
 */

import { spawnSync } from 'node:child_process';
import { copyFileSync, readFileSync, rmSync, writeFileSync, existsSync, statSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { parseArgs } from 'node:util';

const { values } = parseArgs({
  options: {
    'c-test-dir':   { type: 'string' },
    'c-llm-dir':    { type: 'string' },
    'scope-files':  { type: 'string' },
    'delta':        { type: 'string', default: '0.05' },
    'out':          { type: 'string' },
    'complexity-tool': {
      type: 'string',
      default: resolve(new URL('./measure_complexity.mjs', import.meta.url).pathname),
    },
  },
});

function required(name, value) {
  if (!value) {
    console.error(`Missing required --${name}`);
    process.exit(2);
  }
  return value;
}

const cTestDir = required('c-test-dir', values['c-test-dir']);
const cLlmDir  = required('c-llm-dir',  values['c-llm-dir']);
const scopeArg = required('scope-files', values['scope-files']);
const delta    = parseFloat(values['delta']);
const outPath  = required('out', values['out']);
const tool     = values['complexity-tool'];

const scopeFiles = scopeArg.split(',')
  .map(s => s.trim())
  .filter(Boolean)
  // measure_complexity.mjs only handles TS/TSX. Filter out non-TS source.
  .filter(f => /\.(ts|tsx)$/.test(f))
  // Exclude test files defensively
  .filter(f => !/\.test\.(ts|tsx)$/.test(f));
if (scopeFiles.length === 0) {
  console.error('scope-files after TS filter is empty; gate skipped (pass)');
  // Write an empty-scope result so callers have a trail
  const emptyResult = {
    c_test: { mean_cog: 0, per_function_count: 0, files: [] },
    c_llm: { mean_cog: 0, per_function_count: 0, files: [] },
    delta_threshold: parseFloat(values['delta']),
    mean_cog_delta: 0,
    gate_pass: true,
    note: 'no TS/TSX files in scope after filtering',
  };
  const outPath = values['out'];
  if (outPath) {
    const { writeFileSync } = await import('node:fs');
    writeFileSync(outPath, JSON.stringify(emptyResult, null, 2));
  }
  process.exit(0);
}

function measureSnapshot(label, rootDir, files) {
  const existing = files.filter(f => {
    const p = join(rootDir, f);
    return existsSync(p) && statSync(p).isFile();
  });
  if (existing.length === 0) {
    return { mean_cog: 0, per_function_count: 0, files: [] };
  }
  // ESM resolution walks up from the tool script's location to find node_modules.
  // Copy the tool into rootDir (which has node_modules) and invoke the copy.
  const toolCopy = join(rootDir, '_complexity_measure_tmp.mjs');
  copyFileSync(tool, toolCopy);
  try {
    const paths = existing.map(f => join(rootDir, f));
    const proc = spawnSync('node', [toolCopy, ...paths], {
      encoding: 'utf8',
      maxBuffer: 64 * 1024 * 1024,
      cwd: rootDir,
    });
    if (proc.status !== 0) {
      console.error(`${label}: complexity tool failed`, proc.stderr);
      process.exit(2);
    }
    var stdout = proc.stdout;
  } finally {
    try { rmSync(toolCopy); } catch {}
  }
  // (stdout is captured above)
  const proc = { stdout };
  const parsed = JSON.parse(proc.stdout);
  const allFns = parsed.flatMap(r => r.functions || []);
  if (allFns.length === 0) {
    return { mean_cog: 0, per_function_count: 0, files: parsed.map(r => r.file) };
  }
  const mean = allFns.reduce((s, f) => s + f.cognitive, 0) / allFns.length;
  return {
    mean_cog: +mean.toFixed(4),
    per_function_count: allFns.length,
    files: parsed.map(r => r.file),
  };
}

const cTest = measureSnapshot('C_test', cTestDir, scopeFiles);
const cLlm  = measureSnapshot('C_llm',  cLlmDir,  scopeFiles);

const diff = cLlm.mean_cog - cTest.mean_cog;
const pass = diff <= delta;

const result = {
  c_test: cTest,
  c_llm: cLlm,
  delta_threshold: delta,
  mean_cog_delta: +diff.toFixed(4),
  gate_pass: pass,
  ...(pass ? {} : { fallback_action: 'revert_to_C_test' }),
};

writeFileSync(outPath, JSON.stringify(result, null, 2));
console.log(`complexity gate: ${pass ? 'PASS' : 'FAIL'} Δ=${result.mean_cog_delta} (threshold=${delta})`);

process.exit(pass ? 0 : 1);
