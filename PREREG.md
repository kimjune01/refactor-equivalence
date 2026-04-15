# Can LLMs reduce complexity through refactoring to make PRs easier to merge?

## Hypothesis

For brownfield PRs, there exists an equivalence class of correct implementations: multiple implementations pass the same tests, but differ in complexity, maintainability, and fit with the surrounding codebase. The first implementation that passes tests is often not the version that reviewers are willing to merge. Human reviewers frequently push contributors toward simpler or more idiomatic members of this equivalence class before approval.

We hypothesize that LLMs, given only the "tests first pass" snapshot and a refactoring prompt, can move an implementation toward a more merge-ready state without access to reviewer feedback or subsequent commits.

This study deliberately separates three related claims:

1. **Simplification claim:** Does the LLM reduce measured code complexity relative to the tests-first-pass snapshot?
2. **Convergence claim:** Does the LLM move the code closer to the final accepted PR state?
3. **Merge-readiness claim:** Do independent human reviewers judge the LLM-refactored version as more merge-ready than the tests-first-pass version?

The final accepted PR state is treated as an important empirical reference point, not as a perfect proxy for optimal code quality.

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

Primary source repo: `google/gemini-cli`, a TypeScript monorepo with an active review culture and sufficient post-cutoff PR activity.

Additional repositories may be added for generalizability if the pilot shows that the extraction procedure works reliably on `google/gemini-cli`.

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

The default PR size bounds are:

- Minimum: 20 changed source lines from pre-PR base to final accepted PR head.
- Maximum: 800 changed source lines from pre-PR base to final accepted PR head.

Changed source lines exclude generated files, lockfiles, snapshots, vendored files, and documentation-only files.

These thresholds may be adjusted after the pilot for feasibility, but any adjustment will be recorded before the main sample is drawn.

### Sample size

Target sample size: 30 PRs.

A pilot of 5 PRs will be used to validate the extraction, prompting, test execution, measurement, and blind review workflow.

The pilot is for feasibility and calibration only. It will not be used as an efficacy stopping rule.

### Snapshot definitions

For each sampled PR, define the following commits or working-tree states.

#### `C_base`

The pre-PR base commit against which the PR was originally opened or the closest reconstructable ancestor before the PR's changes.

All diffs shown to reviewers are computed relative to `C_base`.

#### `C_test`

The earliest commit in the PR branch where the relevant test suite passes after the core implementation is present.

Operationally:

1. Traverse commits in chronological order from `C_base` through the PR branch.
2. Identify commits where the implementation under test is present.
3. Run the predetermined test command.
4. Select the first such commit where tests pass.

If the exact historical CI environment cannot be reconstructed, the local test command and environment will be recorded. PRs whose test status cannot be determined reproducibly will be excluded before assignment.

#### `C_final`

The final accepted PR head before merge.

This is not necessarily the repository merge commit. It is the final state of the PR branch that reviewers accepted.

#### `C_llm`

The LLM-refactored version produced from `C_test` under the clean-room procedure.

#### `C_random`

A semantics-preserving but non-simplifying control transformation produced from `C_test`.

Examples include mechanical variable renaming, reordering independent helper declarations, or formatting-preserving syntactic rewrites. The transformation must preserve behavior and must not intentionally simplify control flow or improve design.

## Variables

### Independent variable

LLM refactoring applied to the `C_test` snapshot.

### Dependent variables

#### 1. Complexity delta

Measured between:

- `C_test`
- `C_llm`
- `C_final`
- `C_random`, where available

Primary complexity measures:

- Cyclomatic complexity, using a fixed tool and configuration such as ESLint complexity rules or `ts-complexity`
- Cognitive complexity, if supported by the chosen static-analysis tooling
- Maximum function complexity
- Mean function complexity across touched functions

Complexity will be computed on changed source files and, where possible, on functions touched by the PR.

#### 2. Diff similarity to `C_final`

Measures whether `C_llm` moves toward the final accepted PR state.

Candidate metrics:

- Tree-edit distance where practical
- Token-level edit distance
- Line-level normalized diff distance

Primary convergence score:

