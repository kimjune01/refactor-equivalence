# PR 24437 — Complexity Metrics

Measured 2026-04-15. Tool: `scripts/measure_complexity.mjs` (typescript-estree AST walk).

Scope: union of source files touched by C_test or C_llm (2 files):
- `packages/core/src/agents/local-executor.ts`
- `packages/core/src/tools/complete-task.ts`

## Summary

| Metric | C_test | C_llm | C_final | C_llm trajectory |
|--------|--------|-------|---------|------------------|
| Function count | 25 | 26 | 26 | = C_final |
| Total LOC | 1558 | 1558 | 1599 | Better (no growth) |
| Mean cyclomatic | 7.28 | **7.00** | 7.11 | **Past C_final** |
| Max cyclomatic | 43 | 43 | 43 | Same |
| Mean cognitive | 10.84 | **10.27** | 10.39 | **Past C_final** |
| Max cognitive | 77 | 77 | 77 | Same |
| Max nesting | 6 | 6 | 6 | Same |

## Trajectory class (scalar): Past C_final

C_llm has lower mean cyclomatic and cognitive complexity than C_final. The improvement is small (Δ=0.11 CC, Δ=0.12 cognitive vs C_final; Δ=0.28 CC, Δ=0.57 cognitive vs C_test) but directionally correct on both measures.

The max-function complexity (43 CC / 77 cognitive in `processFunctionCalls`) is unchanged across all snapshots — the refactoring correctly left the pre-existing heavyweight untouched.

C_llm achieved the improvement with zero LOC growth, while C_final added 41 lines.

## Forge pipeline metadata

- Volley rounds: 2 (sharpen) + 2 (hunt-spec)
- Claims: 6 proposed, 1 rejected, 5 applied
- Blind-blind merge: opus + codex → byte-identical output
- Hunt-code: gemini, 1 round, zero findings
- Volley-clean: 1 round, converged
- No-op: No (tests pass, edits applied)
- Total C_llm diff: 15 insertions, 15 deletions across 2 files

## Snapshots

| Snapshot | Commit / path |
|----------|---------------|
| C_base | `7d1848d578b644c274fcd1f6d03685aafc19e8ed` |
| C_test | `ffd11f5f1268b90351b3375977a243e457251f6e` |
| C_final | `e169c700911f5d2161b3fc94006f911355aeca1a` |
| C_llm | `/tmp/refactor-eq-workdir/snapshots/24437/c_llm/` |
