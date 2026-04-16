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
