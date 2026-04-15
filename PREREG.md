# Can LLMs reduce complexity through refactoring to make PRs easier to merge?

## Hypothesis

For brownfield PRs, there exists an equivalence class of correct implementations: multiple implementations pass the same tests, but differ in complexity, maintainability, and fit with the surrounding codebase. The first implementation that passes tests is often not the version that reviewers are willing to merge. Human reviewers frequently push contributors toward simpler or more idiomatic members of this equivalence class before approval.

We hypothesize that LLMs, given only the "tests first pass" snapshot and a refactoring prompt, can move an implementation toward a more merge-ready state without access to reviewer feedback or subsequent commits.

This study deliberately separates three related claims:

1. **Simplification claim:** Does the LLM reduce measured code complexity relative to the tests-first-pass snapshot?
2. **Convergence claim:** Does the LLM move the code closer to the final accepted PR state?
3. **Merge-readiness claim:** Do independent human reviewers judge the LLM-refactored version as more merge-ready than the tests-first-pass version?

The final accepted PR state is treated as an important empirical reference point, not as a perfect proxy for optimal code quality.

## Estimand

The target estimand is the effect of an autonomous post-tests-pass LLM refactoring pass on **merged brownfield PRs with substantive post-tests-pass revision**.

The study does not estimate effects for:

- All PRs
- Greenfield examples
- Unmerged PRs
- PRs with no meaningful post-tests-pass revision
- PRs where review changes are primarily documentation, formatting, or dependency churn
- PRs whose relevant test predicate cannot be reconstructed

All claims are scoped to the sampled class of merged brownfield PRs where the contributor reached a passing-test implementation before the final accepted PR state and where subsequent human-authored revisions made substantive code changes.

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

## Snapshot Definitions

For each sampled PR, define the following commits or working-tree states.

### `C_base`

The pre-PR base commit against which the PR was originally opened or the closest reconstructable ancestor before the PR's changes.

All diffs shown to reviewers are computed relative to `C_base`.

### `C_test`

The earliest commit in the PR branch where the relevant test suite passes after the core implementation is present.

Operationally:

1. Define the relevant test command before traversing the PR branch.
2. Traverse commits in chronological order from `C_base` through the PR branch.
3. Identify candidate commits where the implementation under test is present.
4. "Implementation present" means the PR's main behavioral change has been implemented, even if later commits clean it up, rename it, improve edge cases, or revise tests.
5. Run the predetermined test command on each candidate commit.
6. Record all candidate commits where the implementation is present and the predetermined test command passes.
7. Select the first such passing candidate as `C_test`.

If the exact historical CI environment cannot be reconstructed, the local test command and environment will be recorded. PRs whose test status cannot be determined reproducibly will be excluded before assignment.

### `C_final`

The final accepted PR head before merge.

This is not necessarily the repository merge commit. It is the final state of the PR branch that reviewers accepted.

### `C_llm`

The LLM-refactored version produced from `C_test` under the clean-room procedure.

The LLM may edit only source files that were changed in the PR diff from `C_base` to `C_test`. It may not edit tests. This restriction will be mechanically enforced when constructing `C_llm`.

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
- `C_final`
- `C_random`, where available

The primary complexity scope is the union of source files touched by any of:

- `C_test`
- `C_llm`
- `C_final`

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

Complexity may also be reported on the parseable-only subset as a secondary analysis, but primary analyses count invalid or failed outputs as worst-score outcomes.

### 2. Diff similarity to `C_final`

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

Convergence will be reported both:

- Overall across all sampled PRs
- On the subset where the dominant post-`C_test` delta is simplification, refactoring, naming, style, or maintainability cleanup

PRs whose dominant post-`C_test` delta is correctness repair, API adjustment, test change, or another non-refactoring category will be analyzed separately.

### 3. Human merge-readiness preference

Independent reviewers will evaluate unlabeled diffs from `C_base`.

Only test-passing `C_llm` outputs are shown to reviewers. Failed, invalid, unparsable, forbidden-edit, or non-applicable LLM outputs are not reviewed and are automatically scored as "reviewer prefers `C_test`" for the primary prediction. This avoids the contradiction of telling reviewers to "assume tests pass" for code that actually fails tests. The passing-only subset is reported as a secondary analysis.

The primary review instrument is pairwise forced choice between:

- `C_test`
- `C_llm`

Reviewers answer:

```text
Assuming tests pass, which version would you approve for merge?
```

Reviewers must choose one version. They may also provide a short categorical rationale.

Reviewers will separately record whether either version raises a semantic concern. This semantic-concern flag is distinct from merge-readiness preference.

