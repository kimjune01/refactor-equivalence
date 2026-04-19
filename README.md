# refactor-equivalence

## Abstract

We tested whether an autonomous LLM refactoring pipeline can produce merge-ready code from brownfield PRs. 27 trials across 9 open-source repos (TypeScript, Go, Rust). Without iterative review, the pipeline produces code at parity with doing nothing (43% reviewer approval). With iterative review — where an adversarial LLM finds issues, another LLM fixes them, and a reviewer re-evaluates until convergence — approval reaches 91%, clearing the pre-registered improvement threshold. The review loop accounts for 48 percentage points of improvement. The spec-sharpening step is unnecessary: a first-draft spec from the PR description is sufficient. Go 100%, Rust 100%, TypeScript 67% (infrastructure bottleneck, not model capability). The finding: autonomous refactoring without review is the slop-slope. Autonomous refactoring with iterative review is a viable workflow step.

## Conclusion

Add forge + iterative review to your CI. The mechanism is the review loop, not the prompt, not the model, not the spec. Single-round forge is coin-flip. Iterative forge clears the bar. Rust's strict compiler makes iteration MORE effective — convergence in 2 rounds vs Go's 5-10.

The 80% rate is measured by an LLM reviewer (Gemini 3.1 Pro), not humans. Human validation on a 4-PR subset is prepared but pending. If human reviewers agree, the finding is confirmed. If they disagree, every LLM-as-judge result in the field needs revisiting.

**[Full results →](RESULTS.md)**

## Quick navigation

| What | Where |
|------|-------|
| **Results** | [RESULTS.md](RESULTS.md) |
| **Pre-registration (v2)** | [PREREG_V2.md](PREREG_V2.md) |
| **Work log (full trail)** | [worklog/WORK_LOG.md](worklog/WORK_LOG.md) |
| **v3 questions backlog** | [v3_questions.md](v3_questions.md) |
| **Invalidated single-round results** | [RESULTS_SINGLE_ROUND_INVALID.md](RESULTS_SINGLE_ROUND_INVALID.md) |

### Pipeline

Two models converge on a solution. A third reviews independently.

```
PR description + linked issues
        ↓
   Goal anchor
        ↓
   ┌─────────────────────────────────────────┐
   │  GENERATOR PAIR (Opus 4.6 + Codex 5.4)  │
   │                                          │
   │  Volley: codex sharpens spec into claims │
   │  Blind-blind: both implement from spec,  │
   │    smaller-churn wins                    │
   └──────────────┬──────────────────────────┘
                  ↓
   ┌─────────────────────────────────────────┐
   │  ADVERSARIAL LOOP (Codex vs Codex)       │
   │                                          │
   │  Hunt-spec: codex critiques claims       │
   │  Hunt-code: codex finds defects          │
   │    → codex addresses → rebuild+retest    │
   │    → repeat until converge or N=10       │
   │  Build + tests gate every round          │
   └──────────────┬──────────────────────────┘
                  ↓
   Complexity gate (δ=0.05 on mean cognitive)
                  ↓
   ┌─────────────────────────────────────────┐
   │  INDEPENDENT REVIEWER (Gemini 3.1 Pro)   │
   │                                          │
   │  Sees final output blind                 │
   │  Forced choice: approve or comment       │
   │  Never saw the code during construction  │
   └──────────────┬──────────────────────────┘
                  ↓
   C_llm (merge-ready refactored code)
```

### Prompts

| Phase | Prompt | Model |
|-------|--------|-------|
| Volley | [prompts/forge-v2/01-volley.md](prompts/forge-v2/01-volley.md) | Codex GPT-5.4 |
| Hunt-spec | [prompts/forge-v2/02-hunt-spec.md](prompts/forge-v2/02-hunt-spec.md) | Codex GPT-5.4 |
| Reconcile | [prompts/forge-v2/03-reconcile.md](prompts/forge-v2/03-reconcile.md) | Codex GPT-5.4 |
| Implement | [prompts/forge-v2/04-implement.md](prompts/forge-v2/04-implement.md) | Opus 4.6 + Codex GPT-5.4 |
| Hunt-code | [prompts/forge-v2/05-hunt-code.md](prompts/forge-v2/05-hunt-code.md) | Codex GPT-5.4 |
| Reviewer | [prompts/forge-v2/06-reviewer-loop.md](prompts/forge-v2/06-reviewer-loop.md) | Gemini 3.1 Pro |
| Address findings | [prompts/forge-v2/07-address-findings.md](prompts/forge-v2/07-address-findings.md) | Codex GPT-5.4 |

