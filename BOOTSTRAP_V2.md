# Bootstrap prompt — v2

Paste this into a fresh Claude Code session to kick off the v2 run.

---

I'm running v2 of an experiment: does a forge-wrapped LLM refactoring pass improve merge-readiness of large brownfield PRs? Everything is in `~/Documents/refactor-equivalence`.

**Read in this order to get up to speed:**

1. `PREREG_V2.md` — the registered v2 protocol. This is the contract.
2. `worklog/WORK_LOG.md` — the running trail. Tail the last 50 lines.
3. `improvements.md` — the v1 → v2 design rationale (skim to understand why v2 looks the way it does)
4. `v3_questions.md` — running backlog of v3-prep questions (read so you know what to log into it as you observe things)

**Use `/worklog` after every commit, decision, deviation, or direction change.** The work log is the trail and we publish it alongside results.

## v2 design in a paragraph

Forge pipeline: goal-anchored volley (PR description + linked issue as goal, diff as artifact) → iterative hunt-spec with mandatory-reject on blockers → reconcile → blind-blind-merge with whole-model selection (smaller-total-churn wins) → iterative hunt-code with full build/tests → Gemini reviewer-loop → ship-time complexity gate (δ=0.05 on scoped mean cognitive). All iterative loops cap at N=10. Single reviewer (Gemini 3.1 Pro) throughout, in-pipeline + Phase 7. Eligibility floor 500 source lines = blind-blind precondition. No single-agent path. Sample: 21 minimum (15 primary gemini-cli + 2×3 secondary cli/cli + ruff). 25 primary / 10 secondary hard caps. Python repos dropped — open question for v3.

## Hard rules to follow

- **Analysis is descriptive-only.** No formal hypothesis tests (Wilcoxon, mixed-effects, t-tests, etc.). Report rates, deltas, distributions. Compare against pre-registered thresholds. Don't run formal tests even if the rate looks close to threshold.
- **Audience is Dexter Horthy / harness developers.** Practitioner-confident tone, not academic-cautious. "Forge preferred at 78%, parity is 50%" not "we observed 78% but cannot generalize without further study."
- **Pre-registered recommendation criterion:** ≥65% prefer-C_llm = "worth running"; 60-65% = "depends on cost"; 40-60% parity = "do not recommend"; <40% = "counter-indicated." Don't soften coin-flip results.
- **Dev-env timebox: 2 hours per repo to first passing build at C_final.** Hit timebox → drop the repo, substitute next eligible. No infrastructure-debugging iteration.
- **Trail commitment is exhaustive.** Every artifact per trial saved under `samples/<set>/<repo>-<pr>/`: goal text, inputs, volley/hunt round transcripts, blind-blind diffs, merge decisions, complexity gate JSON, reviewer-loop transcripts, final C_llm + measurements, Phase 7 review JSONs. Plus per-trial `anomalies.md` + `deviations.md` populated in-flight.
- **No-self-review:** Opus and Codex generated; only Gemini reviews. Acknowledged: Gemini is in-pipeline AND Phase 7, pre-approval bias is documented in 3 places.

## Three agents, four roles

| Agent | Role | Invocation |
|-------|------|------------|
| Claude Opus 4.6 | Generator (blind-blind), implementer in reviewer-loop | `claude` (this session) |
| Codex GPT-5.4 | Generator (blind-blind), adversarial reviewer at hunt-spec + hunt-code | `codex exec -c model="gpt-5.4" -s danger-full-access` |
| Gemini 3.1 Pro Preview | Reviewer (in-pipeline + Phase 7) | `gemini -m gemini-3.1-pro-preview --approval-mode yolo` (zshrc alias) |

## Immediate next step

Per v2 protocol:

1. **Pull dev-set candidates** from google-gemini/gemini-cli (post 2025-10-01, 500-5000 source lines at C_test, post-exclusion).
2. **Run pre-selection feasibility checks** (test command passes at C_final; source-only C_test→C_final diff is non-empty; ≥1 file in scope after exclusions).
3. **Extract `C_test` snapshots** for the dev set using `scripts/find_c_test.sh`.
4. **Build cleanrooms** using `scripts/build_cleanroom.sh`.
5. **Run the v2 forge pipeline** on dev-set PRs to validate the design. Iterate prompts on dev only — freeze before test set.

When dev set is converged, freeze prompts and start the test set.

## v2 expected duration

- Dev set: 3-5 PRs from gemini-cli, ~1 day
- Test set primary: 15 PRs gemini-cli, ~3-5 days
- Test set secondary: 3 PRs cli/cli + 3 PRs ruff, ~2-3 days each
- Phase 7 reviews: ~half-day total (Gemini single-reviewer per trial)
- Analysis + writeup: ~1-2 days

If a secondary repo dev-env hits the 2-hour timebox, drop and proceed without it.

## Files you will create / update

- `samples/v2/<repo>-<pr>/` — per-trial artifacts (full pipeline trail)
- `samples/v2/candidates-<repo>.json` — pre-selection logs
- `samples/v2/exclusions.md` — per-PR exclusion log
- `failure_modes_v2.md` — built at end-of-experiment, mapping observed failures to v2's anticipated 7
- `v3_questions.md` — append in-flight observations as `### YYYY-MM-DD HH:MM — <title>` entries
- `worklog/WORK_LOG.md` — log every commit / decision / direction change

Good luck.
