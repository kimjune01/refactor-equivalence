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

(populated during v2 execution)

---

## Pre-v2 seed entries (added during v2 prereg drafting)

### Pre-seed 5 — model-strength curve

**Trigger**: speculation during v2 design — older/weaker models likely worse at forging because each stage requires nontrivial instruction-following.

**v2 evidence (so far)**: v2 fixes the model lineup at 2026-vintage SOTA (Opus 4.6, Codex GPT-5.4, Gemini 3.1 Pro). No model-strength variation tested.

**v3 hypothesis**: substituting weaker models (Sonnet 4.5, GPT-4-class, Gemini 1.5) at one or more forge stages would degrade the rate. Open question is the SHAPE of the degradation: linear with model size, threshold at some capability level, or stage-specific (e.g., reviewer is robust but generator collapses).

**Provisional priority**: low — practitioner prior already says "weaker → worse." A formal trial may not move the posterior much beyond confirming the prior. But useful if v2 results need to be hedged for less-capable model deployments.

### Pre-seed 6 — refactor-bench positioning (pipeline-bench, not model-bench)

**Trigger**: v2's design is benchmark-shaped — fixed PR set, reproducible pipeline, pre-registered scoring, multi-language, real merged PRs as ground truth.

**Important constraint**: forge is explicitly multi-model (opus + codex + gemini per stage). A score reflects all three roles working together, not any one model. So a "refactor-bench" derived from v2 is a **pipeline-evaluation bench**, not a model-evaluation bench. Audience is practitioners building agent pipelines, not model developers training new models.

**v2 evidence (so far)**: not yet observable. Will know after v2 ships whether the pipeline is reproducible enough by external practitioners (cost, complexity, scaffolding).

**v3 hypothesis**: a "refactor-bench" version positioned explicitly as a *pipeline* evaluation benchmark, with:
- Versioned snapshots (v2.0 frozen, v2.1 adds N PRs every 6 months to fight contamination)
- External pipeline leaderboard (e.g., "forge-X scored Y% on refactor-bench-2.0")
- Pipeline substitution: practitioners swap their orchestration (different stages, different models per stage, single-shot vs multi-stage) into the generator/reviewer slots
- Composite score from P1/P2/P3 rates, plus per-stage diagnostics (hunt-spec defect-find rate, reviewer-loop convergence, complexity-gate trip rate)

Risks: contamination (pipelines train against the bench's PR set), Goodhart targets, single-composite score loses nuance, expensive per-trial.

Mitigations baked into v2 design: pipeline wrapping makes single-shot training harder to game, reviewer-loop iteration measures address-quality not just first-shot, survivorship + size restriction limits scope of claims, multi-language coverage prevents single-language overfit.

**Provisional priority**: medium if v2's pipeline turns out reproducible by external practitioners. Smaller audience than "model leaderboard" but a real one — pipeline orchestration is its own emerging category (forge, agentic frameworks, code-rewriting agents).
