# Cross-repo pilot results — gemini-cli, cli/cli, fastapi

Three repos × 3 languages (TypeScript, Go, Python). n=17 PRs extracted, 14 eligible, 11 active non-no-op trials.

## Per-repo rollup

| Repo | Lang | PRs selected | Eligible | Active C_llm | Past | Short | Wrong | No-op |
|------|------|--------------|----------|--------------|------|-------|-------|-------|
| gemini-cli | TS | 5 | 5 | 4 | 1 | 3 | 1 | 0 |
| cli/cli | Go | 13 | 9 | 7 | 1 | 4 | 2 | 2 |
| fastapi | Python | 3 | 2 | 0 | 0 | 0 | 1 | 1 |
| **Total** | | **21** | **16** | **11** | **2** | **7** | **4** | **3** |

Secondary-expansion trigger hit on cli/cli (first batch showed 2/3 wrong-direction). Expanded to 10 per pilot decision #6 (9 eligible in practice after 4 exclusions).

## Primary outcomes (aggregate)

| Measure | gemini-cli | cli/cli | fastapi | Combined |
|---------|-----------|---------|---------|----------|
| P3 (reviewer prefers C_llm) | 4/5 = 80% | 7/9 = 78% | — | 11/14 = 79% (excl. fastapi) |
| P2 past trajectory | 1/5 = 20% | 1/9 = 11% | 0/2 = 0% | 2/16 = 12.5% |
| P2 wrong trajectory | 1/5 = 20% | 2/9 = 22% | 1/2 = 50% | 4/16 = 25% |
| No-op rate | 0/5 = 0% | 2/9 = 22% | 1/3 = 33% | 3/17 = 18% |

## Cross-repo findings

### 1. P3 holds across gemini-cli and cli/cli, untested on fastapi
Reviewer preference for C_llm over C_test was cleared above the 65% threshold on both TypeScript and Go repos. fastapi was not review-tested because 2/3 PRs were excluded or no-op before Phase 7.

### 2. P2 past-trajectory consistently below improvement threshold
Pre-registered 50% threshold for "past C_final" is not met on any repo. Combined 12.5%. The parity null (R8) would predict ~30-40% past under equivalence, so this result is below parity too — suggesting the LLM pipeline consistently lands *just short of* what reviewers negotiated. Not wrong direction, just short.

### 3. Wrong-direction rate correlates with language
- TypeScript (gemini-cli): 20% wrong
- Go (cli/cli): 22% wrong
- Python (fastapi): 50% wrong (small n)

Combined 25%, above the registered P2 threshold of <20%. The TypeScript / Go results are at the threshold; Python pushes it over.

### 4. Reviewer additive bias varies by repo culture
- gemini-cli (Google team, active review): C_final > C_test on LOC in 5/5 PRs
- cli/cli (GitHub team, surgical): C_final ≈ C_test on LOC (+5, 0, -3 observed on batch 1 sample)
- fastapi (solo maintainer): mostly small edits in the scoped window

The "reviewer adds LOC" pattern from gemini-cli does not generalize to cli/cli or fastapi. Review culture shapes the scope-expansion signal.

### 5. Python environment setup cost is ~10x Go or TypeScript
- Go: `go test ./...` out of the box after `git clone`
- TypeScript: `npm ci` once per cleanroom (~20s warm)
- Python: 90+ min iterating on dependencies (pyjwt, pwdlib, typer, starlette, orjson, pyyaml, pytest plugins, etc.) — and still needed deselects for 2 flaky tests

This limits feasibility across Python-ecosystem secondary repos at pilot scale.

## Forge pipeline failure modes observed

1. **Reconcile-failure-to-reject** (cli/cli 12695): hunt-spec predicted a test failure, reconcile didn't reject the problematic claim. No-op resulted.

2. **Stale cross-package test fixture** (cli/cli 12884): PR's scope-refactor renamed a symbol that a test file in a *different* package asserted against. Per prereg, we don't touch tests. No-op.

3. **Build-fail at C_final from squash-merge** (cli/cli 12444, 12859): PR HEAD not self-contained; main post-merge added missing symbols. Excluded at candidate selection.

4. **C_test == C_final** (cli/cli 12774, 12846; fastapi 14978): no post-tests-pass source-code revision in the allowed edit set. Excluded.

5. **Descriptive-vs-prescriptive volley** (fastapi 14962): codex produced preservation claims instead of refactoring claims. Opus then made no changes because claims described existing state. No-op.

6. **Refactor that increases complexity** (fastapi 15022): codex applied claims, tests pass, but scalar complexity went UP +0.06. Clean scalar slop-slope datum.

7. **Public API break masked by tests** (cli/cli 12567): renamed `CopilotActorLogin` → `CopilotAssigneeLogin` without alias; tests didn't exercise the export. Phase 1 preferred C_llm but trajectory-classified wrong. Real slop-slope in the sense reviewers would reject in practice.

## Parity null (R8) re-evaluation

Under the retro R8 framing:
- **Parity envelope**: 25-45% past, 40-55% short, 10-20% wrong
- **Observed combined**: 12.5% past, 43.75% short, 25% wrong
- **Interpretation**: past is below parity (LLM underperforms reviewer), short is within parity, wrong is at parity upper bound.

The "past" underperformance (12.5% vs 25% lower bound of parity) is the most informative signal. LLMs in forge-wrap consistently fail to *exceed* reviewer judgment on simplification. They *match* reviewer judgment in 43% of trials (short) but rarely beat it.

## What the pilot cannot resolve

1. **Whether the gap is fundamental or fixable**: would a tighter spec language, stronger hunt-code, or multi-round forge iterations close the past-trajectory gap? Retro R7 suggested hunt-spec needs to be strictly adversarial; we observed reconcile-failure-to-reject twice (12695, plausibly 14962). 

2. **Single-shot ablation**: per retro R1, not a hypothesis we committed to. Practitioner prior already predicts single-shot worse than forge-wrapped. Not informative to run.

3. **Cross-repo sample size for any firm conclusion**: 16 PRs across 3 repos is feasibility scale, not analysis scale. Per prereg, primary test set should be 15 PRs from gemini-cli alone.

## Secondary repos still pending

- **ruff** (Rust): not run. Rust toolchain install + cargo compile per commit was judged too expensive given the fastapi setup cost and remaining time.
- **django** (Python): not run. Expected similar setup cost to fastapi.

Both can be added in a follow-up. Per prereg, each is a 3-PR batch initially with expansion trigger.

## Artifacts

Per-PR trail in `samples/dev/<repo-pr>/`:
- `volley-round1.md` — initial sharpened claim list
- `hunt-spec-findings.md` — adversarial review of claims
- `sharpened-spec-final.md` — post-reconcile spec
- `hunt-code-findings.md` (where run)
- `c_llm_diff.patch` — final C_llm refactor
- `review-bundle.md` + `review-phase{1,23}.json` (for trials reaching Phase 7)

Cross-cutting summaries:
- `samples/dev/pilot-results.md` — gemini-cli
- `samples/dev/cli-expansion-results.md` — cli/cli expansion
- `samples/dev/fastapi-results.md` — fastapi
- `samples/dev/phase7-results.md` — gemini-cli Phase 7
- `samples/dev/cli-phase7-results.md` — cli/cli Phase 7