```text
1 - distance(C_llm, C_final) / distance(C_test, C_final)
```

A positive score indicates that `C_llm` is closer to `C_final` than `C_test` is. A score near 0 indicates no movement toward `C_final`. A negative score indicates movement away from `C_final`.

This metric tests convergence toward the reviewer-mediated final state, not absolute quality.

#### 3. Human merge-readiness ranking

Independent reviewers will evaluate unlabeled diffs from `C_base` to:

- `C_test`
- `C_llm`
- `C_final`
- optionally `C_random`

Reviewers will rank the versions by merge-readiness and may also provide a short categorical rationale.

Reviewers will not see:

- Original PR discussion
- Commit history after `C_test`
- Which version was produced by the LLM
- Which version was final
- Other reviewers' rankings

#### 4. Lines of code delta

Net LOC change from `C_test` to:

- `C_llm`
- `C_final`
- `C_random`

LOC is not treated as a quality measure by itself. It is included to distinguish simplification from mere expansion or compression.

#### 5. Correctness and failure mode

Each LLM output will be classified by test outcome and qualitative failure mode.

Test outcome categories:

- **Passes tests:** `C_llm` remains in the tested equivalence class.
- **Fails tests:** `C_llm` breaks at least one relevant test.
- **Cannot run:** test execution fails for environmental reasons not attributable to the refactor.

Failure-mode categories for non-passing LLM outputs:

- **Directionally useful but broken:** refactor appears to simplify or clarify the code, but introduces a localized correctness issue.
- **Behaviorally unsafe:** refactor changes semantics in a way that tests catch and the change is not plausibly a small repair.
- **Non-simplifying churn:** refactor changes code without clear simplification or convergence.
- **Invalid output:** code does not compile, files are missing, or the patch cannot be applied.
- **Environment failure:** failure appears caused by test infrastructure rather than the refactor.

Failed refactors are not excluded from the primary dataset. They are analyzed as failures and classified separately.

## Procedure

For each sampled PR:

1. **Extract snapshots.**
   Identify `C_base`, `C_test`, and `C_final` according to the definitions above.

2. **Classify post-`C_test` changes.**
   Categorize the human-authored delta from `C_test` to `C_final`.

   Categories may include:

   - Simplification or refactoring
   - Bug fix
   - API adjustment
   - Test adjustment
   - Naming or style change
   - Reviewer-requested maintainability change
   - Documentation or comments
   - Mechanical formatting
   - Other

   This classification is used to interpret whether convergence toward `C_final` reflects simplification, correctness repair, style alignment, or some other review-driven change.

3. **Prepare clean-room workspace.**
   Copy the repository at `C_test` to a temporary workspace such as `/tmp`.

   The clean-room workspace must:

   - Exclude `.git`
   - Exclude PR metadata
   - Exclude reviewer comments
   - Exclude subsequent commits
   - Disable network access during LLM execution and test execution
   - Use already-resolved dependencies where possible

   Since tests pass at `C_test`, the refactoring task should not require external references or network access.

4. **Generate LLM refactoring.**
   Prompt the LLM to refactor for clarity, simplicity, maintainability, and local idiom while preserving behavior.

   The LLM may inspect the full clean-room repository context. It may not access:

   - Reviewer comments
   - Later commits
   - The final accepted PR state
   - Git history
   - The internet

   The exact prompt, model name, model version, decoding parameters, and tool permissions will be recorded.

5. **Construct `C_llm`.**
   Apply the LLM's changes to the clean-room copy and save the resulting working tree.

   If the LLM produces no applicable patch, classify the trial as invalid output.

6. **Verify correctness.**
   Run the predetermined test command on `C_llm`.

   Test failures are retained in the dataset and classified by failure mode. Passing tests are not required for inclusion in the primary analysis, but correctness status is included in all interpretation.

7. **Generate random control.**
   Apply the predetermined random or mechanical transformation to `C_test`, producing `C_random`.

   Verify whether `C_random` passes tests. If it fails, record failure and classify the control as invalid for that PR.