`C_final` will not be included in the same primary forced-choice ranking. It will be evaluated in a separate calibration task to estimate whether reviewers recognize the accepted PR state as merge-ready under the blind review procedure.

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

Net LOC change from `C_test` to:

- `C_llm`
- `C_final`
- `C_random`

LOC is not treated as a quality measure by itself. It is included to distinguish simplification from mere expansion or compression.

### 5. Correctness and failure mode

Each LLM output will be classified by test outcome and qualitative failure mode.

Test outcome categories:

- **Passes tests:** `C_llm` remains in the tested equivalence class.
- **Fails tests:** `C_llm` breaks at least one relevant test.
- **Cannot run:** test execution fails for environmental reasons not attributable to the refactor.

Failure-mode categories for non-passing LLM outputs:

- **Directionally useful but broken:** refactor appears to simplify or clarify the code, but introduces a localized correctness issue.
- **Behaviorally unsafe:** refactor changes semantics in a way that tests catch and the change is not plausibly a small repair.
- **Non-simplifying churn:** refactor changes code without clear simplification or convergence.
- **Invalid output:** code does not compile, files are missing, forbidden files are edited, the patch cannot be applied, or the output violates the mechanical edit restrictions.
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

   The dominant category will be recorded. Secondary categories may also be recorded if the final coder rules permit multi-label classification.

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

   The LLM may not edit tests. It may only edit files changed in the PR diff from `C_base` to `C_test`. These restrictions will be mechanically enforced after generation by rejecting or trimming edits outside the allowed file set according to the locked pilot procedure.

   The exact prompt, model name, model version, decoding parameters, tool permissions, and allowed file set will be recorded.

5. **Construct `C_llm`.**
   Apply the LLM's changes to the clean-room copy and save the resulting working tree.

   If the LLM produces no applicable patch, edits forbidden files, edits tests, or cannot be applied, classify the trial as invalid output.

6. **Verify correctness.**
   Run the predetermined test command on `C_llm`.

   Test failures are retained in the dataset and classified by failure mode. Passing tests are not required for inclusion in the primary analysis, but correctness status is included in all interpretation.

7. **Generate random control.**
   Apply the predetermined random or mechanical transformation to `C_test`, producing `C_random`.

   Verify whether `C_random` passes tests. If it fails, record failure and classify the control as invalid for that PR.

8. **Measure static outcomes.**
   Compute complexity, diff similarity, LOC, and secondary diagnostics for `C_test`, `C_llm`, `C_final`, and `C_random`.

9. **Blind human review.**
   Present reviewers with unlabeled diffs from `C_base`.

   The primary task is pairwise forced choice between `C_test` and `C_llm`.

   Each PR should be evaluated by at least 3 independent reviewers.

   Reviewers answer which version they would approve for merge assuming tests pass, record semantic concerns separately, and optionally provide categorical rationales.

   `C_final` is evaluated separately in a calibration task, not in the same primary ranking.

10. **Post-ranking blinding check.**
    After submitting judgments, reviewers answer whether they believed any version was final, LLM-generated, or otherwise identifiable.

11. **Record all metadata.**
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

This tests whether metrics reward any change or specifically reward changes that plausibly simplify code or move toward the accepted PR state.

### Final accepted PR state

`C_final`.

This is the reviewer-mediated endpoint and is used as a convergence reference and separate calibration target. It is not assumed to be globally optimal and is not included in the primary `C_test` versus `C_llm` forced-choice task.

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

The primary denominator is all trials. Failed, invalid, unparsable, forbidden-edit, or non-applicable LLM outputs are counted as worst-score outcomes for the primary simplification prediction.

Complexity may still be computed if the code parses. Parseable-only analysis will be reported as secondary.

### 2. Convergence toward `C_final`

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

The primary denominator is all trials. Failed, invalid, unparsable, forbidden-edit, or non-applicable LLM outputs are counted as worst-score outcomes for the primary convergence prediction.

Convergence will be reported:

- Overall
- On the subset where the dominant post-`C_test` delta is simplification, refactoring, naming, style, or maintainability cleanup
- Separately for PRs where the dominant post-`C_test` delta is correctness repair, API adjustment, test change, or another non-refactoring category

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

The primary denominator is all reviewer-PR judgments. Failed, invalid, unparsable, forbidden-edit, or non-applicable LLM outputs are counted as worst-score outcomes for the primary merge-readiness prediction.

Semantic-concern flags are analyzed separately from merge-readiness preference.

### Mixed-effects model

For reviewer preferences, use a mixed-effects logistic model.

Candidate model:

```text
prefer_llm_over_test ~ test_status + PR_size + post_C_test_change_type + (1 | PR) + (1 | reviewer)
```

The primary estimand is the intercept-adjusted preference for `C_llm` over `C_test` in the forced-choice task.

