# Pilot results — 5 PRs from google-gemini/gemini-cli

n=5. Scoped measurements: union of C_test ∪ C_llm TypeScript source files (per PREREG §Variables.1). Tool: `scripts/measure_complexity.mjs` (typescript-estree AST walker).

## Primary scalar: mean cognitive complexity across touched functions

| PR | files | C_test | C_llm | C_final | Δ(C_llm − C_final) | Class |
|----|-------|--------|-------|---------|--------------------|-------|
| 24437 | 5 | 4.53 | **4.41** | 4.45 | -0.04 | Past C_final |
| 24483 | 17 | 3.86 | **3.77** | 3.85 | -0.08 | Past C_final |
| 24489 | 73 | 4.74 | **4.71** | 4.74 | -0.03 | Past C_final (boundary) |
| 24623 | 32 | 5.55 | **5.51** | 5.55 | -0.04 | Past C_final |
| 25101 | 38 | 5.48 | **5.47** | 5.48 | -0.01 | Past C_final (boundary/tie) |

**All 5 C_llm ≤ C_final on mean cognitive complexity.** 3/5 clearly past (Δ ≤ -0.04), 2/5 within the boundary threshold δ=0.05.

**Zero wrong-direction trials.** No slop-slope in this pilot.

## Mean cyclomatic complexity (secondary scalar)

| PR | C_test | C_llm | C_final |
|----|--------|-------|---------|
| 24437 | 3.66 | **3.61** | 3.66 |
| 24483 | 3.71 | **3.67** | 3.70 |
| 24489 | 4.10 | **4.09** | 4.11 |
| 24623 | 4.65 | **4.63** | 4.65 |
| 25101 | 4.60 | 4.60 | 4.60 |

## LOC (descriptive, not a quality measure)

| PR | C_test | C_llm | C_final | C_llm − C_test | C_final − C_test |
|----|--------|-------|---------|----------------|------------------|
| 24437 | 2344 | 2344 | 2385 | 0 | +41 |
| 24483 | 15707 | **15694** | 15711 | **-13** | +4 |
| 24489 | 36372 | 36374 | 36684 | +2 | +312 |
| 24623 | 23385 | **23345** | 23768 | **-40** | +383 |
| 25101 | 19211 | **19182** | 19212 | **-29** | +1 |

**C_llm ≤ C_test on LOC in all 5 PRs** (same or lower). **C_final > C_test on LOC in all 5** (reviewers pushed for additions).

## Max function complexity (unchanged across all snapshots)

Max cyclomatic, max cognitive, and max nesting are identical in C_test / C_llm / C_final for 4/5 PRs. PR 24489 shows C_final max-nesting = 15 while C_test and C_llm stay at 14.

The worst functions (e.g., `processFunctionCalls` at 43/77 in PR 24437) are left untouched by both the LLM refactor and the reviewer-accepted version.

## Forge pipeline summary per PR

| PR | Claims applied | Opus vs Codex diverge | No-op | Notes |
|----|----------------|----------------------|-------|-------|
| 24437 | 5/5 | byte-identical | no | hunt-code via gemini (wrong model per skill, but outcome correct) |
| 24483 | 15/15 | 2 files | **(recovered)** | TS type error post-merge; manual 1-line patch; build now green. Out-of-order: verified before hunt-code |
| 24489 | 10/10 | 4 files | no | clean |
| 24623 | 10/10 | 4 files | no | clean |
| 25101 | 25/25 | 2 files | no | clean |

## Scalar trajectory class summary

| Class | Count | PRs |
|-------|-------|-----|
| Past C_final (Δ < -0.05) | 2/5 | 24437, 24483 |
| Past C_final (boundary, -0.05 ≤ Δ < 0) | 3/5 | 24489, 24623, 25101 |
| Short of C_final | 0/5 | — |
| Wrong direction | 0/5 | — |
| No-op | 0/5 | — |

All 5 in the non-negative direction on the primary scalar. Reviewer-classified trajectory (headline per prereg) pending phase 7 blind review.

## Observations

1. **Additive bias in reviews.** C_final adds LOC in all 5 PRs (+1 to +383), while C_llm matches or subtracts (0 to -40). Reviewers push for additions (more tests, more comments, more defensive guards); the LLM refactor prefers subtraction where possible. This is one clean expression of the slop-slope hypothesis: the reviewer destination isn't the complexity minimum.
2. **Max-function complexity is sticky.** Neither the LLM refactor nor the accepted PR touched the heaviest functions (43 CC / 77 cognitive in PR 24437's processFunctionCalls, 275/486 in PR 24489's registry). Simplification happened at the edges.
3. **Scalar deltas are small.** 0.01–0.12 on mean cognitive; 0.00–0.05 on mean cyclomatic. Under δ=0.05, 3/5 land in the boundary zone — scalar alone is not high-confidence. Reviewer classification (primary) will be more decisive.
4. **Codex additive bias in volley generation.** Initial volleys produced zero rejections across all 5 PRs; rejections only appeared after hunt-spec prompted them. Consistent with the training-data hypothesis.