8. **Measure static outcomes.**
   Compute complexity, diff similarity, and LOC metrics for `C_test`, `C_llm`, `C_final`, and `C_random`.

9. **Blind human review.**
   Present reviewers with unlabeled diffs from `C_base` to each candidate version.

   Each PR should be evaluated by at least 3 independent reviewers.

   Reviewers rank versions by merge-readiness and optionally provide categorical rationales.

10. **Record all metadata.**
    Record:

    - Repository
    - PR number
    - `C_base`, `C_test`, `C_final`
    - Model name and version
    - Model cutoff date
    - Prompt
    - Test command
    - Test outcome
    - Failure category, if any
    - Static-analysis tool versions
    - Reviewer IDs or anonymized reviewer labels
    - Review rankings
    - Notes on reconstruction issues

## Controls

### Null control

`C_test` itself.

This establishes the baseline state after tests first pass.

### Random/mechanical control

`C_random`, a semantics-preserving but non-simplifying transformation.

This tests whether metrics reward any change or specifically reward changes that plausibly simplify code or move toward the accepted PR state.

### Final accepted PR state

`C_final`.

This is the reviewer-mediated endpoint and is used as a convergence reference. It is not assumed to be globally optimal.

## Analysis

### Primary analyses

The three main outcomes are analyzed separately.

#### 1. Simplification

Question: Does `C_llm` reduce complexity relative to `C_test`?

Primary comparison:

```text
complexity(C_llm) - complexity(C_test)
```

Analyze with paired tests across PRs:

- Wilcoxon signed-rank test for continuous deltas
- Sign test for direction of improvement

Failed refactors remain in the dataset. Complexity may still be computed if the code parses. If the code does not parse, the trial is classified as invalid output and included in failure-rate reporting.

#### 2. Convergence toward `C_final`

Question: Does `C_llm` move closer to the final accepted PR state than `C_test`?

Primary comparison:

```text
distance(C_llm, C_final) < distance(C_test, C_final)
```

Analyze normalized convergence scores across PRs.

Compare `C_llm` against both:

- `C_test`
- `C_random`

This distinguishes meaningful convergence from arbitrary edit movement.

#### 3. Human merge-readiness

Question: Do blind reviewers rank `C_llm` as more merge-ready than `C_test`?

Primary comparison:

```text
rank(C_llm) > rank(C_test)
```

Analyze reviewer rankings using a mixed-effects model with random effects for PR and reviewer.

A simpler paired sign-test analysis may also be reported for interpretability.

### Mixed-effects model

For reviewer rankings, use a mixed-effects ordinal or logistic model, depending on final coding.

Candidate model:

```text
merge_ready_preference ~ version + test_status + PR_size + (1 | PR) + (1 | reviewer)
```

Where `version` distinguishes `C_test`, `C_llm`, `C_final`, and `C_random`.

The primary contrast is `C_llm` versus `C_test`.

### Inter-rater reliability

Compute inter-rater reliability for blind review rankings.

Candidate measures:

- Kendall's W for rank agreement
- Krippendorff's alpha if rankings or categorical judgments are transformed into ordinal labels

Low agreement will be reported as a substantive result, not treated only as noise.

### Failure analysis

Report the LLM failure rate across all sampled PRs.

Failure reporting includes:

- Fraction of `C_llm` outputs that pass tests
- Fraction that fail tests
- Fraction that cannot be applied
- Failure-mode category distribution
- Whether failed refactors nevertheless reduce measured complexity
- Whether failed refactors are judged directionally useful by reviewers, where review is possible

This separates "the model had the right refactoring idea but broke behavior" from "the model produced non-useful churn."

### Secondary analyses

#### Review-round correlation

Test whether LLM improvement correlates with the number of review rounds in the original PR.

Outcomes:

- Complexity reduction magnitude
- Convergence score
- Human preference for `C_llm` over `C_test`

If LLMs recover more of the delta on PRs with more review rounds, that suggests they capture part of what reviewers enforce.

#### Post-`C_test` change-type interaction

Analyze whether LLM performance differs depending on the dominant human-authored post-`C_test` change type.

