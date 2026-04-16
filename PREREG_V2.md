# Does an LLM refactoring pass help or hurt brownfield PRs? v2

## Changes from v1

This v2 preregistration keeps the v1 estimand and within-PR comparison structure, but incorporates the pilot-locked changes below.

1. **Volley is goal-anchored and prescriptive.** The refactor spec is generated from a goal plus artifact pair: linked issue(s), PR title, and PR body are the goal; the diff from `C_base` to `C_test` is the artifact. Claims must describe changes that move the artifact closer to the goal. An empty Accepted Claims list is allowed and is itself a finding. (v2 change: locked V1)
2. **Adversarial reconcile is mandatory-reject on blockers.** Any blocker finding from hunt-spec moves the parent claim to Rejected. The reconciler may narrow warnings but may not narrow or retain blocker findings. (v2 change: locked V2)
3. **A complexity gate is inserted after blind-blind-merge.** If scoped mean cognitive complexity for the merged candidate exceeds `C_test` by more than `delta = 0.05`, the candidate is rejected and the trial falls back to `C_test` as a no-op. (v2 change: locked S1)
4. **Hunt-code must run the full build plus tests.** It may not rely on typecheck-only validation. The default commands are `npm run build` plus tests for TypeScript, `go build ./...` plus `go test ./...` for Go, `cargo build` plus tests for Rust, and repo-specific install plus test commands for Python. (v2 change: locked S2)
5. **Eligibility is restricted to large PRs.** The minimum source-line threshold is 500 changed source lines from `C_base` to `C_test` after exclusions. This is both the experiment eligibility floor and the blind-blind precondition. There is no single-agent path for smaller PRs. (v2 change: locked S4 + C3)
6. **The maximum source-line bound is raised to 5000.** The previous 2000-line ceiling is replaced by 5000 source lines to admit large but still reviewable PRs. (v2 change: locked C3 cap)
7. **Hunt-code remains broad-scope and iterative.** It follows the bug-hunt default: hunt, address findings, re-hunt until zero findings, with expected convergence in one pass for most PRs. (v2 change: locked S5)
8. **A reviewer loop is inserted before shipping `C_llm`.** Gemini 3.1 Pro reviews the candidate, the implementer addresses comments, and Gemini re-reviews. Iteration stops at zero comments or when comment-count shrinkage stops, with hard cap `N = 10`. The same Gemini model is also used in downstream Phase 7 review, and the resulting pre-approval bias is acknowledged. (v2 change: locked S6)
9. **P2 and P3 use both parity nulls and improvement thresholds.** P2 parity null: past in `[25%, 45%]`, short in `[40%, 55%]`, wrong in `[10%, 20%]`; improvement threshold: past at least 50%. P3 parity null: prefer-`C_llm` rate in `[40%, 60%]`; improvement threshold: at least 65%. (v2 change: locked R1)
10. **Survivorship bias is explicit.** The estimand is restricted to drafts of merged brownfield PRs. This makes positive results on P1, P2, and P3 conservative, but understates real-world slop-slope prevalence for P4. (v2 change: locked R5)

All pilot-derived changes from improvements.md are now incorporated as **locked** in v2: V3 implementation evidence, V4 per-language spec templates (kept short), C1 pre-selection feasibility checks, C2 source-only revision-in-scope refinement, R2 single reviewer is sufficient, R3 precise no-op classes, R4 per-language scaffolding cost (logged, not formalized), O1 serialized test runs across PRs, O2 per-PR Python venv manifests, and O3 raw measurement JSON saved per snapshot.

Design heuristic: this prereg favors **simpler over rigorous**. The goal is to provide evidence either way for v2's hypotheses, not to produce paper-grade statistics. Formal tests (paired Wilcoxon, mixed-effects) are reported only if rates are close to threshold.

## Hypothesis

For brownfield PRs, there exists an equivalence class of correct implementations: multiple implementations pass the same tests, but differ in complexity, maintainability, and fit with the surrounding codebase. The first implementation that passes tests is often not the simplest member of the class.

An LLM refactoring pass after tests pass will move the implementation within this equivalence class. The question is which direction. Two claims, tested independently:

1. **Simplification claim:** Does the LLM reduce measured code complexity relative to the tests-first-pass snapshot?
2. **Merge-readiness claim:** Do independent reviewers judge the LLM-refactored version as more merge-ready than the tests-first-pass version?

