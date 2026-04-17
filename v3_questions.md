# v3 questions backlog

Running list of "if v2 confirms / refutes X, then v3 should investigate Y" observations. Populated by the experimenter as observations arise during v2 execution. Empty at v2 registration; grows during the run.

Format per entry:

```
## YYYY-MM-DD HH:MM — <short title>

**Trigger**: what observation prompted the question
**v2 evidence (so far)**: relevant pilot or in-flight data
**v3 hypothesis or design question**: what to investigate next
**Provisional priority**: low / medium / high
```

---

## 2026-04-16 (pre-v2 seed entries from v1 pilot)

### Pre-seed 1 — does single-shot match forge-wrapped on small refactors?

**Trigger**: v1 pilot showed opus + codex byte-identical on PR 24437 (5 files, ~30 LOC). Blind-blind earned no information on small diffs.

**v2 evidence (so far)**: v2 raises eligibility floor to 500 LOC, so this question is largely moot for the v2 corpus. But for shipping forge as a recommendation, the answer matters: when can practitioners skip blind-blind?

**v3 hypothesis**: blind-blind precondition could be auto-tuned by historical convergence on the target repo, not a fixed LOC threshold.

**Provisional priority**: low — v2's 500 LOC floor handles this for the experiment; question only matters for productization.

### Pre-seed 2 — survivorship-filtered C_llm vs rejected-PR C_llm

**Trigger**: R5 acknowledges sampling only merged PRs. The rejected/abandoned PRs are where slop-slope-prone contributors live. v2 doesn't sample them.

**v2 evidence (so far)**: pilot wrong-direction rate 25% on survivors; real-world rate likely higher.

**v3 hypothesis**: a comparison arm sampling closed-without-merge PRs from the same period would directly test "can forge rescue drafts humans gave up on?" High research-value, high reconstruction cost.

**Provisional priority**: high if v2 finds positive results on survivors — strong follow-up. Low if v2 itself is unconvincing.

### Pre-seed 3 — reviewer-loop convergence rate as forge-quality proxy

**Trigger**: pilot didn't run a reviewer loop. v2 will. If it converges in 0-1 rounds on most PRs, the loop is essentially a sanity check; if it iterates 5+ rounds frequently, that signals real reviewer-implementer friction.

**v2 evidence (so far)**: none yet — first observable in v2 dev set.

**v3 hypothesis**: reviewer-loop round count per trial is itself a useful metric ("forge effort") — could be a primary outcome in v3.

**Provisional priority**: medium — populate after v2 dev set runs.

### Pre-seed 4 — spec descriptive-vs-prescriptive failure mode after V1 fix

**Trigger**: pilot's fastapi 14962 had a no-op because volley produced preservation claims. V1 fix in v2 (goal anchor + prescriptive instruction) should eliminate this.

**v2 evidence (so far)**: not tested. v2's first dev-set PRs will reveal whether V1 worked.

