# PREREG_V2 checklist audit (codex hostile-review)

Run date: 2026-04-16
Auditor: codex GPT-5.4, read-only, against the [20-question prereg checklist](https://june.kim/blog/2026-04-14-prereg-audit/).

## Per-question verdict

1. **PASS**: Sampling is preregistered by repo, eligibility, size bounds, exclusions, and candidate-pool logging.
2. **PARTIAL**: Collection is mostly fixed, but batch expansion/repo swaps/per-repo tooling leave adaptive degrees of freedom.
3. **PASS**: Invalidating assumptions are explicitly listed.
4. **PASS**: Mechanism is stated: tests define equivalence class; refactor moves within it; complexity/review judge direction.
5. **PASS**: Population limits, repo/language limits, build-time bias, and survivorship limits are explicit.
6. **PARTIAL**: Within-PR baseline helps, but the treatment is a bundled forge pipeline with no stage isolation.
7. **PARTIAL**: `C_test` is a baseline control, but dropped `C_random` means no control for “any change” vs simplification.
8. **PARTIAL**: Competing explanations are named, but mostly not tested between.
9. **N/A**: No assignment to human subjects/conditions; design is within-PR against fixed snapshots.
10. **PASS**: P1/P2/P3 thresholds and wrong-direction criteria give scorable refutation points.
11. **PARTIAL**: Thresholds are concrete, but P3 is softened by Gemini pre-approval bias and P1 lacks a noise/change control.
12. **PASS**: Paradigm assumptions about merge-readiness, `C_final`, metrics, and context are explicit.
13. **PASS**: Outcomes can distinguish improvement, parity, metric-only gains, reviewer-only gains, and slop-slope.
14. **PARTIAL**: Artifact risks are named, but Gemini reuse/blinding failure remain baked into the primary outcome.
15. **PARTIAL**: Causal claim is narrow and intervention is defined, but component confounding inside the forge bundle remains.
16. **PARTIAL**: Discusses sample/flexibility/prior, but no formal power and secondary `n=3` batches are weak.
17. **PARTIAL**: Severity is helped by thresholds/build/tests/review, but tests can pass false and P3 can pass via reviewer-loop overfit.
18. **PASS**: Strong full-trail commitment: data, exclusions, logs, prompts, diffs, measurements, deviations, nulls/no-ops.
19. **PASS**: Predictions are timestamped, numeric, denominator-defined, and scorable.
20. **PARTIAL**: Peeking/expansion is acknowledged and logged, but no anytime-valid inference or fixed max sample size.

**Top 5 Issues**

1. **Q20: Adaptive expansion without valid sequential inference.** “Stop when signal is clear” plus no fixed maximum sample size can make thresholds look cleaner than they are.
2. **Q14/Q11: Gemini pre-approval bias.** Gemini helps shape `C_llm` before later judging it, so P3 can become “Gemini likes what Gemini already approved.”
3. **Q8: Alternatives are acknowledged, not adjudicated.** Dev-set overfit, model contamination, size effects, and Gemini-taste optimization can all explain positives.
4. **Q6/Q7: No meaningful alternative-intervention control or ablation.** Dropping `C_random` and testing the whole forge bundle means P1 is direction-only and no stage’s marginal value is identifiable.
5. **Q16: Weak inferential base.** 27 target trials, `n=3` secondary batches, no formal power, and flexible expansion make P2/P3 especially fragile.
tokens used
27,536
1. **PASS**: Sampling is preregistered by repo, eligibility, size bounds, exclusions, and candidate-pool logging.
2. **PARTIAL**: Collection is mostly fixed, but batch expansion/repo swaps/per-repo tooling leave adaptive degrees of freedom.
3. **PASS**: Invalidating assumptions are explicitly listed.
4. **PASS**: Mechanism is stated: tests define equivalence class; refactor moves within it; complexity/review judge direction.
5. **PASS**: Population limits, repo/language limits, build-time bias, and survivorship limits are explicit.

## Top 5 issues

1. **Q20: Adaptive expansion without valid sequential inference.** "Stop when signal is clear" plus no fixed maximum sample size can make thresholds look cleaner than they are.
2. **Q14/Q11: Gemini pre-approval bias.** Gemini helps shape `C_llm` before later judging it, so P3 can become "Gemini likes what Gemini already approved."
3. **Q8: Alternatives are acknowledged, not adjudicated.** Dev-set overfit, model contamination, size effects, and Gemini-taste optimization can all explain positives.
4. **Q6/Q7: No meaningful alternative-intervention control or ablation.** Dropping `C_random` and testing the whole forge bundle means P1 is direction-only and no stage's marginal value is identifiable.
5. **Q16: Weak inferential base.** 27 target trials, n=3 secondary batches, no formal power, and flexible expansion make P2/P3 especially fragile.

## v2 response

Cheap fixes applied to PREREG_V2.md:
- **Q20**: hard cap added (25 primary, 10 secondary). Stop-when-confident still applies, but bounded.
- **Q16**: back-of-envelope power statement added (~62% for P3, ~58% for P2 past).
- **Q8**: each competing explanation now annotated with how it would be adjudicated in v3.

Accepted limitations (no fix in v2):
- **Q6/Q7/Q15**: bundled-pipeline confound. Documented in "what this would show" (positive result supports forge bundle, not generic refactor pass).
- **Q11/Q14**: Gemini pre-approval bias. Acknowledged in 3 places.
- **Q17**: severity. Same.
- **Q20 sequential inference machinery**: deferred to v3 if the design moves toward formal hypothesis testing.

## v3 design implications

If v2 produces ambiguous results, v3 may need:
- A held-out repo for adjudicating dev-set overfit (Q8 #1)
- A counterbalanced Phase 2 design (Q8 #3)
- Sonnet/GPT-5 secondary review on a sample (Q8 #5)
- An ablation arm with single-stage forge for Q6/Q7
- Anytime-valid sequential testing (Q20)
