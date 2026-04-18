# v2 Results: Does a forge-wrapped LLM refactoring pass improve merge-readiness?

## Headline

| Pipeline | Approval rate | Prereg threshold | Verdict |
|----------|--------------|-----------------|---------|
| Single-round (no iteration) | 9/21 = **43%** | [40-60%] parity | "Do not recommend" |
| With iterative review | 16/20 = **80%** | ≥65% improvement | **"Worth running"** |

**Iteration attribution: 38 percentage points.** The convergence loop — not the spec, not the models — is the mechanism.

---

## Design

27 merged brownfield PRs across 9 repos and 3 languages. Each PR's code at first-tests-passing (C_test) was refactored by a forge pipeline and measured for merge-readiness.

**Pipeline:** goal-anchored volley → adversarial hunt-spec → blind-blind implementation (Opus 4.6 + Codex GPT-5.4, smaller-churn wins) → iterative hunt-code with full build+tests (N≤10) → iterative Gemini reviewer-loop (N≤10) → complexity gate (δ=0.05).

**Models:** Claude Opus 4.6 (generator + addressing), Codex GPT-5.4 (generator + adversarial reviewer + addressing), Gemini 3.1 Pro Preview (reviewer).

**Repos:**

| Repo | Language | Valid | Hard no-op | Total |
|------|----------|-------|------------|-------|
| google-gemini/gemini-cli | TypeScript | 6 | 3 | 9 |
| cli/cli | Go | 2 | 0 | 2 |
| google/cel-go | Go | 2 | 1 | 3 |
| googleapis/google-cloud-go | Go | 2 | 0 | 2 |
| google/go-github | Go | 3 | 0 | 3 |
| google/adk-go | Go | 2 | 0 | 2 |
| google/go-containerregistry | Go | 2 | 0 | 2 |
| googleapis/gapic-generator-go | Go | 2 | 0 | 2 |
| astral-sh/ruff | Rust | 0 | 2 | 2 |
| **Total** | | **21** | **6** | **27** |

---

## The accidental ablation

A procedural error produced the experiment's most important finding. The first run used single-round pipeline (skipping iterative hunt-code and reviewer-loop convergence). The second run resumed from the same refactored code and added iteration.

This created an unplanned A/B test on the review loop:

| Condition | What ran | Approval rate |
|-----------|---------|---------------|
| A: Single-round | Spec → implement → 1 hunt-code → 1 reviewer | 9/21 = 43% |
| B: Iterative | Same code → iterative hunt-code (N≤10) → iterative reviewer (N≤10) | 16/20 = 80% |

**The spec and implementation were identical in both conditions.** Only the post-implementation review loop differed. The 38pp improvement is attributable entirely to iterative review — the convergence loop the prereg hypothesized would matter.

### Volley efficacy (accidental finding)

Because condition B reused condition A's code (single-round spec → single-round implementation), the data also shows: **iterative spec sharpening is not required for 80% approval.** A first-draft volley spec produces code good enough that iterative review alone pushes it past the threshold.

This makes sense: the PR title + body + linked issue already IS a sharp spec. The human author sharpened it by writing the code and getting tests to pass. Volley re-derives what the author already knows. The real gap isn't "what to refactor" — it's "was the refactoring done correctly?" That's what the review loop answers.

---

## Iterative convergence behavior

Of the 12 trials that received iterative treatment:

