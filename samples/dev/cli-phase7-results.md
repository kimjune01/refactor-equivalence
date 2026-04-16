# Phase 7 blind review — cli/cli batch (3 PRs)

n=3 PRs, n=1 reviewer (gemini 3.1 pro preview). Secondary repo pilot.

## Per-PR results

| PR | A= | B= | Choice | Preferred | C_llm traj | C_test traj | Correctly ID'd C_llm as LLM | Notes |
|----|----|----|--------|-----------|------------|-------------|------------------------------|-------|
| 12567 | c_test | c_llm | B | **C_llm** | wrong | short | no (blinding JSON malformed) | Phase 1 preferred but phase 2 "wrong" — contradictory |
| 12695 | n/a | n/a | auto | **C_test** | wrong | — | n/a | **No-op trial** (tests fail) |
| 12696 | c_test | c_llm | B | **C_llm** | short | "exact" | yes | C_test ≡ C_final on scope (post-test commit touched tests only) |

## P3 (merge-readiness): 2/3 = 67%

Prereg target: ≥65%. **Cleared by one vote.** No-op trial auto-scored as reviewer-prefers-C_test.

## P2 (trajectory for C_llm): 0/3 past, 1/3 short, 2/3 wrong

All 3 non-past. 12567's "wrong" classification is internally inconsistent with its phase 1 preference (gemini preferred C_llm yet classified it as wrong-direction) — likely a review-quality issue, not a clean signal. The no-op auto-scores as wrong per prereg.

## Blinding

- 12567: phase 3 JSON malformed (empty array); cannot assess
- 12696: blinding failed — gemini correctly ID'd B=c_llm and inferred A=c_final (because A was byte-identical to C_final on the measured scope)

## No-op rate: 1/3 = 33%

Above gemini-cli's 0% but within 40% futility threshold. Combined pilot (gemini-cli + cli/cli): 1/8 = 12.5%.

## Anomalies for v2 consideration

1. **PR 12696's degenerate scope** — C_final's only post-test change was a test file, which is outside the measured scope. The measured-scope C_test ≡ C_final for this PR, so the trajectory classification reduces to "did the LLM stay at or below C_test?" rather than "did it reach or pass reviewer-accepted changes?" Two options for v2: (a) tighten inclusion criteria to require post-test revision ON scope files, not just any file, (b) report such PRs separately.

2. **Contradictory phase 1/phase 2 on PR 12567** — gemini preferred C_llm on merge-readiness but classified it wrong-direction relative to C_final. Suggests the classification task is cognitively different from the forced-choice and reviewers may not reconcile them. The prereg already treats Phase 1 (P3) as primary; this is another datapoint supporting that.

3. **Malformed phase 3** on PR 12567 — gemini returned an empty array where the bundle specified an object. The gemini-reviewer protocol should validate JSON structure and re-run on format violations. Post-pilot tooling item.

## Interpretation

The P3 pass at 2/3 is encouraging but thin; 3-PR samples can't distinguish "LLM helps" from "noise around parity." Even the wrong-direction rate 2/3 (67%) is within the parity envelope at n=3 (confidence interval is wide).

Real signal worth noting: 12567 had a public API break (CopilotActorLogin → CopilotAssigneeLogin) that the LLM didn't restore as the spec said to. Reviewers would reject this in practice; gemini's "wrong direction" classification plausibly reflects that. This is a real slop-slope datum — an LLM refactor that *passes tests* but breaks public API.
