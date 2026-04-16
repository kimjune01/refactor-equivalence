# Does an LLM refactoring pass help or hurt brownfield PRs?

## Hypothesis

For brownfield PRs, there exists an equivalence class of correct implementations: multiple implementations pass the same tests, but differ in complexity, maintainability, and fit with the surrounding codebase. The first implementation that passes tests is often not the simplest member of the class.

An LLM refactoring pass after tests pass will move the implementation within this equivalence class. The question is which direction. Two claims, tested independently:

1. **Simplification claim:** Does the LLM reduce measured code complexity relative to the tests-first-pass snapshot?
2. **Merge-readiness claim:** Do independent human reviewers judge the LLM-refactored version as more merge-ready than the tests-first-pass version?

If both confirm, a refactoring pass is worth adding to agent workflows. If the LLM reduces complexity but reviewers don't prefer it, the agent is optimizing a metric that doesn't match taste. If reviewers prefer it but complexity increases, the agent is doing something useful that metrics don't capture. If both refute — the agent makes things worse while passing tests — that's the **slop-slope** (Dexter Horthy's term for the tendency of automated changes to increase codebase complexity despite passing tests) confirmed as default behavior, and the most important finding.

## Estimand

The target estimand is the effect of an autonomous post-tests-pass LLM refactoring pass on **merged brownfield PRs with substantive post-tests-pass revision**.

The study does not estimate effects for:

- All PRs
- Greenfield examples
- Unmerged PRs
- PRs with no meaningful post-tests-pass revision
- PRs where review changes are primarily documentation, formatting, or dependency churn
- PRs whose relevant test predicate cannot be reconstructed

All claims are scoped to the sampled class of merged brownfield PRs where the contributor reached a passing-test implementation before the final accepted PR state and where subsequent human-authored revisions made substantive code changes. This is intentionally enriched for refactorable cases — PRs where reviewers found something worth changing after tests passed.

## Background

Every PR in a collaborative codebase implicitly navigates three axes:

1. **Predicate** — does the approach work at all?
2. **Transformation** — does the code implement it correctly?
3. **Complexity trajectory** — does this change leave the codebase simpler or more complex than it found it?

Axes 1 and 2 are partially testable. Axis 3 is often enforced through review feedback, style norms, maintainability expectations, and local codebase judgment.

If LLMs can improve axis 3 autonomously after tests pass, then coding agents should include a refactoring pass before submitting for review. Reviewers would still make the final judgment, but less of their time would be spent requesting routine simplification.

If LLMs cannot improve axis 3 without reviewer feedback, that suggests the review bottleneck depends on contextual judgment that current models cannot infer reliably from the codebase alone.

## Design

### Sampling

### Depth and breadth

One primary repo goes deep. Four secondary repos go shallow. If results on the primary repo are clear but secondary repos show ambiguity, expand n on the ambiguous secondaries.

- **Primary:** `google-gemini/gemini-cli` (TypeScript monorepo, 20+ contributors, active review culture). 15 PRs.
- **Secondary (3 PRs each, expandable to 10):**
  - `cli/cli` (Go) — GitHub's own CLI, strict review, fast `go test`, ~50 merged PRs/month
  - `astral-sh/ruff` (Rust) — Python linter, strict review, builds in seconds, comprehensive test suite
  - `django/django` (Python) — mature triage/merger workflow, regression tests required, decades of review culture
  - `fastapi/fastapi` (Python) — modern Python, strict typing, fast test suite, active post-cutoff

These repos are current best candidates, not locked. The selection criteria are locked: language diversity, strict enforced review, ≥10 contributors, active post-cutoff. Repos may be swapped for others of equal caliber if build/test reconstruction is impractical. The bar is the caliber, not the specific repo.

**Build-time bias:** All selected repos have fast build/test cycles (seconds to minutes, not hours). This excludes heavyweight C++ projects (LLVM, Chromium) and large compiler codebases (rust-lang/rust) where build times make per-trial iteration impractical. The experiment's results may not generalize to codebases where the build itself is the bottleneck — different feedback loops may produce different PR shapes and review dynamics.

Total initial sample: 27 PRs. Maximum if all secondaries expand: 55.

### Training-contamination restriction

Eligible PRs must have been merged after the training cutoff of the model being evaluated. The model and its documented or estimated training cutoff will be recorded before sampling begins.

If multiple models are evaluated, eligibility will be determined separately for each model.

### Inclusion criteria

A PR is eligible if all of the following hold:

1. It was merged after the model's training cutoff.
2. It is a brownfield change to an existing codebase, not a purely new isolated example or generated fixture.
3. It has at least 2 review rounds or at least one substantive post-review revision.
4. Tests exist and pass at some commit before the final accepted PR head.
5. The delta between the tests-first-pass commit and the final accepted PR head includes non-trivial code changes.
6. The post-tests-first-pass delta is not limited to typos, comments, formatting, dependency lockfile churn, or documentation-only edits.
7. The PR has a reviewable size: neither too small to permit meaningful refactoring nor too large to make blind review impractical.

### PR size bounds

PR size bounds:

- Minimum: 100 changed source lines from pre-PR base to final accepted PR head.
- Maximum: 2000 changed source lines. Larger within this range is preferred.

Changed source lines exclude generated files, lockfiles, snapshots, vendored files, and documentation-only files.

When multiple eligible PRs are available, prefer larger ones. A positive result on large PRs is maximally surprising — more code means more room for complexity to accumulate, more reviewer feedback to anticipate, and a larger equivalence class to navigate. If refactoring works there, smaller PRs are implied.

### Sample size

Initial target: 27 PRs (15 primary + 4×3 secondary).

A pilot of 5 PRs from the primary repo will validate the extraction, prompting, test execution, measurement, and blind review workflow. The pilot is for feasibility only.

### Batch expansion for confidence

Results are evaluated in batches. After each batch, decide: stop (signal is clear) or run another batch from the same repo.

- **Primary repo:** First batch is 15 PRs. If the three-class distribution and reviewer preference are unambiguous (e.g., ≥12 of 15 in the same direction), stop. If ambiguous, run another batch of 10.
- **Secondary repos:** First batch is 3 PRs each. If a secondary repo's results conflict with the primary, expand to 10 before interpreting.

This is group sequential in spirit: look after each batch, expand if uncertain. Evidence compounds across batches — the second batch doesn't invalidate the first. Post-expansion analyses from any repo are reported alongside pre-expansion results so the reader can see what changed.

No maximum sample size is fixed. The stopping rule is confidence, not a number. But each expansion decision and its rationale are recorded in the work log before the next batch begins.

## Snapshot Definitions

For each sampled PR, define the following commits or working-tree states.

### `C_base`

The pre-PR base commit against which the PR was originally opened or the closest reconstructable ancestor before the PR's changes.

All diffs shown to reviewers are computed relative to `C_base`.

### `C_test`

The earliest commit in the PR branch where the merge-time test suite passes.

The test suite that matters is the one that exists at `C_final` — that's the contract the reviewer accepted. `C_test` is found by backporting those tests onto earlier commits to find when the implementation first satisfied them.

Operationally:

1. Extract the test files from `C_final`.
2. Define the test command. For each repo, this is the CI command that gates merge — the relevant test shard, not the full matrix. Locked per repo before extraction begins.
3. Traverse PR commits in chronological order from `C_base`.
4. At each commit, overlay the `C_final` test files onto the working tree and run the test command.
5. Record all commits where this combined state passes.
6. Select the earliest passing commit as `C_test`.

This ensures `C_test` and `C_final` are compared against the same behavioral contract. The LLM refactors implementation code, not tests — and the tests it must preserve are the ones the reviewer signed off on.

If the `C_final` tests cannot be overlaid cleanly onto earlier commits (e.g., tests reference APIs that don't exist yet), the PR is excluded. Record exclusion reason.

### `C_final`

The final accepted PR head before merge. Serves two roles:

1. **Test source:** the merge-time test suite is backported onto earlier commits to define `C_test`.
2. **Directional proxy:** `C_final` marks the direction reviewers pushed the code. It is not ground truth for optimal code, but if `C_llm` reaches or passes `C_final` on the complexity axis, that's strong evidence the refactoring pass is working. "Past it" is better than "toward it."

### `C_llm`

The LLM-refactored version produced from `C_test` under the clean-room procedure.

The LLM may edit source files changed in the PR diff from `C_base` to `C_test`. It may not edit tests. Mechanically enforced when constructing `C_llm`.

Note: `C_final` may touch additional files beyond `C_test`. The LLM is not given access to those files' identities, because knowing which files reviewers eventually changed is information leakage. If this restriction prevents valid simplifications, that biases against `C_llm` — a conservative choice. It also means complexity comparisons to `C_final` are weakened when reviewers improved the PR by adding or moving code to files outside the `C_test` scope. This is noted as a limitation, not corrected.

### `C_random`

A semantics-preserving but non-simplifying control transformation produced from `C_test`.

Examples include mechanical variable renaming, reordering independent helper declarations, or formatting-preserving syntactic rewrites. The transformation must preserve behavior and must not intentionally simplify control flow or improve design.

## Variables

### Independent variable

LLM refactoring applied to the `C_test` snapshot.

### Dependent variables

### 1. Complexity delta

Measured between:

- `C_test`
- `C_llm`
- `C_final` (directional proxy)
- `C_random`, where available

The primary complexity scope is the union of source files touched by `C_test` or `C_llm`.

This avoids measuring only the subset of files edited by one condition and prevents the LLM from appearing simpler merely by moving or avoiding changes outside the measured scope.

Primary complexity measures:

- Cyclomatic complexity, using a fixed tool and configuration such as ESLint complexity rules or `ts-complexity`
- Cognitive complexity, if supported by the chosen static-analysis tooling
- Maximum function complexity
- Mean function complexity across touched functions

Secondary diagnostics:

- Function count
- Maximum nesting depth
- Number of newly introduced abstractions
- LOC delta
- Number of touched files and touched functions

If the agent produces a no-op (fails tests or produces no applicable output), `C_llm = C_test` and complexity delta is zero.

### 2. Direction relative to `C_final`

`C_final` is where reviewers pushed the code — a satisficing threshold, not the optimum. Each trial is classified into one of three trajectory classes:

- **Past `C_final`:** simpler than the accepted version and the reviewer would still approve it. (Simpler + no new correctness or clarity concerns.)
- **Short of `C_final`:** improved over `C_test` but leaves complexity that the accepted version removed. (Better but not as good.)
- **Wrong direction:** no meaningful improvement, or worse. The slop-slope. (Same or harder to review than `C_test`.)

**Primary classification: reviewer-judged.** After the pairwise forced choice (step 3 below), reviewers see `C_final` and classify `C_llm`'s trajectory relative to both `C_test` and `C_final`. This is the headline label.

**Scalar calibration:** Mean cognitive complexity across touched functions (locked after pilot) is computed for `C_test`, `C_llm`, and `C_final`. The scalar does not determine the class — it calibrates the reviewer judgment. Report:

- Agreement rate between reviewer label and scalar label
- Distance from boundary (how far from a tie)
- Cases where reviewer and scalar disagree

Differences smaller than δ (set after pilot based on observed metric variance) are flagged as boundary cases rather than forced into a class.

**Sensitivity analysis:** Recompute scalar labels using cyclomatic complexity, nesting depth, function count, and LOC. Report the fraction of trials whose class is stable across metrics. Instability is a finding about metric validity.

Report the distribution across the three reviewer-classified categories. "Past `C_final`" is the strongest evidence; "wrong direction" is the most important finding.

### 3. Human merge-readiness preference

Independent reviewers will evaluate unlabeled diffs from `C_base`.

Only test-passing `C_llm` outputs are shown to reviewers. No-op trials (agent failed to produce a test-passing output) are automatically scored as "reviewer prefers `C_test`."

The primary review instrument is pairwise forced choice between:

- `C_test`
- `C_llm`

Reviewers answer:

```text
Assuming tests pass, which version would you approve for merge?
```

Reviewers must choose one version. They may also provide a short categorical rationale.

Reviewers will separately record whether either version raises a semantic concern.

After the forced choice, reviewers are shown `C_final` (labeled as "the version reviewers accepted") and asked to classify `C_llm`'s trajectory: past `C_final`, short of `C_final`, or wrong direction. This is the primary trajectory classification.

`C_random`, where available, may be used in secondary or calibration comparisons.

Reviewers will receive:

- PR title
- PR body
- A neutral task description based on the PR's stated purpose
- Unlabeled diffs from `C_base` to each candidate version

Reviewers will not see:

- Original PR discussion
- Review comments
- Commit history after `C_test`
- Which version was produced by the LLM
- Which version was final
- Other reviewers' judgments

After completing the forced-choice task, reviewers will answer a blinding check asking whether they believed any reviewed version was final, LLM-generated, or otherwise identifiable.

### 4. Lines of code delta

Net LOC change from `C_test` to `C_llm` and `C_random`. LOC is descriptive, not a quality measure.

### 5. Correctness gate

`C_llm` must pass the predetermined test command. Passing tests is a precondition for membership in the equivalence class, not a variable.

If the LLM agent cannot produce a test-passing output, the trial is scored as a no-op: `C_llm = C_test` for all metrics. The agent produced nothing. Report the no-op rate as a measure of agent competence, but do not analyze non-passing outputs further.

The interesting failure is not the agent that breaks tests — that agent is simply incompetent. The interesting failure is the agent that passes tests while making the codebase harder to maintain. That is the slop-slope this experiment is designed to detect.

## Procedure

### Dev/test separation

For each repo, PRs are split into a dev set (used for prompt iteration) and a test set (used for evaluation). No PR may appear in both. The prompt is frozen before any test-set PR is evaluated. Dev-set results are published alongside test-set results but do not contribute to the primary analysis.

### Trail commitment

The following will be published alongside results:

- All candidate PRs considered and why each was included or excluded
- All prompts tried during dev-set iteration, with notes on what changed and why
- Full pilot data including failures
- All `C_test` candidate commits, not just the selected one
- Exclusion log with reasons

### For each sampled PR:

1. **Extract snapshots.**
   Identify `C_base`, `C_test`, and `C_final` according to the definitions above.

2. **Prepare clean-room workspace.**
   Copy the repository at `C_test` to a temporary workspace such as `/tmp`.

   The clean-room workspace must:

   - Exclude `.git`
   - Exclude PR metadata
   - Exclude reviewer comments
   - Exclude subsequent commits
   - Disable network access during LLM execution and test execution
   - Use already-resolved dependencies where possible
   - Build artifacts (node_modules, compiled dependencies, caches) may be shared across trials from the same repo. Only source files differ between trials — the build environment is held constant.

   Since tests pass at `C_test`, the refactoring task should not require external references or network access.

3. **Generate LLM refactoring via forge pipeline.**

   The refactoring uses the strongest available development methodology: [/forge](/forge). The full pipeline runs inside the clean-room workspace with no access to reviewer comments, later commits, the final accepted PR state, git history, or the internet.

   **3a. Volley (sharpen).** Take the repo-specific refactoring prompt and the diff from `C_base` to `C_test`. Volley sharpens the refactoring intent into specific, testable changes. Converge in two rounds — if the refactoring intent doesn't stabilize, the trial is a no-op.

   **3b. Blind-blind-merge (implement).** Two models, same sharpened spec, separate `/tmp` directories. Each produces a refactored version independently. Compare implementations, pick the structurally simpler one per component, synthesize.

   Models: Claude Opus 4.6 (via Claude Code, auto-edit) and Codex GPT-5.4 (via `codex exec -s danger-full-access`). Gemini 3.1 Pro Preview (via `gemini --approval-mode yolo --include-directories <workspace>`) serves as reviewer only — it does not participate in generation. All three verified to write files in `/tmp` workspaces.

   **3c. Bug-hunt (verify).** Run adversarial review against the merged refactoring with the original spec as input. Iterate to convergence (zero new findings). If a bug traces to a spec defect, fix the spec and re-merge rather than patching.

   **3d. Volley (clean).** Review the implementation against the spec. Clean up naming, remove dead code, verify tests pass. Converge in two rounds. Output is `C_llm`.

   The LLM may not edit tests. It may only edit source files changed from `C_base` to `C_test`. Mechanically enforced after generation.

   The exact prompts, model names and versions, decoding parameters, tool permissions, allowed file set, and number of volley/hunt rounds will be recorded.

4. **Verify correctness.**
   Run the predetermined test command on `C_llm`.

   If tests fail, the trial is a no-op: `C_llm = C_test` for all metrics. The agent failed to stay in the equivalence class.

5. **Generate random control.**
   Apply the predetermined random or mechanical transformation to `C_test`, producing `C_random`.

   Verify whether `C_random` passes tests. If it fails, record failure and classify the control as invalid for that PR.

6. **Measure.**
   Compute complexity and LOC for `C_test`, `C_llm`, `C_final`, and `C_random`.

7. **Blind human review.**
   Two phases per reviewer per PR:

   **Phase 1 — Forced choice.** Present unlabeled diffs from `C_base` to `C_test` and `C_llm`. Reviewer picks which to approve assuming tests pass. Record semantic concerns and rationale.

   **Phase 2 — Trajectory classification.** Reveal `C_final` (labeled as "the version reviewers accepted"). Reviewer classifies `C_llm` as past `C_final`, short of `C_final`, or wrong direction.

   Each PR evaluated by at least 3 independent reviewers. Primary reviewer model: Gemini 3.1 (no conflict — it does not participate in the blind-blind-merge that produces `C_llm`). Codex (GPT-5.4) may serve as a secondary reviewer on trials where it did not generate one of the merge candidates. A model that participated in generating `C_llm` may not review that trial.

8. **Post-ranking blinding check.**
    After submitting judgments, reviewers answer whether they believed any version was final, LLM-generated, or otherwise identifiable.

9. **Record all metadata.**
    Record:

    - Repository
    - PR number
    - `C_base`, `C_test`, `C_final`
    - All candidate passing commits considered for `C_test`
    - Model name and version
    - Model cutoff date
    - Prompt
    - Test command
    - Allowed edit file set
    - Test outcome
    - Failure category, if any
    - Static-analysis tool versions
    - Reviewer IDs or anonymized reviewer labels
    - Review preferences
    - Semantic-concern flags
    - Blinding-check responses
    - Notes on reconstruction issues

## Controls

### Null control

`C_test` itself.

This establishes the baseline state after tests first pass.

### Random/mechanical control

`C_random`, a semantics-preserving but non-simplifying transformation.

This tests whether metrics reward any change or specifically reward simplification.

### Directional proxy

`C_final` — where reviewers pushed the code. Used to classify each trial as short, past, or wrong direction on the complexity axis. Not a ground truth; a satisficing threshold.

## Analysis

### Primary analyses

The three main outcomes are analyzed separately.

### 1. Simplification

Question: Does `C_llm` reduce complexity relative to `C_test`?

Primary comparison:

```text
complexity(C_llm) - complexity(C_test)
```

Analyze with paired tests across PRs:

- Wilcoxon signed-rank test for continuous deltas
- Sign test for direction of improvement

No-op trials contribute zero complexity delta. The denominator is all trials.

### 2. Trajectory classification

Question: Where does `C_llm` land relative to `C_test` and `C_final`?

Report the reviewer-classified three-way distribution: past `C_final`, short of `C_final`, wrong direction. No-op trials count as wrong direction.

Report scalar agreement, boundary cases, and sensitivity across metrics as robustness checks.

### 3. Human merge-readiness

Question: Do blind reviewers prefer `C_llm` over `C_test` for merge-readiness?

Primary comparison:

```text
forced_choice(C_llm over C_test)
```

The primary analysis uses the pairwise forced-choice answer to:

```text
Assuming tests pass, which version would you approve for merge?
```

Analyze reviewer preferences using a mixed-effects logistic model with random effects for PR and reviewer.

A simpler paired sign-test analysis may also be reported for interpretability.

Semantic-concern flags are analyzed separately from merge-readiness preference.

### Mixed-effects model

For reviewer preferences, use a mixed-effects logistic model.

Candidate model:

```text
prefer_llm_over_test ~ PR_size + (1 | PR) + (1 | reviewer)
```

Two analyses are reported:

1. **Intent-to-treat (primary for P3):** All trials. No-ops scored as "reviewer prefers `C_test`." This is the denominator for P3.
2. **Observed-only (primary for the mixed-effects model):** Only trials where `C_llm` passed tests and reviewers saw actual diffs. No synthetic judgments. This isolates refactoring quality from agent competence.

For calibration tasks involving `C_random`, ordinal or logistic models may be used depending on the final coding.

### Inter-rater reliability

Compute inter-rater reliability for blind review judgments.

Candidate measures:

- Agreement rate on pairwise forced choice
- Fleiss' kappa or Krippendorff's alpha for categorical preference labels
- Kendall's W if any secondary ranking task is used

Low agreement will be reported as a substantive result, not treated only as noise.

### No-op rate

Report the fraction of trials where the agent failed to produce a test-passing output (no-op rate). This measures agent competence, not the hypothesis. A high no-op rate means the agent isn't ready for the task; it doesn't tell us whether refactoring helps.

### Secondary analyses

### Review-round correlation

Test whether LLM improvement correlates with the number of review rounds in the original PR.

### Active-only analysis

Repeat primary analyses on the subset where the agent produced a test-passing output (non-no-op trials). This isolates the quality of refactoring from agent competence.

## Pilot

The pilot consists of 5 PRs.

The pilot is used to answer feasibility questions:

1. Can `C_base`, `C_test`, and `C_final` be reconstructed reliably?
2. Can tests be run reproducibly in the clean-room environment?
3. Does the prompt produce applicable patches?
4. Are the complexity and diff metrics stable enough to compute?
5. Can blind reviewers evaluate the diffs in reasonable time?
6. Are the PR size bounds appropriate?
7. Can the mechanical edit restrictions be enforced cleanly?
8. Can `C_random` be generated without accidental simplification or behavioral breakage?
9. What is the no-op rate? Is the agent competent enough for the experiment to proceed?

The pilot will not be used to stop early for efficacy.

Any procedural changes after the pilot will be documented before main-sample extraction begins.

## Pilot Decisions

The following items will be decided and locked after the pilot and before the main sample is drawn:

1. **Complexity tool and configuration.**
   Lock the static-analysis tool, version, parser settings, ignored files, thresholds, and aggregation rules.

2. **Review presentation format.**
   Lock syntax highlighting, side-by-side versus sequential presentation, file-path display, diff context, and any reviewer UI constraints.

3. **Reviewer population criteria.**
   Lock reviewer experience criteria, familiarity requirements, exclusion criteria, compensation, and assignment procedure.

4. **`C_random` generator specifics.**
   Lock the transformation family, edit budget, random seed policy, validation procedure, and invalid-control handling.

5. **Boundary threshold δ.**
   Lock the scalar difference below which trials are flagged as boundary cases rather than classified.

6. **Secondary repo expansion trigger.**
   Lock the threshold for expanding a secondary repo from 3 to 10 PRs.

7. **PR size bound adjustments.**
   Lock any changes to minimum or maximum changed-source-line thresholds.


## Futility Conditions

The study may be deemed infeasible, or redesigned before main-sample execution, if the pilot or early extraction process shows any of the following:

1. **`C_test` reconstruction failure is too high.**
   More than 40% of otherwise eligible PRs cannot yield a defensible tests-first-pass snapshot.

2. **Tests are not reproducible often enough.**
   More than 30% of otherwise eligible PRs cannot run the predetermined relevant tests reproducibly.

3. **No-op rate is too high.**
   More than 40% of trials are no-ops (agent fails to produce a test-passing output).

4. **Reviewers cannot evaluate the diffs.**
   Reviewers report that the blind diffs are too large, too context-dependent, or too ambiguous to support meaningful merge-readiness judgments.

5. **Metrics are inapplicable.**
   Complexity or distance metrics cannot be computed for a large enough share of cases to support the planned primary analyses.

6. **`C_random` cannot be generated reliably.**
   The random/mechanical control cannot be generated without frequent behavioral breakage, accidental simplification, or invalid edits.

These are feasibility and design-validity conditions, not efficacy stopping rules.

## Predictions

### P1: Complexity reduction

`C_llm` will have lower measured complexity than `C_test` in at least 70% of all trials.

The denominator is all trials. No-op trials count as zero complexity reduction.

### P2: Trajectory past `C_final`

In at least 50% of active trials (non-no-ops), reviewers will classify `C_llm` as past `C_final` — simpler than what reviewers accepted. Reviewers are pragmatic, not perfectionists; `C_final` is a satisficing threshold, not the simplest possible member of the class.

The wrong-direction rate (slop-slope) will be below 20% of active trials.

### P3: Human merge-readiness

Blind reviewers will prefer `C_llm` over `C_test` in at least 65% of all reviewer-PR forced-choice judgments.

The denominator is all reviewer-PR judgments. No-op trials count as "reviewer prefers `C_test`."

### P4: Some refactors will make things worse

Among test-passing `C_llm` outputs, some will increase measured complexity or be ranked below `C_test` by reviewers. These cases — the slop-slope — are the most practically important finding.

## Misleading-Result Scenarios

The study will explicitly guard against the following misleading interpretations:

1. **Metric-only simplification.**
   `C_llm` may reduce cyclomatic or cognitive complexity while making the code less idiomatic, less maintainable, or less merge-ready.

2. **Correctness hidden by tests.**
   A refactor may pass the project tests while introducing semantic risk that reviewers notice or that tests fail to cover.

3. **No-op rate masking.**
   A high no-op rate dilutes the signal. If 40% of trials are no-ops, the active-only analysis tells you about refactoring quality while the all-trials analysis tells you about end-to-end viability.

4. **Review blinding failure.**
   Reviewers may infer which version is LLM-generated or final based on style, polish, or diff shape, biasing merge-readiness judgments.

These scenarios will be discussed in interpretation regardless of whether the primary predictions are confirmed.

## Checklist Audit

This prereg was audited against the [prereg checklist](/prereg-audit). Answers below.

**Q3 (Descartes) — Assumptions that would invalidate:**
- That test suites define a meaningful equivalence class (if tests are too weak, "test-passing" doesn't mean "correct")
- That complexity metrics correlate with what reviewers care about (if they don't, P1 is meaningless even if true)
- That blinded reviewers approximate real merge decisions (if context matters more than code quality, the forced-choice task measures the wrong thing)
- That `C_final` marks the direction of reviewer preference on complexity (if post-`C_test` changes were mostly bug fixes or API changes, the directional proxy is noise)

**Q8 (Chamberlin) — Competing explanations for a positive result:**
- The prompt was tuned on dev-set PRs from the same repos, and the test-set PRs share enough structure that the prompt's effectiveness is overfitted rather than general
- The model has trained on similar public PRs and is reproducing patterns, not reasoning (we accept this per the Chinese Room argument — output quality is what matters, but it limits the generalization claim)
- The complexity reduction is real but reviewer preference is anchored by seeing `C_final` in Phase 2, not by independent judgment
- Larger PRs were preferentially selected, and refactoring has more room on larger PRs — the effect may not hold at smaller scales

**Q12 (Kuhn) — Paradigm assumptions:**
- We assume "merge-readiness" is primarily a property of the code. It may also be a property of the relationship between code and reviewer context (trust, roadmap awareness, incident history). Blinded review strips that context. If the paradigm is wrong, we're measuring an abstraction that doesn't exist in practice.

**Q16 (Ioannidis) — Positive predictive value:**
- 27 trials, moderate flexibility (prompt tuned on dev set, metrics locked after pilot, expansion rule). Prior: friendly (60% — LLMs are probably decent at refactoring). Under these conditions, a positive result on P1 or P3 is likely real. P2 is more fragile because the trajectory classification depends on reviewer judgment calibrated against a lossy oracle.
- No formal power analysis. The pilot will estimate variance; if effect sizes are small, 27 trials may be underpowered.

**Q20 (Ramdas) — Sequential validity:**
- Batch expansion looks at results before deciding whether to continue. This is peeking by design. Evidence compounds across batches — the second batch doesn't invalidate the first. All expansion decisions and their rationale are logged before the next batch begins. Pre-expansion and post-expansion results are reported side by side.

**Skipped:**
- Q9 (Fisher) — randomized assignment. Not applicable: within-PR design, no assignment to conditions.

## Threats to Validity

### `C_final` is a satisficing threshold

Reviewers accept "good enough," not the simplest possible. `C_final` marks the direction they pushed, not the optimum. `C_llm` landing past it is evidence the agent outperformed a pragmatic bar, not that it found the global minimum.

### Test suites are incomplete

Passing tests does not prove semantic equivalence. This study uses project tests as the available behavioral predicate, while recognizing that reviewers may catch issues tests miss.

### Reviewer judgments may vary

Merge-readiness is partly subjective. The study uses multiple independent reviewers and reports inter-rater reliability.

Disagreement among reviewers is itself informative about whether the complexity axis is well-defined.

### Leakage

The LLM must not see reviewer comments, later commits, PR metadata, git history, or internet resources.

The clean-room procedure strips `.git`, copies only the `C_test` tree, disables network access, and mechanically enforces the allowed edit set.

### Training contamination

Only PRs merged after the model's training cutoff are eligible.

The model version and cutoff date are recorded before sampling. This is a mitigation, not elimination — public code, PR discussions, and similar patterns may exist in retrieval or evaluation memory despite cutoff restrictions.

### Causal scope

The experiment tests this prompt + this model on these PRs. The causal claim is narrow: this specific intervention on these specific PRs, under these specific conditions. Whether the LLM "understands" simplicity or has memorized patterns that produce simpler code is irrelevant — the practical question is whether the output is better.

Positive results on high-caliber repos (kubernetes, rust-lang/rust, LLVM, Django) suggest the refactoring pass may transfer to simpler codebases, but different code quality norms and PR shapes could change the effect. Down-induction is plausible, not guaranteed.

### Environment reconstruction

Historical test environments may be hard to reproduce. PRs whose `C_test` status cannot be reconstructed reproducibly are excluded before assignment.

### Metric validity

Cyclomatic complexity and LOC are incomplete proxies for maintainability. This is why the study keeps static metrics and human review as separate outcomes.

### Scope restriction

The estimand is limited to merged brownfield PRs with substantive post-tests-pass revision. The results should not be generalized to all PRs, all repositories, greenfield tasks, or changes without meaningful review-driven revision.

## What This Would Show

### If confirmed

LLMs can autonomously improve the complexity trajectory of merged brownfield contributions after tests pass, within the scoped class of PRs studied.

The practical implication is that coding agents should include a refactoring pass after achieving correctness and before requesting review. This could reduce review burden by pre-resolving some cleanup and maintainability feedback.

### If partially confirmed

Different outcome patterns imply different conclusions:

- If complexity improves but reviewers do not prefer `C_llm`, the model is optimizing a metric that doesn't match taste.
- If reviewers prefer `C_llm` but complexity increases, the model is doing something useful that metrics don't capture.
- If the no-op rate is high but active trials show improvement, the bottleneck is agent competence, not refactoring judgment.

### If refuted

The complexity axis may require contextual judgment that LLMs lack without reviewer feedback. Reviewers may not merely be asking for less complexity; they may be asking for project-specific tradeoffs that are difficult to infer from code alone.

## Registered: 2026-04-14
