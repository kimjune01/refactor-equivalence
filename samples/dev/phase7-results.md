# Phase 7 blind review — pilot results

n=5 PRs, n=1 reviewer (gemini 3.1 pro preview). Pilot feasibility per prereg; 3-reviewer rule deferred to test set.

## Per-PR results

| PR | A= | B= | Choice | Preferred | C_llm traj | C_test traj | Correctly ID'd C_llm as LLM |
|----|----|----|--------|-----------|------------|-------------|------------------------------|
| 24437 | c_test | c_llm | B | **C_llm** | short | short | yes |
| 24483 | c_test | c_llm | B | **C_llm** | past | short | yes |
| 24489 | c_llm | c_test | A | **C_llm** | short | wrong | yes |
| 24623 | c_llm | c_test | A | **C_llm** | short | wrong | yes |
| 25101 | c_llm | c_test | B | **C_test** | wrong | past | yes |

## P3 (merge-readiness preference): 4/5 = 80%

Prereg target: ≥65% reviewer-PR judgments prefer C_llm. **Cleared.**

Gemini correctly identified C_llm as LLM-generated in all 5 PRs (blinding failure), yet still preferred C_llm in 4/5. Preference is not explained by anti-LLM bias.

## P2 (trajectory classification for C_llm): 20% past, 60% short, 20% wrong

Prereg targets: past ≥ 50% of active trials, wrong < 20%. **Past is below threshold (20% vs 50%).** Wrong is at the boundary.

## P4 (some refactors will make things worse): confirmed

PR 25101 is a clean wrong-direction trial. Reviewer rationale: "Candidate A introduces unnecessary and out-of-scope structural changes to the logic inside `complete-task.ts`." The LLM extended the refactor into complete-task.ts when the intent was just `execute()` signature consolidation. C_final had reverted similar changes during review — so the LLM repeated a mistake reviewers had explicitly pushed back on.

## Scalar vs reviewer disagreement

Scalar classification (mean cognitive complexity):
- Past C_final (Δ < -0.05): 2/5 (24437, 24483)
- Boundary (−0.05 ≤ Δ ≤ 0): 3/5 (24489, 24623, 25101)
- Clear wrong: 0/5

Reviewer classification:
- Past: 1/5 (24483)
- Short: 3/5 (24437, 24489, 24623)
- Wrong: 1/5 (25101)

Agreement: 1/5 (24483 past on both).

The 3 scalar-boundary cases collapsed to 2 short + 1 wrong under reviewer judgment. The 2 scalar-clearly-past cases collapsed to 1 past + 1 short. The scalar tends to overestimate complexity improvements relative to reviewer taste, consistent with the prereg's concern about scalar reliability at small deltas.

## Blinding failure: 5/5

Gemini identified C_llm as LLM-generated in every trial. Identifying signals cited:
- "Aggressive destructuring, extracting local variables for repeated property accesses" (24483)
- "Classic LLM behavior by DRYing up the ToolConfirmationMessage code" (24623)
- "ES6 shorthand... and clean interface fulfillment" (25101)

The LLM's refactoring moves have distinctive structural signatures that gemini can pattern-match. This is a serious validity concern for the test set. Possible mitigations:
- Use multiple reviewer models
- Add stylistic post-processing to normalize surface features
- Report blinding-check results prominently and accept the floor on what blind comparison can measure

## Reviewer-preferred C_final relative to C_test (implicit via trajectory)

From the C_test trajectory assignments:
- 24437: short
- 24483: short
- 24489: wrong — C_test has "3000+ lines of out-of-scope eval and telemetry changes that C_final correctly removed"
- 24623: wrong — "both contained many out-of-scope files that C_final cleanly removed"
- 25101: past — "B shares exact regex artifacts with C_final... likely the human's initial draft before reviewers requested reverting the out-of-scope format change"

In 2 of 5 PRs, reviewers (in the original PR lifecycle) removed out-of-scope work from C_test → C_final. That's context the LLM doesn't have — it can only refactor what's in the diff, not reject out-of-scope work that was already included in C_test.

## Next steps

1. Lock pilot decisions per prereg §Pilot Decisions (complexity tool/version, reviewer criteria, boundary δ, C_random specifics, expansion trigger, PR bounds).
2. Address blinding failure: consider style normalization or multi-reviewer pooling with majority vote.
3. Expand to full primary test set (10 more PRs from the remaining 84 eligible candidates) with locked protocol.