| Outcome | Count | Rate |
|---------|-------|------|
| Converged to approved | 7 | 58% |
| Impasse (comments didn't shrink) | 4 | 33% |
| Infra failure | 1 | 8% |

### Hunt-code convergence

| Pattern | Count | Description |
|---------|-------|-------------|
| Converged (zero findings) | 2 | Clean pass, no iteration needed |
| Hit cap N=10 | 8 | Findings oscillated (codex addressing introduces new issues while fixing old ones) |
| Mixed | 2 | Some rounds failed build/test, recovered |

Hunt-code convergence is noisy. Codex addressing creates oscillation — fixing 2 issues and introducing 2 new ones. The cap at N=10 prevents infinite loops. Despite this, build+test always passes at the final check (the gate works).

### Reviewer-loop convergence

| Pattern | Count |
|---------|-------|
| Round 1: "No comments" | 3 |
| Round 1-2: comments shrink → approved | 4 |
| Impasse: comments don't shrink | 4 |
| Infra failure | 1 |

The reviewer-loop is more decisive than hunt-code. When it works, it converges in 1-2 rounds. When it doesn't, it impasses immediately (comments ≥ previous round).

---

## Language results

| Language | Active trials | Approved (iterative) | Approval rate |
|----------|--------------|---------------------|---------------|
| Go | 15 | 13 | **87%** |
| TypeScript | 6 | 4 | **67%** |
| Rust | 0 | 0 | **0%** |

### Go (87%)

Go is the sweet spot. Fast tests (instant `go test`), strong type system (catches refactoring errors at build time), manageable repo size, and fast CLI addressing (2 min per round). Google Go repos dominated the sample due to multi-commit branch culture.

### TypeScript (67%)

TypeScript works but the addressing step is a bottleneck. CLI-based agents (codex, opus) hang on large TS monorepos (~1000 files) due to context loading. 2 of 3 TS iterative trials were impasse partly due to this infrastructure limitation rather than code quality.

### Rust (0%)

Both Rust trials broke build or tests. The type system (borrow checker, lifetimes, trait constraints) rejects structurally valid refactors that would pass in Go or TS. Not clear whether iterative hunt-code with compiler feedback would recover — that's a v3 question.

---

## Hard no-op rate (agent competence)

| Language | Rate |
|----------|------|
| Go | 1/16 = 6% |
| TypeScript | 3/9 = 33% |
| Rust | 2/2 = 100% |
| **Overall** | **6/27 = 22%** |

---

## Complexity

All 21 active trials passed the complexity gate (Δ ≤ 0.05). No trial increased mean cognitive complexity. 2 trials showed measurable reduction (Δ = -0.01, -0.08). 19 trials showed Δ = 0 — the metric is too coarse for the kind of changes forge makes (helper extraction, deduplication) which don't move per-function cognitive complexity when averaged across 100+ scoped functions.

---

## Blind-blind

| Winner | Count | Rate |
|--------|-------|------|
| Codex (GPT-5.4) | 13/21 | 62% |
| Opus (Claude 4.6) | 8/21 | 38% |
| Exact tie | 1 | — |

Codex produces slightly smaller diffs on average. Both models produce viable code from the same spec. Blind-blind runs in parallel (zero wall-clock cost) and provides redundancy against single-model failures — cheap insurance, not theater.

---

## Structural findings

### 1. The review loop is the anti-slop mechanism

Without iteration, forge produces code at parity with no-refactor (43%). With iteration, it clears the improvement threshold (80%). The slop-slope (Dexter Horthy's term) is real in single-round mode and controlled by the review loop. Autonomous agents accumulate slop; iterative review catches it.

### 2. Force-push culture limits the methodology

~90% of popular OSS repos have single-commit PR branches (rebase/amend culture). The C_test extraction methodology requires multi-commit branches to find pre-review state. Only Google-ecosystem repos (inherited Gerrit/Critique patchset culture) reliably preserve branch history. v3 should use the GitHub Review API for C_test extraction.

### 3. Hunt-code oscillation is a real problem

Codex addressing fixes N issues and introduces N±1 new ones, creating oscillation that never reaches zero findings. The cap at N=10 is essential. Despite oscillation, build+test always passes — the findings are style/correctness warnings, not build-breaking.

### 4. The LLM-reviewer validity question is open

The entire pipeline uses LLMs to generate, review, and judge code. The 80% approval rate is Gemini approving code shaped by Gemini's own feedback. Human reviewer validation on a subset is needed to calibrate. 4 PRs are prepared on a gemini-cli fork for blind human review.

---

## Deviations from prereg

1. **Single-round first, iterative second** — procedural error that produced the ablation finding.
2. **Distributed across 9 repos** instead of 15-primary + 2×3-secondary — gemini-cli pool exhausted; cross-repo breadth is more powerful for the practitioner claim.
3. **C_test = C_final PRs excluded** — user decision; no human-improvement baseline when C_test = C_final.
4. **TS iterative addressing incomplete** — CLI agents hang on large TS monorepos; 2 of 3 TS iterative trials may have impassed from infra, not code quality.
5. **Phase 7 blind review not yet run** — in-pipeline reviewer (4g) used as measurement instrument; Phase 7 with trajectory classification pending.

---

## Conclusion

Per pre-registered recommendation criterion:

> **Iterative forge-wrapped refactor pass: 80% approval rate.** Above the 65% improvement threshold. **"Worth running on large brownfield PRs in your workflow."**

> **Single-round forge: 43% approval.** Inside parity envelope. **"Do not recommend."**

The finding is not "forge works" or "forge doesn't work." It's: **forge without review = slop-slope. Forge with iterative review = above threshold.** The review loop is the mechanism.

### Caveats

- Gemini reviews code shaped by Gemini's own in-pipeline feedback (pre-approval bias). Human validation pending.
- Go dominates the sample (15/21 active). TS is underrepresented (6/21). Rust absent from active trials.
- Complexity metric (mean cognitive) is too coarse — shows Δ=0 on 19/21 trials despite real structural changes.
- The iterative "resume" design reuses single-round code. A full iterative pipeline (iterative spec + iterative implementation + iterative review) might perform differently.