For example, LLMs may perform better on simplification and naming changes than on subtle bug fixes or API adjustments.

#### Correctness-sensitive analysis

Repeat primary analyses on the subset where `C_llm` passes tests.

This subset analysis is secondary. The full dataset, including failures, remains the primary basis for evaluating the refactoring pass as an autonomous workflow.

## Pilot

The pilot consists of 5 PRs.

The pilot is used to answer feasibility questions:

1. Can `C_base`, `C_test`, and `C_final` be reconstructed reliably?
2. Can tests be run reproducibly in the clean-room environment?
3. Does the prompt produce applicable patches?
4. Are the complexity and diff metrics stable enough to compute?
5. Can blind reviewers evaluate the diffs in reasonable time?
6. Are the PR size bounds appropriate?

The pilot will not be used to stop early for efficacy or futility.

Any procedural changes after the pilot will be documented before the main 30-PR sample is evaluated.

## Predictions

### P1: Complexity reduction

`C_llm` will have lower measured complexity than `C_test` in at least 70% of trials where the LLM output parses.

### P2: Convergence toward accepted PR state

`C_llm` will be closer to `C_final` than `C_test` is, by the primary normalized tree/token/line-edit metric, in at least 60% of trials.

### P3: Human merge-readiness

Blind reviewers will rank `C_llm` above `C_test` in at least 65% of reviewer-PR judgments.

### P4: Non-identity with final state

`C_llm` will not exactly match `C_final` in any trial.

The equivalence class is expected to be large. A successful LLM refactor may find a different simple implementation than the one produced through human review.

### P5: Failure modes are informative

Some LLM refactors will fail tests while still being directionally useful. These cases will cluster separately from non-simplifying churn or invalid output.

## Threats to validity

### Final PR state is an imperfect proxy

`C_final` is not necessarily the simplest or best possible implementation. It is the version accepted by reviewers under real project constraints.

This study therefore treats convergence toward `C_final` as one outcome, separate from measured simplification and blind human merge-readiness.

### Test suites are incomplete

Passing tests does not prove semantic equivalence. This study uses project tests as the available behavioral predicate, while recognizing that reviewers may catch issues tests miss.

### Reviewer judgments may vary

Merge-readiness is partly subjective. The study uses multiple independent reviewers and reports inter-rater reliability.

Disagreement among reviewers is itself informative about whether the complexity axis is well-defined.

### Leakage

The LLM must not see reviewer comments, later commits, PR metadata, git history, or internet resources.

The clean-room procedure strips `.git`, copies only the `C_test` tree, and disables network access.

### Training contamination

Only PRs merged after the model's training cutoff are eligible.

The model version and cutoff date are recorded before sampling.

### Environment reconstruction

Historical test environments may be hard to reproduce. PRs whose `C_test` status cannot be reconstructed reproducibly are excluded before assignment.

### Metric validity

Cyclomatic complexity, LOC, and edit distance are incomplete proxies for maintainability. This is why the study keeps static metrics, convergence metrics, and human review as separate outcomes.

## What this would show

### If confirmed

LLMs can autonomously improve the complexity trajectory of brownfield contributions after tests pass.

The practical implication is that coding agents should include a refactoring pass after achieving correctness and before requesting review. This could reduce review burden by pre-resolving some cleanup and maintainability feedback.

### If partially confirmed

Different outcome patterns imply different conclusions:

- If complexity improves but reviewers do not prefer `C_llm`, the model may be optimizing shallow simplicity rather than merge-readiness.
- If `C_llm` moves toward `C_final` but complexity does not improve, reviewer changes may reflect style, API fit, or correctness rather than simplification.
- If reviewers prefer `C_llm` but it does not converge toward `C_final`, the model may find alternative acceptable members of the equivalence class.
- If failed refactors are directionally useful but often break tests, the bottleneck is execution reliability rather than refactoring judgment.

### If refuted

The complexity axis may require contextual judgment that LLMs lack without reviewer feedback. Reviewers may not merely be asking for less complexity; they may be asking for project-specific tradeoffs that are difficult to infer from code alone.

## Registered: 2026-04-14
