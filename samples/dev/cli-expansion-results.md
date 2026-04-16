# cli/cli expansion results — 6 additional PRs

Per pilot decision #6 (secondary-expansion trigger hit on initial 3-PR batch). Total cli/cli: 9 PRs (batch 1 + expansion), 4 excluded.

## Per-PR expansion results

| PR | Scalar Δ(llm−final) | Phase 1 | C_llm trajectory | Notes |
|----|---------------------|---------|-------------------|-------|
| 13009 | -0.08 | C_llm | wrong | API refactor; gemini found tension with C_final |
| 12811 | -0.24 | C_llm | short | Largest scalar improvement in batch; still short |
| 13025 | -0.02 | C_llm | past | Boundary scalar, reviewer confirmed past |
| 12526 | -0.08 | C_llm | short | Public API concerns noted by hunt-code |
| 12884 | 0.00 | (no-op) | auto-wrong | Tests fail (stale transfer fixture, hunt-spec predicted) |
| 12453 | -0.09 | C_llm | short | Clean pipeline, small improvements |

## Exclusions from the 10-PR expansion pool

| PR | Reason |
|----|--------|
| 12444 | Build-fail at C_final (squash-merge added files) |
| 12859 | Build-fail at C_final (squash-merge added methods) |
| 12774 | C_test == C_final |
| 12677 | Docs/CI-config only (no Go code) |

Replacement strategy: picked 12526, 12453, 12884 to bring batch to 6 (plus original 3).

## Full cli/cli aggregate (n=9)

- **P3 (prefers C_llm)**: 7/9 = **78%** ≥ 65% threshold ✓
- **P2 trajectory breakdown**: 1 past / 4 short / 2 wrong / 2 no-op
- **No-op rate**: 2/9 = 22% (below 40% futility threshold)
- **Combined with gemini-cli (5 PRs)**: 11/14 = 79% prefer C_llm; 2 past / 7 short / 3 wrong / 2 no-op

## Forge pipeline failure modes observed on cli/cli

1. **Reconcile-failure-to-reject (PR 12695)**: hunt-spec correctly predicted the `return_run_details` test failure but reconcile didn't remove the problematic claim. Noop resulted. Recommended fix for v2: reconcile must treat test-breaking findings as MUST-reject, not optional.

2. **Stale test fixture (PR 12884)**: PR's C_test has a test fixture in a *different package* than the allowed edit set, and that test fixture references symbols the refactor renamed. The refactor can't touch the test file (per prereg), so the test fails. This is a cross-package cascade the pipeline can't solve under current scope rules. Recommend: allow adjacent-test-only-edits for cases where the test is directly asserting on refactored symbols.

3. **Build-fail at C_final (PRs 12444, 12859)**: the PR HEAD commit isn't self-contained — tests reference symbols that were added in main post-merge (squash-merge artifact). Excluded per feasibility; affects candidate selection. Recommend: candidate filter should require `go test ./...` passes at C_final, not just assume it from PR approval status.
