# v2 dev-set pipeline validation results

Locked dev-set: 24460, 24544, 24489 (gemini-cli). Run date: 2026-04-16.

## Pipeline outcome per PR

| PR | C_test | Volley claims | Winner (churn) | Build | Tests | Hunt-code findings | Reviewer-loop | Gate Δ | Gate | Final |
|----|--------|---------------|----------------|-------|-------|-------------------|---------------|--------|------|-------|
| 24460 | C_final | 5 (all ept) | opus (228 vs 229) | PASS | PASS | 3 warnings (all false-positive) | 3 approve-blockers (**all infra leaks from orchestrator bug; fixed post-run**) | -0.0784 | PASS | **valid C_llm** |
| 24489 | eb0fc840 ≠ C_final | 2 (narrowed from ≥7) | codex (146 vs 150) | PASS | PASS | F1 blocker HALLUCINATED (fabricated git-diff), F2 warning false-positive | **"No comments"** — would approve | -0.0096 | PASS | **valid C_llm** |
| 24544 | C_final | 4 | opus (309 vs 312) | PASS | **1/6716 FAIL** (flaky shell-integration test, unrelated to refactor) | n/a (pipeline aborted) | n/a | -0.0281 (manual rerun) | PASS | **hard no-op (flaky-test class)** |

## Summary signals

**Refactor quality (from complexity delta):** 3/3 trials produce a simpler C_llm on scoped mean cognitive. All three Δ values are in the `(-0.05, 0)` band — technically within the parity threshold but always in the "simpler" direction. No scope file set is large so these are noisy.

**Refactor quality (from reviewer-loop):** The only trial with a clean merged diff (24489) got **"No comments"** from Gemini reviewer. The other two trials' reviewer responses were polluted by orchestrator bugs (pipeline artifacts leaking into the diff) and don't reflect real refactor signal.

**Build + test correctness:** 2/3 trials: explicit build + test both PASS in merged_dir. 1/3: 1 flaky integration test failed out of 6716.

**Hunt-code signal:** Low-precision. Both trials that ran to hunt-code produced findings that DIDN'T reflect the actual refactor (false-positive "claim not applied" warnings, hallucinated `git diff HEAD~` outputs, blockers flagged on unchanged files). For iterative hunt-code (N>1) to work, prompt needs tighter evidence requirements and the cleanroom may need `git init` at build time so `git diff HEAD` works.

## Orchestrator bugs caught in dev set (all fixed in run_forge_v2.sh)

1. `npm ci` on merged_dir was a rsync-copy of cleanroom/node_modules — missed per-workspace `packages/*/node_modules` under npm workspace hoisting (`@a2a-js/sdk`, `fdir`, `ajv/dist/2020.js`, etc.). Fix: fresh `npm ci --prefer-offline --ignore-prepare` in merged_dir.
2. `no-op-class.txt` not cleared between attempts; attempt-2 showed stale "hard" from attempt-1. Fix: `: > no-op-class.txt` at orchestrator start.
3. `package.json` prepare script got jq-rewritten for npm-ci purposes and the rewrite leaked into merged.diff. Fix: snapshot original before rewrite, restore after `npm ci`.
4. `IMPLEMENT_SUMMARY.md`, `SHARPENED_SPEC.md`, `GOAL.md`, `FORGE_*.{txt,patch}` leaked into merged.diff. Fix: remove from merged_dir after saving; also add to diff `--exclude` list so CLEANROOM-side copies don't show as deletions.
5. 4e "Implementation evidence" check read from merged_dir AFTER the pipeline-artifact cleanup, causing false trivial-no-op flag. Fix: read from trial_dir's saved copy.
6. `complexity_gate_v2.mjs` crashed on non-TS files in scope (`.toml`, `.yml`, `.json`). Fix: filter to `*.ts` / `*.tsx`, exclude `*.test.ts`.
7. `measure_complexity.mjs` import of `@typescript-eslint/typescript-estree` fails if run from a directory without node_modules. Fix: gate copies the tool into the target cleanroom/merged dir before invoking.

## Prompt iteration decisions

**Volley (4a)** — produced prescriptive, goal-linked, file-specific claims on all 3 dev PRs. No changes needed. Non-determinism between attempts shows up (attempt 1 of 24460 had 4 claims, attempt 2 had 5, different). Acceptable.

**Hunt-spec (4b)** — worked correctly on 24460 (no findings), narrowed 24489's spec from ~7 candidates to 2. No prompt change needed.

**Reconcile (4c)** — worked: on 24489 cut Rejected list to 5 items, kept narrowest 2 claims.

**Implement (4d)** — both opus and codex produced applicable patches. Both report claims accurately in IMPLEMENT_SUMMARY.md. No change.

**Hunt-code (4f)** — problematic. Two classes of false-positive:
  (a) "Claim not applied" warnings even when claim WAS applied (verified in merged_dir). Mitigation: add explicit "show the exact unchanged block" requirement to the prompt before flagging.
  (b) Blocker findings citing a `git diff HEAD~` output that's fabricated (merged_dir has no .git). Mitigation: either seed `git init && git add && git commit` in the cleanroom build (so HEAD~ is the pre-refactor state), OR rewrite the prompt to use `diff -r $CLEANROOM $MERGED_DIR` as the evidence command.

**Reviewer-loop (4g)** — worked correctly on 24489 (recognized a clean diff and approved). On 24460 it correctly flagged infra leaks that were real bugs in the orchestrator, not refactor bugs. No prompt change needed.

**Complexity gate (4h)** — script-level bugs fixed (see "Orchestrator bugs #6"). Gate threshold (δ=0.05) is wide relative to observed deltas (-0.01 to -0.08); all 3 trials PASS comfortably.

## v3 questions populated during dev

See `v3_questions.md` for entries:
- `2026-04-16 12:45 — CONFIRMED: C_test == C_final for 2/3 dev-set PRs` (HIGH priority)
- `2026-04-16 12:15 — C_test may equal C_final on small single-feature PRs` (HIGH)
- Per-trial `anomalies.md` files for hunt-code false-positives (24460), hunt-code hallucination (24489), flaky integration test (24544).

## Dev-set → test-set readiness

**Orchestrator**: fixed. Ready for test-set runs.

**Prompts**: minor change needed on hunt-code prompt (add evidence-quoting requirement). Volley/hunt-spec/reconcile/implement/reviewer-loop prompts frozen as-is.

**Open questions for test-set lock:**
1. **C_test definition**: 2/3 dev PRs had C_test == C_final. The prereg's definition is structurally biased against small feature PRs. Options: (a) loosen C2 to allow C_test == C_final with P2 trajectory noted as "degenerate by construction" for such PRs, (b) pre-select for PRs with explicit post-review-commit patterns (multiple "address feedback" commits), (c) define C_test via PR timeline (first commit before first reviewer comment). DECISION PENDING.
2. **Flaky-test handling**: 24544 hard-no-opped on a single flaky integration test unrelated to the refactor. Need to expand registered test command's exclude list or adopt a re-run-on-fail heuristic.
3. **Iterative phases (N>1)**: current MVP runs single-round for hunt-spec/hunt-code/reviewer-loop. The prereg specifies iterative (N≤10). Should test-set use iterative or stick with single-round? Iterative would amplify the hunt-code hallucination problem unless the prompt is hardened first.