For calibration tasks involving `C_final` or `C_random`, ordinal or logistic models may be used depending on the final coding.

### Inter-rater reliability

Compute inter-rater reliability for blind review judgments.

Candidate measures:

- Agreement rate on pairwise forced choice
- Fleiss' kappa or Krippendorff's alpha for categorical preference labels
- Kendall's W if any secondary ranking task is used

Low agreement will be reported as a substantive result, not treated only as noise.

### Failure analysis

Report the LLM failure rate across all sampled PRs.

Failure reporting includes:

- Fraction of `C_llm` outputs that pass tests
- Fraction that fail tests
- Fraction that cannot be applied
- Fraction that violate edit-scope restrictions
- Failure-mode category distribution
- Whether failed refactors nevertheless reduce measured complexity
- Whether failed refactors are judged directionally useful by reviewers, where review is possible

This separates "the model had the right refactoring idea but broke behavior" from "the model produced non-useful churn."

### Secondary analyses

### Review-round correlation

Test whether LLM improvement correlates with the number of review rounds in the original PR.

Outcomes:

- Complexity reduction magnitude
- Convergence score
- Human preference for `C_llm` over `C_test`

If LLMs recover more of the delta on PRs with more review rounds, that suggests they capture part of what reviewers enforce.

### Post-`C_test` change-type interaction

Analyze whether LLM performance differs depending on the dominant human-authored post-`C_test` change type.

For example, LLMs may perform better on simplification and naming changes than on subtle bug fixes or API adjustments.

### Correctness-sensitive analysis

Repeat primary analyses on the subset where `C_llm` passes tests.

This subset analysis is secondary. The full dataset, including failures, remains the primary basis for evaluating the refactoring pass as an autonomous workflow.

### Parseable-only analysis

Repeat static metric analyses on the subset where `C_llm` parses and metrics can be computed.

This subset analysis is secondary. The primary denominator remains all trials, with invalid or unparsable outputs counted as worst-score outcomes.

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

The pilot will not be used to stop early for efficacy.

Any procedural changes after the pilot will be documented before the main 30-PR sample is evaluated.

## Pilot Decisions

The following items will be decided and locked after the pilot and before the main sample is drawn:

1. **Exact distance metric.**
   Lock whether the primary convergence metric uses tree-edit distance, token-level edit distance, line-level normalized diff distance, or a specified fallback sequence.

2. **Complexity tool and configuration.**
   Lock the static-analysis tool, version, parser settings, ignored files, thresholds, and aggregation rules.

3. **Review presentation format.**
   Lock syntax highlighting, side-by-side versus sequential presentation, file-path display, diff context, and any reviewer UI constraints.

4. **Reviewer population criteria.**
   Lock reviewer experience criteria, familiarity requirements, exclusion criteria, compensation, and assignment procedure.

5. **`C_random` generator specifics.**
   Lock the transformation family, edit budget, random seed policy, validation procedure, and invalid-control handling.

6. **Repo expansion criteria.**
   Lock whether additional repositories will be added and the criteria for doing so.

7. **PR size bound adjustments.**
   Lock any changes to minimum or maximum changed-source-line thresholds.

8. **Classification coder rules.**
   Lock whether post-`C_test` change classification is single-label or multi-label, the number of coders, adjudication procedure, and reliability reporting.

## Futility Conditions

The study may be deemed infeasible, or redesigned before main-sample execution, if the pilot or early extraction process shows any of the following:

1. **`C_test` reconstruction failure is too high.**
   More than 40% of otherwise eligible PRs cannot yield a defensible tests-first-pass snapshot.

2. **Tests are not reproducible often enough.**
   More than 30% of otherwise eligible PRs cannot run the predetermined relevant tests reproducibly.

3. **LLM outputs are too often invalid or trivial.**
   More than 40% of LLM outputs are invalid, non-applicable, forbidden-scope edits, empty/no-op edits, or trivial churn.

4. **Reviewers cannot evaluate the diffs.**
   Reviewers report that the blind diffs are too large, too context-dependent, or too ambiguous to support meaningful merge-readiness judgments.

5. **Metrics are inapplicable.**
   Complexity or distance metrics cannot be computed for a large enough share of cases to support the planned primary analyses.

6. **Post-`C_test` deltas are usually not refactoring-related.**
   Most eligible PRs have dominant post-`C_test` changes that are correctness fixes, API changes, test changes, or other non-refactoring work, making the convergence outcome poorly aligned with the study question.

7. **`C_random` cannot be generated reliably.**
   The random/mechanical control cannot be generated without frequent behavioral breakage, accidental simplification, or invalid edits.

These are feasibility and design-validity conditions, not efficacy stopping rules.