**v3 hypothesis**: if V1 still produces descriptive volleys on Python (where fastapi's failure happened), the fix is language-specific not prompt-architectural. v3 may need per-language volley templates with stronger anchoring.

**Provisional priority**: medium — diagnose during v2 dev.

---

## v2 in-flight entries

### 2026-04-16 12:45 — CONFIRMED: C_test == C_final for 2/3 dev-set PRs (24460, 24544)

**Trigger**: extraction on 24460 and 24544 complete. Both have C_test = C_final. 24460 walked 11 commits; all 10 pre-C_final commits fail (6 fail_test, 4 fail_build). 24544 walked 5 commits; all 4 pre-C_final commits fail_test. 24489 in-flight but trending same way.

**v2 evidence (so far)**: 100% of completed dev-set PRs exhibit C_test == C_final. If this extrapolates, entire v2 corpus would be excluded per prereg C2.

**Next action for v2 in-flight**: proceeding to run pipeline anyway using C_test = C_final for dev-set pipeline validation (log as deviation). For test-set decision, need to either (a) revise C_test definition, (b) change PR selection criteria to prefer PRs with refactor-style structure, or (c) loosen C2 to allow C_test == C_final with the trade-off that P2 trajectory becomes degenerate.

**v3 hypothesis or design question**: See 12:15 entry above for the broader question. This confirms the problem is not rare but systematic on feature-PRs in active repos. Design choices:
- Option A: filter selection to PRs with high "late-PR refactor" signal (e.g., multiple "address feedback" commits touching source, not new tests)
- Option B: define C_test as "last commit that builds" rather than "first commit where C_final tests pass"
- Option C: skip C_test concept entirely, use C_base → C_final as the artifact the LLM refactors against (inverts the forge task: "refactor what you think the author should have written")

**Provisional priority**: HIGH. This blocks the v2 estimand. Must decide before test-set lock.

### 2026-04-17 00:00 — Force-push culture eliminates ~90% of OSS repos from C_test extraction

**Trigger**: Screened 21 major repos (TS/Go/Rust) for multi-commit PR branches. Result: ~90% have single-commit branches because contributors amend+force-push during review per "clean history" norms. Repos with multi-commit branches (gemini-cli, cli/cli, biome) are the exception, not the rule — typically Google-style review culture where each push is a separate patchset.

**v2 evidence**: Of 21 repos screened, only 3 had ≥2/5 big PRs with ≥3 commits: gemini-cli, cli/cli, hashicorp/consul. Most popular repos (react, TypeScript, kubernetes, deno, tokio, go-ethereum, cockroachdb) had 0/5.

**v3 design**: Use **GitHub Review API** instead of git commit history to find C_test. The API preserves the exact SHA at each review event (`PullRequestReview.commit_id`) even after force-push. Algorithm: find the SHA at the first `CHANGES_REQUESTED` or `COMMENTED` review event → that's the "pre-review state" → use as C_test. This unlocks EVERY repo regardless of force-push culture.

Fallback: GitHub also stores `refs/pull/N/head` push events via the Events API. Each push updates the ref. The state before the first review-response push is another proxy for C_test.

**Provisional priority**: CRITICAL for v3 viability. Without this, v3 is limited to the same ~5 repos that v2 can access.

---

### 2026-04-16 12:15 — C_test may equal C_final on small single-feature PRs

**Trigger**: In v2 dev-set extraction, the PR-touched *source* code often builds/tests only in the final commits because the C_final test files assert on behavior the feature adds. Intermediate commits FAIL_BUILD (early code doesn't compile) or FAIL_TEST (C_final's tests probe behavior not yet implemented). Observed so far on 24460 (8 of 9 tested commits FAIL_TEST or FAIL_BUILD) and 24489 (4 of 4 tested commits FAIL_BUILD before reaching commits that at least build).

**v2 evidence (so far)**: in-flight; await 24460/24489 final results. If both end up with C_test == C_final, both are excluded per prereg C2 (non-trivial C_test→C_final delta required). Dev-set candidates would shrink; test-set predicted similarly.

**v3 hypothesis or design question**: the prereg's C_test definition ("earliest commit where C_final tests pass") may be pathological for small feature PRs where the feature-tests-first-pass commit IS the review-polished commit. Alternatives to consider for v3: (a) "earliest commit where C_base tests pass and source-change count exceeds N" — captures the spirit of "first-complete draft" without requiring C_final tests; (b) "pre-review state" — use the first commit before the first reviewer comment, inferred from PR timeline; (c) accept C_test == C_final and redefine what we're measuring (forge vs reviewer-signed-off-code).

**Provisional priority**: high if >60% of v2 PRs end up with C_test == C_final — that would invalidate the entire P2 construct. Low if only a minority.

---

## Pre-v2 seed entries (added during v2 prereg drafting)

### Pre-seed 5 — model-strength curve

**Trigger**: speculation during v2 design — older/weaker models likely worse at forging because each stage requires nontrivial instruction-following.

**v2 evidence (so far)**: v2 fixes the model lineup at 2026-vintage SOTA (Opus 4.6, Codex GPT-5.4, Gemini 3.1 Pro). No model-strength variation tested.

**v3 hypothesis**: substituting weaker models (Sonnet 4.5, GPT-4-class, Gemini 1.5) at one or more forge stages would degrade the rate. Open question is the SHAPE of the degradation: linear with model size, threshold at some capability level, or stage-specific (e.g., reviewer is robust but generator collapses).

**Provisional priority**: low — practitioner prior already says "weaker → worse." A formal trial may not move the posterior much beyond confirming the prior. But useful if v2 results need to be hedged for less-capable model deployments.

### Pre-seed 7 — does forge work on Python?

**Trigger**: v1 pilot's fastapi attempt cost ~90 minutes of dependency iteration before tests would run, then both eligible PRs went no-op or wrong-direction. v2 dropped Python entirely (django + fastapi) to keep the primary question (does forge work on TS/Go?) clean.

**v2 evidence (so far)**: not in v2 scope. Open question.

**v3 hypothesis**: with V1 (goal anchor + prescriptive volley) live, the descriptive-vs-prescriptive volley failure on fastapi 14962 may be fixed. Worth re-trying Python in v3 with the v2 design and budget for the dependency-setup cost upfront. django and fastapi are first-pick re-additions; if Python is still infeasible after the setup-cost budget, that's an answer too.

**Provisional priority**: medium — Python is too widely used to leave indefinitely as "too hard." But not blocking v2.

### Pre-seed 6 — refactor-bench positioning (pipeline-bench, not model-bench)

**Trigger**: v2's design is benchmark-shaped — fixed PR set, reproducible pipeline, pre-registered scoring, multi-language, real merged PRs as ground truth.

**Important constraint**: forge is itself a harness — a multi-model orchestration (opus + codex + gemini per stage). A v2 score reflects all three roles working together inside one specific harness implementation, not any one model. So a "refactor-bench" derived from v2 is a **harness-evaluation bench**, not a model-evaluation bench. v2's reported numbers ARE forge's score on the bench; other harness developers can compare their own harness's score against forge's reference number on the same PRs.

Audience: **harness developers** — people building agent orchestration frameworks (forge, Aider, OpenHands, SWE-agent, Cursor's harness, HumanLayer) — not model trainers.

**v2 evidence (so far)**: not yet observable. Will know after v2 ships whether the pipeline is reproducible enough by external practitioners (cost, complexity, scaffolding).

**v3 hypothesis**: a "refactor-bench" version positioned explicitly as a *harness* evaluation benchmark, with:
- Versioned snapshots (v2.0 frozen, v2.1 adds N PRs every 6 months to fight contamination)
- External harness leaderboard (e.g., "forge-X scored Y% on refactor-bench-2.0")
- Harness substitution: harness developers swap their orchestration (different stages, different models per stage, single-shot vs multi-stage) into the generator/reviewer slots
- Composite score from P1/P2/P3 rates, plus per-stage diagnostics (hunt-spec defect-find rate, reviewer-loop convergence, complexity-gate trip rate)

Risks: contamination (pipelines train against the bench's PR set), Goodhart targets, single-composite score loses nuance, expensive per-trial.

Mitigations baked into v2 design: pipeline wrapping makes single-shot training harder to game, reviewer-loop iteration measures address-quality not just first-shot, survivorship + size restriction limits scope of claims, multi-language coverage prevents single-language overfit.

**Provisional priority**: medium if v2's pipeline turns out reproducible by external harness developers. Smaller audience than "model leaderboard" but a real and growing one — agent harness development is an emerging category (forge, Aider, OpenHands, SWE-agent, HumanLayer-style orchestration). A bench that distinguishes good harnesses from sloppy ones serves an unmet need.