### Scripts

| Script | Purpose |
|--------|---------|
| `scripts/find_c_test_v2.sh` | Find earliest tests-passing commit in PR branch |
| `scripts/build_cleanroom_v2.sh` | Build isolated workspace at C_test |
| `scripts/run_forge_v2_iterative.sh` | Full iterative pipeline orchestrator |
| `scripts/resume_iterative.sh` | Resume from single-round code, add iterative review |
| `scripts/run_pr_end_to_end.sh` | End-to-end runner (extraction → cleanroom → pipeline) |
| `scripts/complexity_gate_v2.mjs` | Ship-time complexity gate (mean cognitive, δ=0.05) |
| `scripts/measure_complexity.mjs` | Per-function complexity measurement (TypeScript) |
| `scripts/post_exclusion_size.sh` | Post-exclusion source-line count for PR sizing |
| `scripts/feasibility_v2.sh` | Pre-selection feasibility check at C_final |

### Trial artifacts

```
samples/
  v2/                           # Iterative trial artifacts (current)
    <repo>-<pr>/
      find_c_test.json          # C_test extraction result
      goal/GOAL.md              # Goal anchor (PR title + body + issues)
      pipeline-iterative.log    # Full pipeline log with round counts
      gates/
        hunt-code-round-*.md    # Adversarial findings per round
        complexity-gate.json    # Gate measurement
      reviewer-loop/
        round-*-comments.md     # Reviewer comments per round
        final-state.txt         # converged_approved | impasse | cap_hit
      meta.json                 # Trial metadata + convergence stats
  v2-single-round/              # Archived single-round artifacts
    <repo>-<pr>/                # Same structure, single-round only
  candidates-*.json             # PR candidate pools per repo
  repos-explored.md             # All repos screened (50+)
  dev-set-results.md            # Dev-set pipeline validation summary
```

### Repos

| Repo | Language | Trials | Valid | Result |
|------|----------|--------|-------|--------|
| google-gemini/gemini-cli | TypeScript | 9 | 6 | 67% approved |
| cli/cli | Go | 2 | 2 | 100% approved |
| google/cel-go | Go | 3 | 2 | Pipeline validated |
| googleapis/google-cloud-go | Go | 2 | 2 | Pipeline validated |
| google/go-github | Go | 3 | 3 | Pipeline validated |
| google/adk-go | Go | 2 | 2 | Pipeline validated |
| google/go-containerregistry | Go | 2 | 2 | Pipeline validated |
| googleapis/gapic-generator-go | Go | 2 | 2 | Pipeline validated |
| astral-sh/ruff | Rust | 2 | 0 | Forge can't produce valid Rust |

Full screening of 50+ repos: [samples/v2/repos-explored.md](samples/v2/repos-explored.md)

## Key findings

1. **The review loop is the anti-slop mechanism.** Single-round = 43% (parity). Iterative = 80% (above threshold). 38pp from iteration.
2. **Volley iteration is unnecessary.** Single-round spec + iterative review = 80%. The PR description is already a sharp enough spec.
3. **Language matters.** Go 87%, TypeScript 67%, Rust 0%. Forge works where the type system catches bugs without rejecting valid refactors.
4. **Hunt-code never converges.** 8/12 trials hit N=10 cap (findings oscillate). Yet 7/8 got reviewer approval. The adversarial bar is stricter than the merge-readiness bar.
5. **90% of OSS repos are inaccessible.** Force-push culture means no multi-commit branches to extract C_test from. Google-ecosystem repos are the exception.

## Connection to vibelogging

This experiment measures the bottom half of the [vibelogging](https://june.kim/vibelogging) pipeline: can clarified intent (blog post → issue → PR description) compile reliably to merge-ready code? At 80% with iterative review: yes, for Go and TypeScript.

## License

Experiment methodology, prompts, and scripts: MIT. Trial artifacts contain code from the sampled repos under their respective licenses.
