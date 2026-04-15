# Can LLMs reduce complexity through refactoring to make PRs easier to merge?

## Hypothesis

For brownfield PRs, there exists an equivalence class of correct implementations — all pass the same tests, but they differ in complexity. The first implementation that passes tests is rarely the least complex. Human reviewers push contributors toward simpler members of the class before merging. We hypothesize that LLMs, given only the "tests first pass" snapshot and a refactoring prompt, can move the implementation toward the merge-ready state without access to reviewer feedback.

## Background

Every PR in a collaborative codebase implicitly navigates three axes:
1. **Predicate** — does the approach work at all?
2. **Transformation** — does the code implement it correctly?
3. **Complexity trajectory** — does this change leave the codebase simpler or more complex than it found it?

Axes 1 and 2 are testable. Axis 3 is what reviewers enforce through feedback rounds. If LLMs can control axis 3 autonomously, the review bottleneck shrinks: reviewers check direction, not cleanup.

## Design

### Sampling

Source repos: `google/gemini-cli` (TypeScript monorepo, 20+ contributors, active review culture). Additional repos TBD for generalizability.

**Inclusion criteria:**
- Merged PR with ≥2 review rounds
- Tests exist and pass at some commit before the final merge commit
- Delta between "tests first pass" commit and merge commit includes non-trivial refactoring (not just typo fixes or comment additions)

**Sample size:** 30 PRs (power analysis TBD after pilot of 5).

### Variables

**Independent variable:** LLM refactoring applied to the "tests first pass" snapshot.

**Dependent variables:**
1. **Cyclomatic complexity delta** — measured via `eslint --rule complexity` or `ts-complexity` between (a) tests-first-pass, (b) LLM-refactored, (c) merge-ready
2. **Diff similarity** — Levenshtein distance or tree-edit distance between LLM-refactored and merge-ready, normalized against tests-first-pass to merge-ready distance
3. **Reviewer simulation** — blind evaluation by a human reviewer: given the three versions unlabeled, rank by merge-readiness
4. **Lines of code delta** — net LOC change from tests-first-pass to each version

### Procedure

For each sampled PR:

1. **Extract snapshots.** Identify commit where tests first pass (`C_test`). Identify final merge commit (`C_merge`). Checkout both.
2. **Generate LLM refactoring.** Starting from `C_test`, prompt the LLM to refactor for clarity and simplicity. The LLM sees the full repo context but NOT the reviewer comments or subsequent commits. Produce `C_llm`.
3. **Verify correctness.** Run the test suite on `C_llm`. If tests fail, the trial is excluded (LLM broke the equivalence class).
4. **Measure.** Compute all dependent variables for the triple (`C_test`, `C_llm`, `C_merge`).
5. **Blind review.** Present all three diffs (from the pre-PR base) to a reviewer who hasn't seen the original PR. Rank order for merge-readiness.

### Controls

- **Null control:** `C_test` itself (no refactoring). Establishes baseline distance to `C_merge`.
- **Random control:** Apply a semantics-preserving but non-simplifying transformation (e.g., rename variables to synonyms, reorder functions). Ensures the metric isn't just measuring "any change."

### Analysis

**Primary test:** Paired comparison. For each PR, does `C_llm` land closer to `C_merge` than `C_test` does, on each metric? Sign test or Wilcoxon signed-rank across the 30 PRs.

**Secondary:** Correlation between complexity reduction magnitude and number of review rounds in the original PR. If LLMs recover more of the delta on PRs that required more review rounds, that suggests they're capturing what reviewers enforce.

**Stopping rule:** After the pilot of 5 PRs, compute effect size. If Cohen's d < 0.2 on all metrics, stop (futility). If d > 0.8 on any metric, stop (clear signal). Otherwise continue to 30.

## Predictions

- **P1:** LLM-refactored code will have lower cyclomatic complexity than the tests-first-pass snapshot in ≥70% of trials.
- **P2:** LLM-refactored code will be closer to the merge-ready version (by tree-edit distance) than the tests-first-pass snapshot in ≥60% of trials.
- **P3:** Blind reviewers will rank `C_llm` above `C_test` in ≥65% of trials.
- **P4:** `C_llm` will NOT match `C_merge` exactly in any trial. The equivalence class is large; LLMs will find a different simple member, not the same one the reviewer guided toward.

## What this would show

**If confirmed:** LLMs can autonomously navigate the complexity axis of brownfield contributions. The practical implication is that coding agents should include a refactoring pass after tests pass, before submitting for review. This compresses the review cycle by pre-resolving the feedback that reviewers would otherwise give.

**If refuted:** The complexity axis requires contextual judgment that LLMs lack — taste about what "simpler" means in a specific codebase's idiom. Reviewers aren't just asking for less complexity; they're asking for complexity reduction along dimensions the LLM can't infer from the code alone.

## Registered: 2026-04-14