If both confirm, a refactoring pass is worth adding to agent workflows. If the LLM reduces complexity but reviewers do not prefer it, the agent is optimizing a metric that does not match taste. If reviewers prefer it but complexity increases, the agent is doing something useful that metrics do not capture. If both refute - the agent makes things worse while passing tests - that is the **slop-slope** (Dexter Horthy's term for the tendency of automated changes to increase codebase complexity despite passing tests) confirmed as default behavior, and the most important finding.

## Estimand

The target estimand is the effect of a forge-wrapped autonomous post-tests-pass LLM refactoring pass on **drafts of merged brownfield PRs with substantive post-tests-pass source revision**. (v2 change: R5 locked survivorship-bias wording)

The study does not estimate effects for:

- All PRs
- Greenfield examples
- Unmerged PRs
- PRs with no meaningful post-tests-pass source revision in the measurement scope
- PRs where review changes are primarily documentation, formatting, generated files, tests, dependency churn, or lockfile churn
- PRs whose relevant test predicate cannot be reconstructed
- PRs below the 500 changed-source-line eligibility floor

All claims are scoped to the sampled class of merged brownfield PRs where the contributor reached a passing-test implementation before the final accepted PR state and where subsequent human-authored revisions made substantive source-code changes. This is intentionally enriched for refactorable survivor drafts - PRs where reviewers found something worth changing after tests passed and the contributor-reviewer pair ultimately converged on an accepted version.

This survivorship-filtered population excludes drafts that were abandoned, rejected, closed without merge, or stuck in review indefinitely. Positive results on P1, P2, and P3 are therefore conservative because the sample is biased toward already-viable drafts with less remaining room for improvement. Negative slop-slope prevalence in P4 is likely understated relative to arbitrary agent output in the wild. (v2 change: locked R5)

## Background

Every PR in a collaborative codebase implicitly navigates three axes:

1. **Predicate** - does the approach work at all?
2. **Transformation** - does the code implement it correctly?
3. **Complexity trajectory** - does this change leave the codebase simpler or more complex than it found it?

Axes 1 and 2 are partially testable. Axis 3 is often enforced through review feedback, style norms, maintainability expectations, and local codebase judgment.

If LLMs can improve axis 3 autonomously after tests pass, then coding agents should include a refactoring pass before submitting for review. Reviewers would still make the final judgment, but less of their time would be spent requesting routine simplification.

If LLMs cannot improve axis 3 without reviewer feedback, that suggests the review bottleneck depends on contextual judgment that current models cannot infer reliably from the codebase alone.

The v1 pilot found that forge-wrapped refactors were often preferred over `C_test`, but rarely landed past `C_final`. Across the cross-repo pilot, P3 was strong on TypeScript and Go while P2 past-trajectory remained below improvement threshold, wrong-direction cases remained practically important, and Python setup cost was materially higher than Go or TypeScript. v2 therefore tightens prompt anchoring, adds blocker enforcement, adds build and complexity gates, raises the size floor, and adds an in-pipeline reviewer loop.

## Design

### Sampling

### Depth and breadth

One primary repo goes deep. Four secondary repos go shallow. If results on the primary repo are clear but secondary repos show ambiguity, expand n on the ambiguous secondaries.

- **Primary:** `google-gemini/gemini-cli` (TypeScript monorepo, 20+ contributors, active review culture). 15 PRs.
- **Secondary (3 PRs each, expandable to 10):**
  - `cli/cli` (Go) - GitHub's own CLI, strict review, fast `go test`, active review culture
  - `astral-sh/ruff` (Rust) - Python linter, strict review, comprehensive test suite
  - `django/django` (Python) - mature triage/merger workflow, regression tests required, decades of review culture
  - `fastapi/fastapi` (Python) - modern Python, strict typing, active post-cutoff

These repos are now preregistered for v2. If a repo becomes infeasible because current dependencies, historical tests, or CI reconstruction cannot be made reproducible within the registered timebox, it may be replaced only by a repo of equal caliber and the swap is recorded before extraction of the replacement begins. The selection criteria remain: language diversity, strict enforced review, at least 10 contributors, active post-cutoff, and reconstructable build/test commands.

**Build-time bias:** All selected repos have fast build/test cycles by ecosystem standards. This excludes heavyweight C++ projects and large compiler codebases where build times make per-trial iteration impractical. The experiment's results may not generalize to codebases where the build itself is the bottleneck.

### Registered repo tooling

The following defaults are committed before extraction. If a repo's CI reveals a narrower gating shard, the narrower shard may be used only if recorded before that repo's first sampled PR is run.

- `google-gemini/gemini-cli`: Node >= 22.x, `npm ci`, `npm run build`, repo test command from CI or `npm test` if CI has no narrower shard, TypeScript complexity via `scripts/measure_complexity.mjs` using `@typescript-eslint/typescript-estree`.
- `cli/cli`: Go toolchain from `go.mod`, `go build ./...`, `go test ./...`, Go cognitive complexity via `gocognit`, cyclomatic via `gocyclo`, formatting via `gofmt -w`.
- `astral-sh/ruff`: Rust toolchain from `rust-toolchain` or repo docs, `cargo build`, `cargo test`, formatting via `cargo fmt`, lint diagnostics via `cargo clippy` where feasible, complexity via `rust-code-analysis-cli`.
- `django/django`: Python version from repo CI, virtualenv per PR, install command from Django contributor docs, test command narrowed to affected apps where CI supports it, complexity via `radon cc --json`, cognitive complexity via `flake8-cognitive-complexity` or the `cognitive_complexity` package if the flake8 plugin cannot emit machine-readable per-function output.
- `fastapi/fastapi`: Python version from repo CI, virtualenv per PR, install from project dependency metadata, `pytest` with preregistered deselects for environment-dependent tests, complexity via `radon cc --json`, cognitive complexity via `flake8-cognitive-complexity` or the `cognitive_complexity` package if needed.

For each secondary language, the complexity tool version, test command, random-control transformation family, estimated environment setup cost, and fallback if the cost exceeds the timebox are recorded before extraction. (v2 change: proposed R4)

### Training-contamination restriction

Eligible PRs must have been merged after the latest training cutoff among models in use. v2 model cutoffs:

| Role | Model | Training cutoff |
|------|-------|-----------------|
| Generator (forge) | Claude Opus 4.6 | 2025-05 (Anthropic-documented) |
| Generator (forge) | Codex GPT-5.4 | 2025-08-31 (per v1) |
| Reviewer (in-pipeline + Phase 7) | Gemini 3.1 Pro Preview | 2025-09 (Google-documented) |
| Secondary reviewer | Claude Sonnet 4.5 | 2025-05 (Anthropic-documented) |
| Secondary reviewer | OpenAI GPT-5 | (to confirm before extraction) |

**Binding cutoff for eligibility: latest of all in-use cutoffs.** Under the v2 lineup above, that is **2025-09** (Gemini 3.1 Pro Preview). PRs eligible only if merged on or after 2025-10-01.

If the secondary GPT-5 cutoff is later than this, the binding cutoff is moved forward and any already-extracted PRs that fall before it are dropped from analysis. The cutoff is locked before main-sample extraction begins.

### Inclusion criteria

A PR is eligible if all of the following hold:

1. It was merged after the model's training cutoff.
2. It is a brownfield change to an existing codebase, not a purely new isolated example or generated fixture.
3. It has at least 2 review rounds or at least one substantive post-review revision.
4. Tests exist and pass at some commit before the final accepted PR head.
5. The delta between the tests-first-pass commit and the final accepted PR head includes non-trivial source changes in the measurement scope: allowed edit set intersected with non-test source files. (v2 change: proposed C2)
6. The post-tests-first-pass delta is not limited to typos, comments, formatting, dependency lockfile churn, generated files, fixtures, tests, or documentation-only edits.
7. The PR has a reviewable size under the v2 source-line bounds: at least 500 and at most 5000 changed source lines from `C_base` to `C_test`, after exclusions. (v2 change: locked S4 + C3)
8. Pre-selection feasibility checks pass: the registered test command passes at `C_final`; `git diff C_test C_final -- <source globs except tests>` is non-empty; and at least one source file remains after exclusions. (v2 change: proposed C1)

### PR size bounds

PR size bounds:

- Minimum: 500 changed source lines from `C_base` to `C_test`, post-exclusion.
- Maximum: 5000 changed source lines from `C_base` to `C_test`, post-exclusion.

Changed source lines are additions plus deletions counted by `git diff --numstat`, with the following exclusion globs applied (registered before extraction):

| Category | Glob patterns |
|---|---|
| Tests | `**/*_test.go`, `**/*.test.ts`, `**/*.test.tsx`, `tests/**/*.py`, `**/test_*.py`, `**/*_test.py`, `**/__snapshots__/**`, `**/*.snap` |
| Docs | `docs/**`, `**/*.md`, `**/README*` |
| Schemas | `schemas/**`, `**/*.schema.json` |
| Lockfiles | `**/package-lock.json`, `**/yarn.lock`, `**/Cargo.lock`, `**/uv.lock`, `**/poetry.lock`, `**/go.sum` |
| Generated | `**/dist/**`, `**/build/**`, `**/target/**`, `**/__pycache__/**`, `**/.next/**`, `**/_generated.go`, `**/*.pb.go` |
| Vendored | `**/vendor/**`, `**/third_party/**`, `**/node_modules/**` |
| Repo-specific | recorded per-repo before extraction (e.g., gemini-cli's `bundle/`) |

This list is applied to the `git diff` filter via `:(exclude)` patterns. Per-repo additions are appended to the registered list before that repo's first PR is sampled.

The size bound is applied at `C_test`, not `C_final`. A PR whose final accepted diff is within bounds but whose tests-first-pass draft exceeded 5000 source lines is excluded. A PR whose final accepted diff is below 500 lines but whose tests-first-pass draft was at least 500 source lines remains eligible if the post-tests-pass source revision is substantive.

When multiple eligible PRs are available, select from the top of the size-sorted candidate pool, subject to feasibility. A positive result on large PRs is maximally surprising: more code means more room for complexity to accumulate, more reviewer feedback to anticipate, and a larger equivalence class to navigate. If refactoring works there, smaller PRs are plausibly implied. (v2 change: locked C3)

### Sample size

Initial target: 27 **eligible** PRs (15 primary + 4×3 secondary), where "eligible" means surviving inclusion criteria 1-8 plus pre-selection feasibility checks.

Pilot exclusion rate was ~25-30% (4 of 13 cli/cli candidates excluded post-reconstruction; 1 of 3 fastapi). To absorb this, **pre-select more candidates than the eligibility target**:

```
candidates_to_pre_select = ceil(target_eligible / (1 - expected_exclusion_rate))

with expected_exclusion_rate = 0.30 (conservative based on pilot):
  primary: ceil(15 / 0.70) = 22 candidates pre-selected
  secondary: ceil(3 / 0.70) = 5 candidates pre-selected per repo
```

Pre-selection draws from the size-sorted candidate pool, top down. If still under-target after exhausting the pool, expand selection criteria as documented for that batch.

A dev/pilot set is used for feasibility and prompt iteration. Dev-set PRs do not enter the primary test-set analysis.

### Batch expansion for confidence

Results are evaluated in batches. After each batch, decide: stop because the signal is clear, or run another batch from the same repo.

- **Primary repo:** First batch is 15 PRs. If the three-class distribution and reviewer preference are unambiguous, stop. If ambiguous, run another batch of 10.
- **Secondary repos:** First batch is 3 PRs each. Expand a secondary repo to 10 PRs if forced-choice preference for `C_llm` drops below 50% at n=3, wrong-direction rate is at least 2 of 3, or there are zero "past" trials. (v2 change: inherited from pilot decision 6)

This is group sequential in spirit: look after each batch, expand if uncertain. Evidence compounds across batches. Post-expansion analyses from any repo are reported alongside pre-expansion results so the reader can see what changed.

No maximum sample size is fixed beyond the batch structure. The stopping rule is confidence, not a number. Each expansion decision and its rationale are recorded in the work log before the next batch begins.

## Snapshot Definitions

For each sampled PR, define the following commits or working-tree states.

### `C_base`

The pre-PR base commit against which the PR was originally opened or the closest reconstructable ancestor before the PR's changes.

All diffs shown to reviewers are computed relative to `C_base`.

### `C_test`

The earliest commit in the PR branch where the merge-time test suite passes.

The test suite that matters is the one that exists at `C_final` - that is the contract the reviewer accepted. `C_test` is found by backporting those tests onto earlier commits to find when the implementation first satisfied them.

Operationally:

1. Extract the test files from `C_final`.
2. Define the test command. For each repo, this is the CI command that gates merge or a preregistered relevant shard.
3. Traverse PR commits in chronological order from `C_base`.
4. At each commit, overlay the `C_final` test files onto the working tree and run the test command.
5. Record all commits where this combined state passes.
6. Select the earliest passing commit as `C_test`.

This ensures `C_test` and `C_final` are compared against the same behavioral contract. The LLM refactors implementation code, not tests, and the tests it must preserve are the ones the reviewer signed off on.

If the `C_final` tests cannot be overlaid cleanly onto earlier commits, the PR is excluded and the exclusion reason is recorded.

### `C_final`

The final accepted PR head before merge. Serves two roles:

1. **Test source:** the merge-time test suite is backported onto earlier commits to define `C_test`.
2. **Directional proxy:** `C_final` marks the direction reviewers pushed the code. It is not ground truth for optimal code, but if `C_llm` reaches or passes `C_final` on the complexity axis, that is strong evidence the refactoring pass is working. "Past it" is better than "toward it."

### `C_llm`

The LLM-refactored version produced from `C_test` under the clean-room procedure.

The LLM may edit source files changed in the PR diff from `C_base` to `C_test`. It may not edit tests. This is mechanically enforced when constructing `C_llm`.

`C_final` may touch additional files beyond `C_test`. The LLM is not given access to those files' identities, because knowing which files reviewers eventually changed is information leakage. If this restriction prevents valid simplifications, that biases against `C_llm`. It also means complexity comparisons to `C_final` are weakened when reviewers improved the PR by adding or moving code to files outside the `C_test` scope.

### `C_random`

A semantics-preserving but non-simplifying control transformation produced from `C_test`. Tests whether complexity metrics reward *any* change or specifically reward *simplification*. v1 pilot did not generate `C_random` for any trial; v2 commits to running it for the primary repo at minimum and flags secondary-repo coverage as proposed (R4).

**Per-language transformation families:**

- **TypeScript** (`gemini-cli`): local `let`/`const` renaming to `_a`/`_b`/...; independent statement reordering within basic blocks; redundant parenthesization on already-parenthesizable sub-expressions. Tool: `ts-morph` AST walker (registered before extraction).
- **Go** (`cli/cli`): local var renaming via `gorename`-style identifier swap; reorder independent `var` declarations in a block. Cannot reorder statements freely (Go's stricter scope rules); skip that transformation. Tool: `go/ast` walker.
- **Rust** (`ruff`): local binding renames; redundant parentheses on expressions. Statement reordering disabled (borrow-checker fragility). Tool: `syn` AST walker.
- **Python** (`django`, `fastapi`): local variable renames; reorder independent assignments in a block. No expression-level transforms (Python's expression grammar is too tight to wrap meaningfully without breaking tests). Tool: `ast` module + `astor`.

**Per-PR scaffolding:**
- Edit budget: 50% of `|C_llm - C_test|` LOC delta, rounded up to 10 lines, floor 10
- Random seed: `sha256(PR_number || "random" || attempt_N)` first 8 hex digits → decimal
- Validation: locked test command must pass; scoped mean cognitive complexity must not decrease by more than `δ=0.05`
- Invalid-control handling: regenerate with next seed up to 5 attempts; record invalid if all fail

**Decision on coverage:** v2 locks `C_random` for the primary repo (gemini-cli). For each secondary repo, `C_random` generation is conditional on the per-language transformation family compiling and producing valid controls within a 1-day timebox per repo. If timebox exceeded, `C_random` analyses for that repo are dropped from the v2 primary outcomes; this is reported in Trail Commitment.

## Variables

### Independent variable

LLM refactoring applied to the `C_test` snapshot via the v2 forge-wrapped procedure.

### Dependent variables

### 1. Complexity delta

Measured between:

- `C_test`
- `C_llm`
- `C_final` (directional proxy)
- `C_random`, where available

The primary complexity scope is the union of source files touched by `C_test` or `C_llm`.

This avoids measuring only the subset of files edited by one condition and prevents the LLM from appearing simpler merely by moving or avoiding changes outside the measured scope.

Primary complexity measure:

- Mean cognitive complexity across scoped functions, using the registered per-language tool, with `delta = 0.05` as the boundary threshold. (v2 change: inherited pilot decision 5)

Secondary diagnostics:

- Cyclomatic complexity
- Maximum function complexity
- Mean function complexity across touched functions
- Function count
- Maximum nesting depth
- Number of newly introduced abstractions
- LOC delta
- Number of touched files and touched functions

For TypeScript, the locked tool is `scripts/measure_complexity.mjs`, an AST walker built on `@typescript-eslint/typescript-estree`, run from inside the target cleanroom. For Go, Rust, and Python, tools are registered by language before extraction as listed in Design.

If the agent produces a hard no-op, `C_llm = C_test` and complexity delta is zero. If the agent produces a trivial no-op with zero source modifications, complexity delta is zero but the no-op class is recorded separately. (v2 change: proposed R3)

### 2. Direction relative to `C_final`

`C_final` is where reviewers pushed the code - a satisficing threshold, not the optimum. Each active trial is classified into one of three trajectory classes:

- **Past `C_final`:** simpler than the accepted version and the reviewer would still approve it. Simpler plus no new correctness or clarity concerns.
- **Short of `C_final`:** improved over `C_test` but leaves complexity that the accepted version removed. Better but not as good.
- **Wrong direction:** no meaningful improvement, worse complexity, worse merge-readiness, or semantic risk. The slop-slope.

**Primary classification: reviewer-judged.** After the pairwise forced choice, reviewers see `C_final` and classify `C_llm`'s trajectory relative to both `C_test` and `C_final`. This is the headline label.

**Scalar calibration:** Mean cognitive complexity across touched functions is computed for `C_test`, `C_llm`, and `C_final`. The scalar does not determine the class; it calibrates the reviewer judgment. Report:

- Agreement rate between reviewer label and scalar label
- Distance from boundary
- Cases where reviewer and scalar disagree

Differences smaller than `delta = 0.05` are flagged as boundary cases rather than forced into a scalar class.

**Sensitivity analysis:** Recompute scalar labels using cyclomatic complexity, nesting depth, function count, and LOC. Report the fraction of trials whose class is stable across metrics. Instability is a finding about metric validity.

Report the distribution across the three reviewer-classified categories. "Past `C_final`" is the strongest evidence; "wrong direction" is the most important finding.

### 3. Human merge-readiness preference

Independent reviewers evaluate unlabeled diffs from `C_base`.

Only test-passing active `C_llm` outputs are shown to reviewers. Hard no-op trials are automatically scored as "reviewer prefers `C_test`" for intent-to-treat. Trivial no-op trials are scored as tied for intent-to-treat. Out-of-scope no-ops have out-of-scope edits reverted; any remaining in-scope diff is reviewed or scored according to what remains. (v2 change: proposed R3)

The primary review instrument is pairwise forced choice between:

- `C_test`
- `C_llm`

Reviewers answer:

```text
Assuming tests pass, which version would you approve for merge?
```

Reviewers must choose one version for active diffs. They may also provide a short categorical rationale.

Reviewers separately record whether either version raises a semantic concern.

After the forced choice, reviewers are shown `C_final` labeled as "the version reviewers accepted" and asked to classify `C_llm`'s trajectory: past `C_final`, short of `C_final`, or wrong direction. This is the primary trajectory classification.

`C_random`, where available, may be used in secondary or calibration comparisons.

Reviewers receive:

- PR title
- PR body
- Linked issue title/body where available
- A neutral task description based on the PR's stated purpose
- Unlabeled diffs from `C_base` to each candidate version

Reviewers do not see:

- Original PR discussion
- Review comments
- Commit history after `C_test`
- Which version was produced by the LLM
- Which version was final during Phase 1
- Other reviewers' judgments

After completing the forced-choice task, reviewers answer a blinding check asking whether they believed any reviewed version was final, LLM-generated, or otherwise identifiable.

### 4. Lines of code delta

Net LOC change from `C_test` to `C_llm` and `C_random`. LOC is descriptive, not a quality measure.

### 5. Correctness gate

`C_llm` must pass the predetermined test command and full build command. Passing tests and builds is a precondition for membership in the equivalence class, not a variable. (v2 change: locked S2)

If the LLM agent cannot produce a build- and test-passing output, the trial is a hard no-op: `C_llm = C_test` for all metrics. The agent produced nothing usable. Report the hard no-op rate as a measure of agent competence, but do not analyze non-passing outputs further.

The interesting failure is not the agent that breaks tests. The interesting failure is the agent that passes tests and builds while making the codebase harder to maintain. That is the slop-slope this experiment is designed to detect.

## Procedure

### Dev/test separation

For each repo, PRs are split into a dev set used for prompt iteration and a test set used for evaluation. No PR may appear in both. The prompt is frozen before any test-set PR is evaluated. Dev-set results are published alongside test-set results but do not contribute to the primary analysis.

### Trail commitment

Everything produced by the pipeline is saved per-trial under `samples/<set>/<repo>-<pr>/` for posterior analysis. The published artifact is a complete reconstruction of every decision point — no summary-only outputs.

**Per-trial artifacts (saved per PR):**

```
samples/<set>/<repo>-<pr>/
  meta.json                      # PR number, repo, base/test/final SHAs, model versions
  goal/
    issue-<id>.md                # each linked issue's title+body
    pr-title.txt
    pr-body.md
  inputs/
    diff-base-to-test.patch      # the artifact (input to volley)
    allowed-files.txt
  volley/
    round-1-claims.md            # codex output round 1
    hunt-spec-round-1.md         # findings round 1
    round-2-claims.md            # if iterated
    hunt-spec-round-2.md
    ...
    sharpened-spec-final.md      # reconciled, post-iteration
  blind-blind/
    opus-dir.diff                # opus's diff vs C_test (full files too big; just patches)
    codex-dir.diff
    merge-decisions.json         # per-file: which model won and why
    merged.diff                  # final merged candidate vs C_test
  gates/
    complexity-gate.json         # mean cog at C_test + candidate, pass/fail
    hunt-code-round-1.md         # findings round 1
    hunt-code-round-2.md
    ...
    build-log.txt                # full build output at final candidate
    test-log.txt                 # full test output
  reviewer-loop/
    round-1-comments.md          # gemini's comments
    round-1-address.diff         # implementer's response diff
    round-2-comments.md
    ...
    final-state.txt              # converged | impasse | cap-hit
  c_llm/
    diff.patch                   # final C_llm vs C_test
    files/                       # full files of C_llm in allowed edit set
  c_random/                      # if generated
    diff.patch
    seed.txt
    validation.json
  measurements/
    c_test.json                  # raw measure_complexity output
    c_llm.json
    c_final.json
    c_random.json                # if available
  phase7/
    review-bundle.md             # what gemini saw
    review-assignment.json       # A/B order seed
    review-phase1.json           # forced choice + rationale + concerns
    review-phase23.json          # trajectory + blinding check
    sonnet-phase1.json           # if calibration-subset
    gpt5-phase1.json             # if calibration-subset
  no-op-class.txt                # hard | trivial | out-of-scope | none
  exclusion-reason.txt           # if excluded
  venv-requirements.txt          # Python only
```

**Cross-trial summaries:**

- Candidate-pool log: every PR considered for a batch, with include/exclude decision and reason
- Exclusion log aggregating per-trial exclusion-reason files
- Complexity-tool output JSON aggregated across all trials in a single CSV/JSON for analysis
- Per-language scaffolding-cost log (registered timebox vs actual)
- Reviewer-loop convergence stats: rounds-to-converge histogram per repo

**Why exhaustive:**

Posterior analysis (including reanalyses with new metrics, new reviewer models, or new statistical tests) needs to be possible without re-running the pipeline. Every artifact a future analyst might want is committed at trial-completion time. Cost: ~5-50 MB per trial; trivially within repo-size budget.

This extends v1's trail commitment which was prompt + diff + final-snapshot only. v2 saves the whole pipeline so that:
- Failed trials can be re-analyzed (e.g., "what would have happened if we used a different complexity tool?")
- Pipeline failures can be retroactively classified (e.g., "did hunt-spec catch this case?")
- Reviewer judgments can be re-collected with new models without re-running forge
- The forge pipeline itself can be evaluated in isolation from the experiment outcome

**v2 change: extends V1 trail commitment** with full per-trial artifact capture. Pulls in O2 (Python venv manifest) and O3 (complexity JSON) as locked, plus pipeline-stage transcripts (volley rounds, hunt rounds, reviewer-loop iterations) which were not in v1.

### v3-prep: live anomaly capture

Secondary goal of v2: leave enough procedural evidence for a v3 prereg if v2's results motivate one. The trail commitment above captures *what happened*; this section captures *what surprised us about it*.

**Per-trial: anomaly notes.** Each trial directory includes:

```
samples/<set>/<repo>-<pr>/
  anomalies.md      # free-text observations during the trial: "reviewer
                    # comment style was unusual", "implementer needed 8
                    # rounds, all addressing the same misread", etc.
  deviations.md     # cases where the pipeline did something the prereg
                    # didn't explicitly cover; what we did and why
```

These are populated *during* the trial, not reconstructed from logs at the end. They cost nothing in the common case (empty file) and cost minutes when a real surprise happens.

**Cross-trial: v3 questions backlog.** A single file at the experiment root:

```
v3_questions.md     # running list of "if v2 confirms / refutes X, then v3
                    # should investigate Y" observations. Populated by the
                    # experimenter as observations arise.
```

Examples of v3-question entries (illustrative):
- "If hunt-spec consistently catches `__proto__`-style prototype-pollution-by-refactor (as in v1 pilot 24483), v3 should add a typed-language-aware adversarial check explicitly."
- "If reviewer-loop converges in 1 round on >80% of trials, v3 can simplify by removing the loop-cap machinery."
- "If trivial no-op rate drops below 5% with V1 prescriptive volley, v3 can remove the trivial-no-op classification."

**Pipeline-deviation log.** When the experimenter has to manually intervene (apply a patch, work around a feasibility issue, exclude a candidate post-extraction), record the intervention. Pilot v1 had several of these (TS type error patch on PR 24483, dep iteration on fastapi); v2 logs them as part of the trail.

**Failure-mode taxonomy aggregation.** At end of v2 main-sample, produce a `failure_modes_v2.md` that categorizes every no-op and exclusion observed, mapped to v2's anticipated failure modes (the 7 pilot-identified). Failures the v2 design didn't anticipate become v3 design inputs.

The cost of this layer is small (per-trial notes + one cross-trial backlog file). The benefit is that v3, if needed, starts from concrete observed failures and not retrospective reconstruction.

### For each sampled PR:

1. **Extract snapshots.**
   Identify `C_base`, `C_test`, and `C_final` according to the definitions above.

2. **Run pre-selection feasibility checks.**
   Before accepting the PR into the sample, verify that the registered command passes at `C_final`, that the source-only `C_test` to `C_final` diff is non-empty, and that at least one source file remains after exclusions. (v2 change: proposed C1)

3. **Prepare clean-room workspace.**
   Copy the repository at `C_test` to a temporary workspace such as `/tmp`.

   The clean-room workspace must:

   - Exclude `.git`
   - Exclude PR metadata
   - Exclude reviewer comments
   - Exclude subsequent commits
   - Disable network access during LLM execution and test execution after dependencies are prepared
   - Use already-resolved dependencies where possible
   - Share build artifacts, package caches, or compiled dependencies across trials from the same repo where this does not expose source state

   Since tests pass at `C_test`, the refactoring task should not require external references or network access.

4. **Generate LLM refactoring via v2 forge pipeline.**

   The refactoring uses the strongest available development methodology: forge with blind-blind implementation, adversarial spec review, broad bug-hunt, complexity gate, and reviewer-in-the-loop. The full pipeline runs inside the clean-room workspace with no access to reviewer comments, later commits, the final accepted PR state, git history, or the internet.

   **4a. Goal-anchored volley.** Parse the PR body for issue references (`#1234`, `fixes #1234`, `closes #1234`, `gh-1234`, repo URLs), fetch linked issue title/body where available before clean-room isolation, and concatenate issues first, then PR title and body. This is the goal. The diff from `C_base` to `C_test` is the artifact. Volley must produce prescriptive, bounded claims that move the artifact closer to the goal. Empty Accepted Claims is permitted and recorded. (v2 change: locked V1)

   **4b. Hunt-spec (iterative).** Run adversarial review of the claims before implementation. Findings are labeled blocker, warning, or note. Iterate: hunt → reconcile → re-hunt, until zero blocker findings remain or the cap is reached. Hard cap: 10 rounds. If unconverged at cap, declare spec unstable and fail the trial back to a no-op.

   **4c. Reconcile.** Any blocker finding from hunt-spec moves the parent claim to Rejected. The reconciler may narrow warnings and must justify each retained claim against the hunt findings. It may not narrow or qualify a blocker. (v2 change: locked V2)

   **4d. Blind-blind-merge.** Two models, same reconciled spec, separate `/tmp` directories. Each produces a refactored version independently. Per-file merge rule: pick the candidate with fewer lines changed vs `C_test` (proxy for structural simplicity). On exact tie, pick alphabetically by model name (codex before opus). The result is the merged candidate. Blind-blind is mandatory for every eligible PR; there is no single-agent path. (v2 change: locked S4)

   Models: Claude Opus 4.6 via Claude Code and Codex GPT-5.4 via `codex exec -s danger-full-access`. Gemini 3.1 Pro Preview via Vertex AI serves as reviewer only; it does not participate in generation.

   **4e. Implementation evidence check.** The implementer must either modify at least one source file with an actual diff and report modified files, or explicitly declare no-op with reason. "Applied M/M, no changes made" is internally inconsistent and is flagged as trivial no-op. (v2 change: proposed V3)

   **4f. Complexity gate.** Measure scoped mean cognitive complexity on the merged candidate and `C_test`. If `mean_cog(candidate) > mean_cog(C_test) + 0.05`, reject the candidate and fall back to `C_test` as no-op. (v2 change: locked S1)

   **4g. Hunt-code (iterative).** Run broad adversarial review against the merged refactoring with the original spec as input. Hunt-code must run the repo's full build plus tests, not just typecheck. Failing the build or tests is a blocker. Iterate: hunt → implementer addresses findings → re-hunt, until zero findings. Hard cap: 10 rounds. If unconverged at cap, fall back to `C_test` as no-op. (v2 change: locked S2 and S5)

   **4h. Reviewer loop.** Gemini 3.1 Pro reviews the post-hunt-code `C_llm` against the goal and artifact context. If it returns zero comments, ship. If it returns comments, the implementer addresses them and Gemini re-reviews. Stop when comments reach zero or comment-count shrinkage stops. Hard cap: 10 review rounds. If remaining comments are blockers, fall back to `C_test`; otherwise ship with remaining comments recorded.

   If the reviewer loop's implementer changes are non-trivial enough to warrant re-running hunt-code, hunt-code runs again with its own cap reset (does not accumulate against the prior round). The reviewer-loop cap also resets after each hunt-code re-entry. (v2 change: locked S6)

   The LLM may not edit tests. It may only edit source files changed from `C_base` to `C_test`. This is mechanically enforced after generation. (v2 change: clean-pass step removed; cleanup happens organically in 4g and 4h iterations)

   Per-language spec template adds idiomatic notes for the target language (gofmt/go-vet for Go, PEP 8 for Python, cargo fmt/clippy for Rust, tsc gate for TypeScript) — kept short, not exhaustive style guides. Each repo's spec template is committed to the trail before its first PR runs. (v2 change: locked V4, simplified)

5. **Verify correctness.**
   Run the predetermined full build and test command on `C_llm`.

   If either fails, the trial is a hard no-op: `C_llm = C_test` for all metrics. The agent failed to stay in the equivalence class.

6. **Generate random control.**
   Apply the predetermined random or mechanical transformation to `C_test`, producing `C_random`.

   Verify whether `C_random` passes the build and tests. If it fails, record failure and classify the control as invalid for that PR.

7. **Measure.**
   Compute complexity and LOC for `C_test`, `C_llm`, `C_final`, and `C_random`. Save raw JSON output per snapshot. (v2 change: proposed O3)

8. **Blind review.**
   Two phases per reviewer per PR:

   **Phase 1 - Forced choice.** Present unlabeled diffs from `C_base` to `C_test` and `C_llm`. Reviewer picks which to approve assuming tests pass. Record semantic concerns and rationale.

   **Phase 2 - Trajectory classification.** Reveal `C_final` labeled as "the version reviewers accepted." Reviewer classifies `C_llm` as past `C_final`, short of `C_final`, or wrong direction.

   **Reviewer protocol (v2):**
   - **Single reviewer is sufficient for trial validity.** Primary reviewer = Gemini 3.1 Pro Preview throughout (in-pipeline + Phase 7), with the pre-approval bias acknowledged.
   - Additional reviewers (Claude Sonnet 4.5, OpenAI GPT-5) are **optional** and run only for inter-rater reliability calibration on a pre-registered subset (e.g., the first batch of each repo). Not required per-trial.
   - The v1 ≥3-reviewer requirement is dropped: pilot blinding failed 5/5, so adding more LLM reviewers averages over the same surface-pattern signal without breaking the bias.
   - The reviewer receives the same goal anchor as the volley: PR title + PR body + linked issue title/body (where available). This makes the reviewer's task structurally analogous to the volley's task — judge the artifact against the goal.
   (v2 change: locked R2 + V1 alignment)

9. **Post-ranking blinding check.**
   After submitting judgments, reviewers answer whether they believed any version was final, LLM-generated, or otherwise identifiable.

10. **Record all metadata.**
    Record:

    - Repository
    - PR number
    - `C_base`, `C_test`, `C_final`
    - All candidate passing commits considered for `C_test`
    - Model name and version
    - Model cutoff date
    - Prompt
    - Linked issue IDs and goal-source status
    - Test command
    - Build command
    - Allowed edit file set
    - Test and build outcome
    - Failure category, if any
    - No-op class, if any
    - Static-analysis tool versions
    - Reviewer IDs or anonymized reviewer labels
    - Review preferences
    - Semantic-concern flags
    - Blinding-check responses
    - Notes on reconstruction issues
    - Python venv manifest where applicable

### Operational constraints

All test-running phases are serialized across PRs because cross-PR test execution can collide on shared filesystem state such as home-directory config files or `/tmp` artifacts. Generation and review phases may parallelize. (v2 change: proposed O1)

For Python repos, save `pip freeze` output per PR as `samples/<set>/<repo>-<pr>/venv-requirements.txt`. Future reruns use that file directly. (v2 change: proposed O2)

## Controls

### Null control

`C_test` itself.

This establishes the baseline state after tests first pass.

### Random/mechanical control

`C_random`, a semantics-preserving but non-simplifying transformation.

This tests whether metrics reward any change or specifically reward simplification.

### Directional proxy

`C_final` - where reviewers pushed the code. Used to classify each trial as short, past, or wrong direction on the complexity axis. Not a ground truth; a satisficing threshold.

## Analysis

### Primary analyses

The three main outcomes are analyzed separately.

### 1. Simplification

Question: Does `C_llm` reduce complexity relative to `C_test`?

Primary comparison:

```text
complexity(C_llm) - complexity(C_test)
```

Report the per-trial deltas and the rate above the threshold. Formal paired tests (Wilcoxon, sign test) are reported only if the rate is close to threshold and statistical inference would change the read. Goal: evidence either way, not paper-grade rigor.

No-op trials contribute zero complexity delta. The denominator is all trials.

### 2. Trajectory classification

Question: Where does `C_llm` land relative to `C_test` and `C_final`?

Report the reviewer-classified three-way distribution: past `C_final`, short of `C_final`, wrong direction. Hard no-op trials count as wrong direction for trajectory. Trivial no-ops are reported separately and counted as not-past in improvement-threshold analysis. (v2 change: proposed R3)

Report scalar agreement, boundary cases, and sensitivity across metrics as robustness checks.

Evaluate P2 against both the parity null and the improvement threshold. (v2 change: locked R1)

```text
Parity null distribution:
  past  in [25%, 45%]
  short in [40%, 55%]
  wrong in [10%, 20%]

Improvement threshold:
  past >= 50%
```

Reject the parity null if the observed distribution falls outside the parity envelope in any direction. Accept improvement if the observed past rate is at least 50%. If parity holds and improvement does not, report: "matches reviewer judgment on trajectory, does not exceed it."

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

Analyze reviewer preferences using a mixed-effects logistic model with random effects for PR and reviewer where reviewer count supports it. A simpler paired sign-test analysis may also be reported for interpretability.

Semantic-concern flags are analyzed separately from merge-readiness preference.

Evaluate P3 against both the parity null and the improvement threshold. (v2 change: locked R1)

```text
Parity null:
  prefer-C_llm rate in [40%, 60%]

Improvement threshold:
  prefer-C_llm rate >= 65%
```

Reject the parity null if the observed rate falls outside the parity envelope. Accept improvement if the prefer-`C_llm` rate is at least 65%. If parity holds and improvement does not, report: "matches reviewer judgment on merge-readiness, does not exceed it."

### Reviewer preference reporting

Report two summaries:

1. **Intent-to-treat (primary for P3):** all trials, hard no-ops scored as "reviewer prefers C_test", trivial no-ops scored as tied. Plain prefer-rate.
2. **Observed-only:** trials where C_llm passed build/tests and reviewers saw actual diffs. Same prefer-rate, smaller denominator.

Mixed-effects models (e.g., logistic with PR + reviewer random effects) are reported only if the data support them and the rate is close to threshold. Single-reviewer pilot data does not warrant random-effect modeling. Goal: evidence either way, not paper-grade rigor.

### Inter-rater reliability

Inter-rater reliability is computed only on the calibration subset where additional reviewers (Sonnet 4.5, GPT-5) ran. The primary analysis uses single-reviewer (Gemini 3.1 Pro) judgments per trial; IRR informs interpretation, not validity.

Calibration measures (where multi-reviewer data exist):

- Agreement rate on pairwise forced choice
- Fleiss' kappa or Krippendorff's alpha for categorical preference labels

Low agreement on the calibration subset is reported as a substantive result about the LLM-reviewer-pattern-matching ceiling, not as evidence the primary trials are invalid. (v2 change: locked R2)

### No-op rate

Report no-op rates by class:

- **Hard no-op:** refactor failed to produce build- and test-passing output.
- **Trivial no-op:** refactor produced zero source modifications.
- **Out-of-scope no-op:** refactor produced changes only outside the allowed edit set, or out-of-scope edits had to be reverted leaving no in-scope diff.

Hard no-op rate measures agent competence. Trivial no-op rate measures whether the spec/implementation pipeline found any actionable refactor. Out-of-scope no-op rate measures edit-boundary compliance. (v2 change: proposed R3)

### Secondary analyses

### Review-round correlation

Test whether LLM improvement correlates with the number of review rounds in the original PR.

### Active-only analysis

Repeat primary analyses on the subset where the agent produced a build- and test-passing non-trivial output. This isolates the quality of refactoring from agent competence.

### Scaffolding-cost analysis

For each repo, log setup time and any extraction failures due to environment reconstruction. Don't formalize beyond that — the cost data is for "should we even attempt this language" decisions, not for hypothesis testing. (v2 change: locked R4, simplified)

## Pilot

The v1 pilot consisted of 16 eligible PRs across TypeScript, Go, and Python after exclusions, with 11 active non-no-op trials. It motivated v2 but does not enter the v2 primary analysis.

Observed pilot results:

- `gemini-cli`: 5 eligible, 4 active `C_llm`, 1 past, 3 short, 1 wrong, 0 no-op.
- `cli/cli`: 9 eligible, 7 active `C_llm`, 1 past, 4 short, 2 wrong, 2 no-op.
- `fastapi`: 2 eligible, 0 active `C_llm`, 0 past, 0 short, 1 wrong, 1 no-op.
- Combined: P3 was 11/14 = 79% excluding fastapi, P2 past was 2/16 = 12.5%, P2 wrong was 4/16 = 25%, and no-op rate was 3/17 = 18%.

The pilot identified the following failure modes that v2 addresses:

- Descriptive rather than prescriptive volley output
- Reconcile failure to reject blocker findings
- Typecheck passing while full build failed
- Test-passing refactor that increased scoped mean cognitive complexity
- Degenerate `C_test == C_final` measurement scope
- High Python environment setup cost
- Cross-PR test collisions through shared filesystem state
- Blinding failure through LLM stylistic signatures

The v2 pilot/dev phase, if run, is used only to validate extraction, prompting, test execution, measurement, and review workflow. It is not used to stop early for efficacy.

## Pilot Decisions

The following v1 pilot decisions are inherited unless explicitly modified by v2.

1. **Complexity tool and configuration.** TypeScript uses `scripts/measure_complexity.mjs`, an AST walker built on `@typescript-eslint/typescript-estree`, run from inside each cleanroom. Primary scalar is weighted mean cognitive complexity across scoped functions. Secondary scalars are weighted mean cyclomatic, max cyclomatic, max cognitive, max nesting, function count, and total LOC.
2. **Review presentation format.** Per-PR markdown bundle with sibling diff patches. Unified diff with 3-line context. Neutral labels. Sequential presentation. Deterministic A/B assignment by hash. Reviewer-facing content includes PR title, PR body, neutral task description, and diffs.
3. **Reviewer population criteria.** Primary reviewer is Gemini 3.1 Pro Preview. Secondary reviewers are Claude Sonnet 4.5 and OpenAI GPT-5 where non-conflicted and available. v2 modifies this by dropping the hard discard rule for trials with fewer than 3 reviewers and by acknowledging Gemini pre-approval bias from the reviewer loop. (v2 change: locked S6, proposed R2)
4. **`C_random` generator specifics.** TypeScript random controls use local variable/parameter renames, independent statement reordering, and redundant parenthesization. Validation requires tests/build to pass and mean cognitive complexity not to decrease by more than `delta = 0.05`.
5. **Boundary threshold `delta`.** `delta = 0.05` on mean cognitive complexity. v2 also uses this threshold for the complexity gate. (v2 change: locked S1)
6. **Secondary repo expansion trigger.** Expand a secondary repo from 3 to 10 PRs if forced-choice preference for `C_llm` drops below 50%, wrong-direction rate is at least 2/3, or there are zero "past" trials.
7. **PR size bound adjustments.** v2 overrides v1's 100-2000 bound with 500-5000 source lines measured from `C_base` to `C_test` after exclusions. (v2 change: locked S4 + C3)

## Futility Conditions

The study may be deemed infeasible, or redesigned before main-sample execution, if the dev/pilot or early extraction process shows any of the following:

1. **`C_test` reconstruction failure is too high.**
   More than 40% of otherwise eligible PRs cannot yield a defensible tests-first-pass snapshot.

2. **Builds/tests are not reproducible often enough.**
   More than 30% of otherwise eligible PRs cannot run the predetermined build and relevant tests reproducibly.

3. **No-op rate is too high.**
   More than 40% of trials are hard no-ops.

4. **Reviewers cannot evaluate the diffs.**
   Reviewers report that the blind diffs are too large, too context-dependent, or too ambiguous to support meaningful merge-readiness judgments.

5. **Metrics are inapplicable.**
   Complexity or distance metrics cannot be computed for a large enough share of cases to support the planned primary analyses.

6. **`C_random` cannot be generated reliably.**
   The random/mechanical control cannot be generated without frequent behavioral breakage, accidental simplification, or invalid edits.

7. **Reviewer-loop convergence fails systematically.**
   More than 40% of active candidates hit the Gemini reviewer-loop cap or impasse with unresolved blockers. (v2 change: locked S6)

These are feasibility and design-validity conditions, not efficacy stopping rules.

## Predictions

### P1: Complexity reduction

`C_llm` will have lower measured complexity than `C_test` in at least 70% of all trials.

The denominator is all trials. Hard no-op and trivial no-op trials count as zero complexity reduction.

**Why P1 has no parity null:** P1's parity-equivalent question — "does the LLM reduce complexity at a rate above what arbitrary semantic-preserving change would?" — is answered by the `C_random` comparison, not by an alternative threshold on P1 itself. If `C_random` is not generated for a trial (per-repo timebox exceeded), P1 evaluation for that trial is incomplete — only the absolute reduction-rate is reported, not the simplification-specific signal. This was a v1 pilot gap (no `C_random` generated); v2 closes it for the primary repo.

### P2: Trajectory past `C_final`

In active trials, the reviewer-classified trajectory distribution is evaluated against both parity and improvement. (v2 change: locked R1)

Parity null:

```text
past  in [25%, 45%]
short in [40%, 55%]
wrong in [10%, 20%]
```

Improvement threshold:

```text
past >= 50%
```

The wrong-direction rate is expected to remain below 20% of active trials. A wrong-direction rate above 20% rejects the v1 optimistic slop-slope prediction even if P3 remains positive.

### P3: Human merge-readiness

Blind reviewers will prefer `C_llm` over `C_test` in at least 65% of all reviewer-PR forced-choice judgments. (v2 change: locked R1)

Parity null:

```text
prefer-C_llm rate in [40%, 60%]
```

Improvement threshold:

```text
prefer-C_llm rate >= 65%
```

The denominator is all reviewer-PR judgments. Hard no-op trials count as "reviewer prefers `C_test`." Trivial no-op trials count as tied in intent-to-treat summaries. (v2 change: proposed R3)

### P4: Some refactors will make things worse

Among build- and test-passing `C_llm` outputs, some will increase measured complexity, be ranked below `C_test` by reviewers, or introduce semantic risk that reviewers notice. These cases - the slop-slope - are the most practically important finding.

Because the sample is restricted to drafts of merged PRs, observed slop-slope prevalence is likely a lower bound on prevalence among arbitrary-quality agent output in real workflows. (v2 change: locked R5)

## Misleading-Result Scenarios

The study will explicitly guard against the following misleading interpretations:

1. **Metric-only simplification.**
   `C_llm` may reduce cyclomatic or cognitive complexity while making the code less idiomatic, less maintainable, or less merge-ready.

2. **Correctness hidden by tests.**
   A refactor may pass the project tests while introducing semantic risk that reviewers notice or that tests fail to cover.

3. **No-op rate masking.**
   A high no-op rate dilutes the signal. Active-only analysis tells you about refactoring quality while all-trials analysis tells you about end-to-end viability.

4. **Review blinding failure.**
   Reviewers may infer which version is LLM-generated or final based on style, polish, or diff shape. The v1 pilot showed this risk clearly.

5. **Reviewer-loop pre-approval bias.**
   Gemini 3.1 Pro participates in the in-pipeline reviewer loop and may also serve as Phase 7 primary reviewer. This biases downstream Gemini judgments toward artifacts it already helped approve. The bias is recorded rather than hidden. (v2 change: locked S6)

6. **Survivorship bias.**
   The study samples only drafts that ultimately merged. It does not measure rejected or abandoned drafts. Positive results are conservative for viable merged-draft workflows, but wrong-direction prevalence is likely understated for wild agent output. (v2 change: locked R5)

These scenarios will be discussed in interpretation regardless of whether the primary predictions are confirmed.

## Checklist Audit

This prereg was audited against the prereg checklist. Answers below.

**Q3 (Descartes) - Assumptions that would invalidate:**

- That test suites define a meaningful equivalence class. If tests are too weak, "test-passing" does not mean "correct."
- That complexity metrics correlate with what reviewers care about. If they do not, P1 is meaningless even if true.
- That blinded reviewers approximate real merge decisions. If context matters more than code quality, the forced-choice task measures the wrong thing.
- That `C_final` marks the direction of reviewer preference on complexity. If post-`C_test` changes were mostly bug fixes or API changes, the directional proxy is noise.
- That Gemini reviewer-loop pre-approval does not dominate downstream Phase 7 judgments. If it does, P3 overstates independent merge-readiness.

**Q8 (Chamberlin) - Competing explanations for a positive result:**

- The prompt was tuned on dev-set PRs from the same repos, and the test-set PRs share enough structure that the prompt's effectiveness is overfitted rather than general.
- The model has trained on similar public PRs and is reproducing patterns, not reasoning. Output quality remains the practical target, but this limits generalization.
- The complexity reduction is real but reviewer preference is anchored by seeing `C_final` in Phase 2, not by independent judgment.
- Larger PRs were preferentially selected, and refactoring has more room on larger PRs. v2 intentionally leans into this because large PR success plausibly down-induces to smaller cases.
- The reviewer-in-the-loop made the artifact better by optimizing toward Gemini's taste specifically, not toward human reviewer taste generally.

**Q12 (Kuhn) - Paradigm assumptions:**

- We assume "merge-readiness" is primarily a property of the code. It may also be a property of the relationship between code and reviewer context: trust, roadmap awareness, incident history, and maintainer priorities. Blinded review strips that context. If the paradigm is wrong, the study measures an abstraction that does not exist in practice.

**Q16 (Ioannidis) - Positive predictive value:**

- 27 trials, moderate flexibility, prompt tuned on dev set, metrics registered before extraction, and expansion rules logged. Prior remains friendly: LLMs are probably decent at refactoring. Under these conditions, a positive result on P1 or P3 is likely real within the scoped population. P2 is more fragile because the trajectory classification depends on reviewer judgment calibrated against a lossy oracle.
- No formal power analysis. The pilot estimated variance and showed P2 past-trajectory is likely harder to move than P3 preference.

**Q20 (Ramdas) - Sequential validity:**

- Batch expansion looks at results before deciding whether to continue. This is peeking by design. Evidence compounds across batches; the second batch does not invalidate the first. All expansion decisions and their rationale are logged before the next batch begins. Pre-expansion and post-expansion results are reported side by side.

**Skipped:**

- Q9 (Fisher) - randomized assignment. Not applicable: within-PR design, no assignment to conditions.

## Threats to Validity

### `C_final` is a satisficing threshold

Reviewers accept "good enough," not the simplest possible. `C_final` marks the direction they pushed, not the optimum. `C_llm` landing past it is evidence the agent outperformed a pragmatic bar, not that it found the global minimum.

### Test suites are incomplete

Passing tests does not prove semantic equivalence. This study uses project tests as the available behavioral predicate, while recognizing that reviewers may catch issues tests miss.

### Reviewer judgments may vary

Merge-readiness is partly subjective. The study reports each reviewer separately, aggregates where applicable, and reports inter-rater reliability when reviewer count permits.

Disagreement among reviewers is itself informative about whether the complexity axis is well-defined.

### Reviewer-loop pre-approval bias

The v2 reviewer loop uses Gemini 3.1 Pro before `C_llm` ships, and Gemini 3.1 Pro is also the primary downstream reviewer. This creates pre-approval bias. It is accepted because the experiment's practical goal is to ship better artifacts, but it weakens the independence of Gemini's downstream Phase 7 judgment. Secondary reviewers, when available, are important for estimating the size of this bias. (v2 change: locked S6)

### Leakage

The LLM must not see reviewer comments, later commits, `C_final`, PR discussion, git history, or internet resources during generation.

The clean-room procedure strips `.git`, copies only the `C_test` tree, disables network access after dependency setup, and mechanically enforces the allowed edit set. Goal text from linked issues, PR title, and PR body is allowed by design because v2 makes the goal anchor explicit. (v2 change: locked V1)

### Training contamination

Only PRs merged after the model's training cutoff are eligible.

The model version and cutoff date are recorded before sampling. This is a mitigation, not elimination. Public code, PR discussions, and similar patterns may exist in retrieval or evaluation memory despite cutoff restrictions.

### Causal scope

The experiment tests this prompt, these models, and these PRs under a specific forge-wrapped workflow. The causal claim is narrow: this specific intervention on these specific PRs, under these specific conditions. Whether the LLM "understands" simplicity or has memorized patterns that produce simpler code is irrelevant to the practical question of output quality.

Positive results on high-caliber repos suggest the refactoring pass may transfer to simpler codebases, but different code quality norms and PR shapes could change the effect. Down-induction is plausible, not guaranteed.

### Environment reconstruction

Historical test environments may be hard to reproduce. PRs whose `C_test` status cannot be reconstructed reproducibly are excluded before assignment.

Python repos are especially vulnerable to dependency setup cost. v2 records per-language scaffolding cost and per-PR Python venv manifests. (v2 change: proposed R4 and O2)

### Metric validity

Cyclomatic complexity, cognitive complexity, and LOC are incomplete proxies for maintainability. This is why the study keeps static metrics and human review as separate outcomes.

### Scope restriction

The estimand is limited to drafts of merged brownfield PRs with substantive post-tests-pass source revision. The results should not be generalized to all PRs, all repositories, greenfield tasks, rejected drafts, or changes without meaningful review-driven revision.

### Survivorship bias

The candidate pool is restricted to merged PRs. PRs that died in review, were closed without merge, were abandoned by the contributor, were rejected outright, or stayed in changes-requested indefinitely never enter the pool.

This means `C_final` is what a contributor-reviewer pair converged on, not what reviewers would accept from any starting point. The trajectory comparison is relative to a survivor. Contributors whose drafts were unsalvageable or who could not absorb review feedback are absent.

Bias direction is mixed. Positive results on P1, P2, and P3 are conservative because survivor drafts are already relatively viable, leaving less room for the LLM to improve. Negative slop-slope prevalence in P4 is understated because the wildest bad drafts are filtered out before sampling. (v2 change: locked R5)

## What This Would Show

### If confirmed

LLMs can autonomously improve the complexity trajectory and merge-readiness of large merged brownfield contribution drafts after tests pass, within the scoped class of PRs studied.

The practical implication is that coding agents should include a goal-anchored refactoring pass, full build/test validation, complexity gate, broad bug-hunt, and lightweight reviewer loop after achieving correctness and before requesting review. This could reduce review burden by pre-resolving some cleanup and maintainability feedback.

### If partially confirmed

Different outcome patterns imply different conclusions:

- If complexity improves but reviewers do not prefer `C_llm`, the model is optimizing a metric that does not match taste.
- If reviewers prefer `C_llm` but complexity increases, the model is doing something useful that metrics do not capture.
- If P3 clears improvement while P2 remains at parity or below, the model improves merge-readiness without exceeding the accepted human trajectory.
- If the no-op rate is high but active trials show improvement, the bottleneck is agent competence, not refactoring judgment.
- If Gemini prefers `C_llm` but secondary reviewers do not, the reviewer loop may be overfitting to Gemini's review style.

### If refuted

The complexity axis may require contextual judgment that LLMs lack without real maintainer feedback. Reviewers may not merely be asking for less complexity; they may be asking for project-specific tradeoffs that are difficult to infer from code, PR description, and linked issue text alone.

If refuted despite v2's build gate, complexity gate, blocker enforcement, and reviewer loop, the slop-slope becomes harder to dismiss as a prompt-engineering artifact.

## Registered: 2026-04-16
