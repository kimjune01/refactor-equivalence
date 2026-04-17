# Reviewer task instructions — v2

Instructions given to the blind reviewer (Gemini 3.1 Pro Preview, single reviewer per trial) for Phase 7 evaluation.

Construct being measured: **model-reviewer merge-readiness preference** — would a Gemini-class reviewer approve this diff for merge? This is not identical to human reviewer judgment; it is a proxy for what model-judges find reviewable. Renamed from v1's "human merge-readiness" per PREREG_V2.md (codex hostile-review concern #1).

## Context the reviewer sees

- Goal anchor: PR title + PR body + linked issue title/body (where available). Mirrors the volley's goal anchor.
- Two unlabeled diffs (Version A and Version B) from the same base commit (`C_base`).
- Label: "Both versions pass the project's test suite. Tests passing does not mean behavior is correct — use your judgment."

Reviewer does NOT see: original PR discussion, review comments, commit history after C_test, which version is LLM-generated, which version was final during Phase 1, other reviewers' judgments.

## Phase 1 — Forced choice

```
Assuming tests pass, which version would you approve for merge?
```

Reviewer must pick one version. Also record:
- Semantic concerns for each version (behavior that might be wrong despite passing tests)
- Brief rationale (1-2 sentences)

## Phase 2 — Trajectory classification

Reveal a third version labeled "the version reviewers accepted" (this is `C_final`).

Reviewer classifies **only the LLM-generated version** (`C_llm`) against `C_final`:

- **Past `C_final`:** simpler than the accepted version; reviewer would still approve it. Strictly better, by reviewer judgment.
- **Short of `C_final`:** improved over `C_test`, but leaves complexity the accepted version removed. Better, not as good.
- **Wrong direction:** no meaningful improvement; worse complexity, worse merge-readiness, or semantic risk.

## Post-ranking blinding check

After submitting judgments, reviewer answers:
- Did you believe either Phase 1 version was the final accepted version?
- Did you believe either was LLM-generated?
- Neither / couldn't tell?

## Invocation

```bash
gemini -m gemini-3.1-pro-preview --approval-mode yolo "<rendered task prompt>"
```

Output JSON per phase into:
- `{TRIAL_DIR}/phase7/review-phase1.json` (forced choice + rationale + semantic concerns)
- `{TRIAL_DIR}/phase7/review-phase23.json` (trajectory + blinding check)

## v2 changes from v1

- Single reviewer (Gemini). No Sonnet/GPT-5 calibration. Codex already adversarial in-pipeline (4b, 4f).
- Goal anchor added to the reviewer's context (same as volley's).
- Construct re-labeled: "model-reviewer merge-readiness" (was "human merge-readiness").
- Pre-approval bias acknowledged: Gemini is in-pipeline (4g) AND Phase 7. Documented in 3 places (PREREG_V2.md, BOOTSTRAP_V2.md, and this file).