## Predictions

### P1: Complexity reduction

`C_llm` will have lower measured complexity than `C_test` in at least 70% of all trials.

The denominator is all trials. Invalid, failed, unparsable, forbidden-edit, or non-applicable LLM outputs count as not reducing complexity. A parseable-only result may be reported as secondary.

### P2: Convergence toward accepted PR state

`C_llm` will be closer to `C_final` than `C_test` is, by the primary locked distance metric, in at least 60% of all trials.

The denominator is all trials. Invalid, failed, unparsable, forbidden-edit, or non-applicable LLM outputs count as not converging.

### P3: Human merge-readiness

Blind reviewers will prefer `C_llm` over `C_test` in at least 65% of all reviewer-PR forced-choice judgments.

The denominator is all reviewer-PR judgments. Invalid, failed, unparsable, forbidden-edit, or non-applicable LLM outputs count as not preferred.

### P4: Non-identity with final state

`C_llm` will not exactly match `C_final` in any trial.

The equivalence class is expected to be large. A successful LLM refactor may find a different simple implementation than the one produced through human review.

### P5: Failure modes are informative

Some LLM refactors will fail tests while still being directionally useful. These cases will cluster separately from non-simplifying churn or invalid output.

## Misleading-Result Scenarios

The study will explicitly guard against the following misleading interpretations:

1. **Metric-only simplification.**
   `C_llm` may reduce cyclomatic or cognitive complexity while making the code less idiomatic, less maintainable, or less merge-ready.

2. **Convergence without improvement.**
   `C_llm` may move closer to `C_final` because it copies superficial structure or style, not because it improves the underlying implementation.

3. **Divergence despite quality.**
   `C_llm` may be a good alternative implementation that reviewers prefer, while still not resembling `C_final`.

4. **Final-state overinterpretation.**
   `C_final` may reflect reviewer preference, time pressure, API constraints, or local compromise rather than optimal code quality.

5. **Correctness hidden by tests.**
   A refactor may pass the project tests while introducing semantic risk that reviewers notice or that tests fail to cover.

6. **Invalid-output denominator masking.**
   Parseable-only or passing-only analyses may overstate model usefulness by excluding failed autonomous refactoring attempts.

7. **Review blinding failure.**
   Reviewers may infer which version is LLM-generated or final based on style, polish, or diff shape, biasing merge-readiness judgments.

8. **Change-type mismatch.**
   Apparent non-convergence may occur because the human post-`C_test` delta was primarily correctness repair, API negotiation, or test adjustment rather than simplification.

These scenarios will be discussed in interpretation regardless of whether the primary predictions are confirmed.

## Threats to Validity

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

The clean-room procedure strips `.git`, copies only the `C_test` tree, disables network access, and mechanically enforces the allowed edit set.

### Training contamination

Only PRs merged after the model's training cutoff are eligible.

The model version and cutoff date are recorded before sampling.

### Environment reconstruction

Historical test environments may be hard to reproduce. PRs whose `C_test` status cannot be reconstructed reproducibly are excluded before assignment.

### Metric validity

Cyclomatic complexity, LOC, and edit distance are incomplete proxies for maintainability. This is why the study keeps static metrics, convergence metrics, and human review as separate outcomes.

### Scope restriction

The estimand is limited to merged brownfield PRs with substantive post-tests-pass revision. The results should not be generalized to all PRs, all repositories, greenfield tasks, or changes without meaningful review-driven revision.

## What This Would Show

### If confirmed

LLMs can autonomously improve the complexity trajectory of merged brownfield contributions after tests pass, within the scoped class of PRs studied.

The practical implication is that coding agents should include a refactoring pass after achieving correctness and before requesting review. This could reduce review burden by pre-resolving some cleanup and maintainability feedback.

### If partially confirmed

Different outcome patterns imply different conclusions:

- If complexity improves but reviewers do not prefer `C_llm`, the model may be optimizing shallow simplicity rather than merge-readiness.
- If `C_llm` moves toward `C_final` but complexity does not improve, reviewer changes may reflect style, API fit, or correctness rather than simplification.
- If reviewers prefer `C_llm` but it does not converge toward `C_final`, the model may find alternative acceptable members of the equivalence class.
- If failed refactors are directionally useful but often break tests, the bottleneck is execution reliability rather than refactoring judgment.
- If performance is concentrated only on the simplification/refactoring subset, the autonomous refactoring pass may be useful but narrower than the full post-review revision process.

### If refuted

The complexity axis may require contextual judgment that LLMs lack without reviewer feedback. Reviewers may not merely be asking for less complexity; they may be asking for project-specific tradeoffs that are difficult to infer from code alone.

## Registered: 2026-04-14
