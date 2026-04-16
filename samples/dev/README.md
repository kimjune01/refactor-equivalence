# Dev set pilot artifacts

5 PRs from `google-gemini/gemini-cli`. Each PR dir contains the forge pipeline trail in execution order.

## Per-PR contents

- `volley-round1.md` — codex's initial sharpened claim list (step 1)
- `hunt-spec-findings.md` — codex's adversarial review of the claim list (step 2)
- `hunt-spec-findings-round1.md` (if present) — the first-round findings before reconciliation (only where findings existed)
- `sharpened-spec-final.md` — the converged spec after any reconciliation (step 3)
- `hunt-code-findings.md` — codex's adversarial review of the merged code (step 5)
- `c_llm_diff.patch` — the final C_llm refactor vs C_test (the measured artifact)

## Measurements

- `pilot-results.md` — scoped metrics summary across all 5 PRs
- `24437-metrics.md` — n=1 detailed metrics (kept for history)

## PR inclusion record

| PR | Title | Fate | Scoped files | Claims applied | C_llm vs C_final (mean cognitive) |
|----|-------|------|--------------|----------------|-----------------------------------|
| 24437 | fix(core): ensure complete_task tool calls are recorded in chat history | applied | 5 | 5/5 | -0.04 (past) |
| 24483 | feat(core): Land ContextCompressionService | applied + 1-line patch | 17 | 15/15 | -0.08 (past) |
| 24489 | feat(core): refactor subagent tool to unified invoke_subagent tool | applied | 73 | 10/10 | -0.03 (past, boundary) |
| 24623 | split context | applied | 32 | 10/10 | -0.04 (past) |
| 25101 | refactor(core): consolidate execute() arguments into ExecuteOptions | applied | 38 | 25/25 | -0.01 (past, boundary) |

## PR exclusion record

No PRs excluded from the dev set. 100% C_test reconstruction rate (5/5).

Of the 89 eligible candidates in `candidates-gemini-cli.json`, these 5 were chosen for the pilot by size diversity and package coverage. The remaining 84 are reserved for the test set — no overlap permitted until prompt freeze.
