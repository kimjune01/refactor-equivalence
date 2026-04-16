# Improvements for prereg v2

Forward-looking design doc based on observations from the 16-PR pilot across gemini-cli (TS), cli/cli (Go), and fastapi (Python). Not amendments to the registered v1 protocol — a recipe for what to change in v2.

Categories below: **prompt fixes**, **forge structure**, **selection criteria**, **estimand registration**, **operational rules**. Each item is rated by expected information-gain-per-effort.

## Prompt-level fixes

### V1. Volley needs a goal anchor: PR description as goal, diff as artifact *(tiny effort, huge value)*

**Problem observed (fastapi 14962):** codex's volley produced "ensure X behavior is preserved" claims. Opus interpreted them correctly as preservation-of-existing-state and made zero changes. Both candidates were no-ops.

**Root cause:** the experiment harness invoked volley naked. The volley prompt gave codex the diff and asked for "claims," with no anchor against which "good claim" could be evaluated. Without a goal, codex could only describe the artifact's existing properties.

**Fix:** the volley invocation must pair **goal** with **artifact**:
- **Goal** = the linked issue(s) + PR title + PR body (what the contributor was trying to achieve)
- **Artifact** = the diff from C_base to C_test (the realization of the goal so far)

Issues matter because the PR description often degrades to "this PR does X" — already half-artifact, framed by the implementer. The original goal lives upstream in the issue: "users can't do Y," "we keep getting reports of Z," "we need to support W." That's the gradient against which "good claim" is evaluated.

Goal fetch order:
1. Parse PR body for issue references (`#1234`, `fixes #1234`, `closes #1234`, `gh-1234`, repo URLs)
2. Fetch those issues via `gh issue view --json title,body`
3. Concatenate: issue(s) first (the "why"), then PR title + body (the contributor's framing of "how")
4. If no issue references: fall back to PR title + body alone, log as "no upstream goal"

Claims are then proposed *changes to the artifact that better serve the goal*. This naturally produces prescriptive claims because every claim is gap-relative.

**Volley prompt template (v2):**

```
You are sharpening a refactor spec. Treat the PR description as the GOAL —
what the contributor was trying to achieve. Treat the diff as the ARTIFACT —
the realization so far.

PR title: {title}
PR body: {body}

Allowed edit set: {file list}
Diff to refactor (artifact): {diff}

What changes to the artifact would better serve the goal? Each claim should:
- Move the artifact closer to the goal's intent (cleaner, less coupling,
  less indirection introduced by THIS diff)
- Preserve the goal's behavior (tests stay green)
- Be specific (file + function/block + change)
- Be bounded (one independent change per claim)
- Reject claims that "preserve behavior" or "ensure X" — those are
  descriptions of the artifact, not refinements toward the goal

If the artifact already serves the goal cleanly, output an empty Accepted
Claims list. That is allowed and is itself a finding.
```

The skill can carry a precondition checking that PR title + body are non-empty before volley runs — naked-spec invocations fail preflight.

**Reliability of the goal source:** the repos in this experiment (gemini-cli, cli/cli, fastapi, ruff, django) all enforce PR templates with structured goal sections — typically `## Description`, `## Why`, `## Motivation`, or `## What`. Contributors fill these in to get past PR-description CI. So at test-set scale the goal anchor is reliably present in `gh pr view --json body`. The precondition can be tightened from "body is non-empty" to "body matches expected template sections" per repo, with naked-template PRs (e.g., contributor left placeholders unedited) treated as feasibility exclusions at selection time.

### V2. Adversarial reconcile *(tiny effort, high value)*

**Problem observed (cli/cli 12695):** hunt-spec correctly predicted a test failure on a claim. Reconcile retained the claim. Resulting C_llm broke tests → no-op.

**Fix:** reconcile prompt becomes mandatory-reject on blocker findings:

> Any hunt-spec finding labeled `blocker` (compile-breaking, test-breaking, behavior-changing) MOVES the parent claim to Rejected. You may not narrow or qualify a blocker — only reject. Warnings can narrow. Justify each retention against the hunt findings.

### V3. Implementation must declare evidence of change *(tiny effort, medium value)*

**Problem observed (fastapi 14962):** opus reported "Applied 13/13 claims" while making zero file modifications. The IMPLEMENT_SUMMARY contract was insufficient.

**Fix:** tighten the implement contract:

> Either: (a) modify ≥1 source file with an actual diff and report `Applied N/M (N≥1, modified files: [list])`; or (b) explicitly declare no-op with reason. "Applied M/M, no changes made" is internally inconsistent and must be flagged as a no-op.

### V4. Per-language spec template *(medium effort, medium value)*

**Problem observed:** REFACTOR_SPEC.md was reused across TS/Go/Python with verbal patches. Each language has different idioms, type systems, and review cultures.

**Fix:** ship per-language REFACTOR_SPEC templates with idiom anchors:
- TypeScript: tsconfig path conventions, `tsc --noEmit` gate, ESLint rules in scope
- Go: `gofmt -l`, `go vet`, idiomatic error handling, no generics-for-its-own-sake
- Python: PEP-8, type hints consistent with surrounding module, docstring style
- Rust: `cargo fmt`, `cargo clippy`, no `unwrap()` without comment

Parametrize at extraction time per repo.

## Forge structure changes

### S1. Complexity gate between merge and bug-hunt *(small effort, high value)*

**Problem observed (fastapi 15022):** codex's refactor passed tests, but scoped mean cognitive complexity went UP +0.06 vs C_test. Forge had no gate to detect "tests pass but the metric we care about got worse."

**Fix:** insert a complexity gate immediately after blind-blind-merge:

```
volley → hunt-spec → reconcile → blind-blind-merge →
  COMPLEXITY GATE: if scoped_mean_cog(C_llm) > scoped_mean_cog(C_test) + δ,
                   reject merge → fall back to C_test as no-op →
hunt-code → volley-clean
```

**Threshold locked to δ = 0.05** (same as trajectory boundary, locked in PILOT_DECISIONS.md item 5). One number, two uses. Simple to reason about.

This is the simplest possible fix for the "scalar-up but tests-pass" failure mode. It explicitly aligns the forge's success condition with the experiment's primary scalar.

### S2. Build in hunt-code, not just typecheck *(tiny effort, high value)*

**Problem observed (cli/cli 24483):** hunt-code's `tsc --noEmit` missed a TypeScript dead-case error that `npm run build` caught. R6 from retro.

**Fix:** hunt-code prompt MUST run the repo's full build command (`npm run build`, `go build ./...`, `cargo build`) plus tests, not just type-checks. Failing the build is a blocker finding.

### S3. Hunt-spec → re-volley loop instead of reconcile *(medium effort, medium value)*

**Problem observed:** reconcile is a single linear pass that sometimes fails to act on findings. Hunt-spec catches issues but reconcile has no enforcement teeth (V2 fixes the prompt; this fixes the structure).

**Fix:** replace reconcile with iterative volley:

```
volley → hunt-spec → IF findings: re-volley with findings as input → hunt-spec → repeat
                    UNTIL zero blocker findings OR N=3 rounds (declare unstable, fail)
```

This is the same convergence mechanic as bug-hunt, applied at the spec stage.

### S4. Blind-blind precondition: large PRs only *(zero effort, clarification)*

**Clarification (not a change):** blind-blind was always meant for large PRs. The skill itself carries a precondition that gates it on diff size.

**Locked threshold: 500 source lines.** Same number as the C3 size floor — they unify. PRs not worthy of blind-blind are not worthy of the experiment. The corollary: there is no "single-agent path" for sub-threshold PRs because sub-threshold PRs are not eligible.

Justification for 500: pilot data shows opus and codex were byte-identical on PR 24437 (5 files, ~30 lines source) and diverged on 2-4 files in PRs above 600 LOC. Crossover sits around several hundred LOC; 500 puts us on the divergent side with margin, and aligns with the "down-induction implies small" argument from C3.

### S5. Hunt-code stays broad, iterates to zero-findings convergence *(no change — restate intent)*

**Observed:** hunt-code returned "No findings" on most cli/cli expansion PRs. Defects that landed in C_llm were typically caught by either hunt-spec, the complexity gate (S1), or the build step (S2). It looked redundant.

**Decision: keep it broad, run it iteratively (zero-findings termination).** Per the existing /bug-hunt skill: hunt iterates until it returns zero findings, then terminates. Most cases converge on the first pass — cost is bounded by convergence. LLM budget is cheap relative to missing a bug that ships into a real PR.

In v1 the experiment ran hunt-code as a single pass. v2 follows the skill's default iterative contract:

```
loop:
  hunt-code → produces findings
  IF zero findings: terminate, ship C_llm
  ELSE: implementer addresses → re-hunt
```

This keeps the adversarial sanity check alive AND makes it cheap in the common case (one pass, zero findings, done).

### S6. Reviewer-in-the-loop after merge *(medium effort, high value — addresses primary outcome alignment)*

**Problem observed:** the forge ships C_llm based on its own gates (tests, complexity). Whether reviewers would actually approve it for merge — the experiment's P3 — is only measured downstream. Forge has no signal of "this would get rejected in review" until after it ships.

**Fix:** add a reviewer loop between hunt-code and the final ship step. Mirrors how review bots (CodeRabbit, Sourcery) function in real PR pipelines:

```
volley → hunt-spec → reconcile → blind-blind-merge →
  COMPLEXITY GATE → hunt-code (mechanical) →
  REVIEWER LOOP:
    Gemini 3.1 reviews the merged C_llm vs the goal +
    artifact context → comments
    IF approve: ship C_llm
    IF comments: implementer (opus) addresses → re-review →
       repeat up to N rounds
    IF still not approved after N rounds: fall back to C_test (no-op)
```

**Reviewer model: Gemini 3.1 throughout** — in-pipeline and Phase 7. The pre-approval bias (Phase 7 reviewer has seen and signed off on C_llm at gate-time) is acceptable for two reasons:
1. The experiment's primary purpose is to ship better artifacts. Iteration with a reviewer model produces a better artifact, not just a better-measured one. Quality-on-model-agreement only goes up.
2. The slop-slope failure mode is still detected through the no-op path: a C_llm that the in-pipeline reviewer rejects after N rounds becomes a no-op, which scores as "reviewer prefers C_test" in P3 intent-to-treat. The cases the experiment most wants to find still surface.

What we lose: Phase 7's "independent judgment" of C_llm becomes pre-biased. Acknowledged trade.

**Iteration cap:**
- **Approve**: reviewer returns zero comments → ship C_llm.
- **Impasse**: comment count stops shrinking between rounds (implementer can't address what's left) → ship C_llm with the remaining comments noted, OR fall back to C_test if the unaddressed comments are blockers (test/build/complexity).
- **Safety bound**: N=10 hard cap. Almost never hit in practice; exists to catch pathological reviewer/implementer pairs.

## Selection criteria changes

### C1. Pre-selection feasibility check *(small effort, high impact on n)*

**Problem observed:** 4 of 13 cli/cli candidates were excluded post-extraction. Reasons:
- 2 squash-merge build failures (PR HEAD missing files added in main post-merge)
- 1 docs/CI-only (no source code in scope)
- 1 C_test == C_final (no source revision in allowed scope)

**Fix:** add to candidate filter, run BEFORE accepting a PR into the pool:
1. `<test command>` passes at C_final
2. `git diff <C_test> <C_final> -- <source globs except tests>` is non-empty
3. ≥1 file in source globs after exclusions

This raises eligibility rate from ~75% to ~95% by rejecting bad candidates upfront.

### C2. Refine "substantive post-tests-pass revision" to source-only *(tiny effort, fixes degenerate trajectories)*

**Problem observed (cli/cli 12696):** the only post-test commit was a test-file change. Per inclusion condition 5 it satisfied "non-trivial code change." But the measurement scope excludes tests — so on the measured scope, C_test ≡ C_final. The trajectory comparison was degenerate.

**Fix:** condition 5 requires non-trivial revision in **the measurement scope** (allowed edit set ∩ non-test files), not just any file.

### C3. Raise the size floor: size/complexity induces down *(tiny effort, high signal-per-trial)*

**Down-induction argument.** The prereg already uses this logic for repo selection ("if it works on the strictest repos, down-induction to simpler ones is plausible"). The same logic applies to PR size *within* a repo: if forge handles large and complex PRs well, the small/simple cases are implied. Testing small PRs is redundant work.

This sharpens the framing: small PRs aren't "noisy" or "uninformative." They're *implied* by the large PR results. We shouldn't need to run them at all.

**Problem observed:** the pilot included PRs as small as 270 LOC (fastapi 14962), 302 LOC (cli/cli 12846), 374 LOC (cli/cli 12811). The fact that forge handled some easily and choked on others tells us little — both outcomes are implied by what we'd see at the high end.

The interesting case is large PRs where:
- Forge has more room to mess up (more places for bad refactors to land)
- Reviewer additive bias has more surface to manifest (C_final more likely to diverge from C_test)
- Complexity deltas are large enough to interpret (above metric noise)
- Blind-blind earns its precondition (S4)

**Fix:** raise the minimum to 500 source lines (C_base → C_test, post-exclusion). Make "prefer larger" strict — when expanding a sample, pick from the top of the size-sorted candidate pool. Surprise that holds at the top induces down to smaller cases.

**Maximum bound:** the registered 2000 was a reviewer-fatigue ceiling for Phase 7 single-session review. With multi-reviewer support and chunkable diffs, raise to 5000 source lines. PR cli/cli 24489 (3099 LOC) was excluded post-extraction under the 2000 cap but is exactly the kind of trial worth running.

**Pool effect (estimated from pilot):** the 89 gemini-cli candidates filtered to 100-2000 LOC would shrink to ~30-40 at ≥500 LOC. Still ample for the registered 15-PR primary sample. Secondary repos may need to expand their initial pull radius (e.g., wider date range) to hit 3 eligible candidates above the floor.

## Estimand registration changes

### R1. Register parity null alongside improvement threshold *(tiny effort, huge value)*

**Problem observed (retro R8):** P2 was registered as "past ≥ 50%" — an improvement threshold. Without a parity null, "did P2 pass" is ambiguous when observed past is 12-20%: that could mean "the LLM is broken" or "the LLM is at parity, beating the bar would have been a bonus." We can't tell.

**Fix:** register both thresholds explicitly for both P2 and P3.

```
P2 evaluation (trajectory):
  Parity null distribution: past ∈ [25%, 45%], short ∈ [40%, 55%], wrong ∈ [10%, 20%]
  Improvement threshold: past ≥ 50%

  Reject parity null IF observed distribution falls outside parity envelope (in any direction)
  Accept improvement IF past ≥ 50%
  If parity holds AND improvement does not: report "matches reviewer judgment on
  trajectory, does not exceed it"

P3 evaluation (forced choice):
  Parity null: prefer-C_llm rate ∈ [40%, 60%] (50/50 ± noise)
  Improvement threshold: prefer-C_llm rate ≥ 65%

  Reject parity null IF observed rate falls outside the parity envelope
  Accept improvement IF rate ≥ 65%
  If parity holds AND improvement does not: report "matches reviewer judgment on
  merge-readiness, does not exceed it"
```

### R2. Drop ≥3-reviewer requirement *(tiny effort, medium value)*

**Problem observed:** blinding failed in 5/5 of gemini-cli's Phase 7 reviews. Gemini correctly identified C_llm as LLM-generated based on stylistic signatures (DRYing, ES6 shorthand, helper extraction). Adding more reviewers won't help if they pattern-match the same surface signatures.

**Fix:** report each reviewer's judgment separately, note inter-rater agreement as a finding rather than a quorum requirement. Specifically:
- Use Gemini 3.1 Pro as primary; Sonnet 4.5 + GPT-5 as secondary where non-conflicted
- Report each model's preference and trajectory classification
- Aggregate via majority where applicable, but DO NOT require 3 reviewers per PR
- If only 1 non-conflicted model is available (as in pilot), the trial is still valid

### R3. Define "no-op" precisely *(small effort, clarifies P3)*

**Problem observed:** "No-op" was used for three different conditions in the pilot:
- **Hard no-op**: refactor failed to produce test-passing output (cli/cli 12695)
- **Trivial no-op**: refactor produced 0-LOC change (fastapi 14962)
- **Out-of-scope no-op**: refactor produced changes outside allowed set, ignored

**Fix:** define each in v2 and treat differently in P3 intent-to-treat:
- Hard no-op: scored "reviewer prefers C_test"
- Trivial no-op: scored as "tied" (50/50 rather than auto-prefer-C_test)
- Out-of-scope no-op: revert the out-of-scope edits, keep in-scope ones, classify by what remains

### R5. Survivorship bias must be acknowledged *(tiny effort, integrity)*

**Hidden assumption (uncorrected in v1):** the candidate pool is restricted to *merged* PRs. PRs that died in review — closed without merge, abandoned by the contributor, rejected outright, or stuck in CHANGES_REQUESTED forever — never enter the pool. So:

- `C_final` is "what a contributor + reviewer pair were able to converge on," not "what reviewers would accept from any starting point."
- The trajectory comparison `past / short / wrong` is *relative to a survivor*. PRs whose drafts were so far off that reviewers rejected them outright are filtered out — exactly the wild slop-slope cases the experiment most wants to see in nature.
- Reviewer-additive bias (the R3 reframe in retro) is measured only on PRs whose contributors *could absorb* the additions. Contributors who pushed back too hard or gave up are absent from the data.
- "Merge-readiness" in our P3 question means "merged-form-readiness from a draft that already survived," not "merge-readiness for any plausible draft."

**Fix in v2 prereg:** add this explicitly to Threats to Validity. Phrase the estimand carefully:

> The estimand is the effect of a forge-wrapped LLM refactoring pass on **drafts of merged brownfield PRs** — i.e., on the population of pre-review states that ultimately produced an accepted version. Drafts that were rejected without merging are not in scope. This is a survivorship-filtered population: contributors who could not converge with reviewers, or whose drafts reviewers found unsalvageable, do not contribute data.

**Direction of the bias — helps or hurts our case?** Mixed:

- **Helps** the positive results (P1, P2, P3): survivorship pre-filters for drafts that contributors+reviewers could converge on, which means the drafts are already pretty good. Less room for the LLM to simplify, less room to land past C_final, less room for reviewers to find the LLM version dramatically better. Clearing a threshold on this sample means clearing it on a sample biased *against* clearing it. Positive results are conservative, more credible.

- **Hurts** the negative result (P4 / slop-slope prevalence): the contributors whose drafts reviewers couldn't fix never enter the pool. Those are the same contributors most likely to ship slop in the wild. The wrong-direction rate observed here understates the real-world prevalence among arbitrary-quality agent output. The 25% combined wrong-direction observed in the pilot is plausibly an undercount.

For the v2 framing: lean into the conservative-positive reading where it applies. For slop-slope, explicitly note the bias direction — observed rate is a lower bound on the wild rate.

**Optional v2 design extension (not required to ship):** add a comparison arm sampling *closed-without-merge* PRs from the same period. Run forge against their `C_test` candidate states and compare:
- Does forge produce test-passing C_llm at similar rates on rejected drafts?
- When forge succeeds on a rejected draft, would reviewers prefer the C_llm over the C_test (despite reviewers having rejected the original)?
- Does the LLM's refactor land in a more reviewer-acceptable shape than what the contributor produced?

This would be a separate mini-study, expensive (rejected PRs often have C_test reconstruction issues since they never merged), but informative about whether forge can rescue PRs that humans gave up on. Worth considering as a v2.5 follow-up, not blocking the main v2 prereg.

### R4. Per-language scaffolding cost is part of registration *(tiny effort, sets expectations)*

**Problem observed:** Python (fastapi) cost ~90 minutes of dep iteration before tests would run. This was discovered during extraction, not budgeted upfront.

**Fix:** for each secondary repo's language, register BEFORE extraction:
- Complexity tool + version
- Test command (with deselects for env-dependent tests)
- C_random transformation family
- Estimated venv/dep setup cost (timeboxed)
- Fallback if cost exceeds timebox

## Operational rules

### O1. Serialize test runs across PRs *(R5 from retro)*

Cross-PR test execution collides on shared filesystem state (`~/.gemini`, `/tmp` artifacts used by tests like `logger.test.ts`, `write-file.test.ts`). All test-running phases must be serialized across PRs. Generation/review phases (volley, hunt-spec, blind-blind, hunt-code) can parallelize.

### O2. Per-PR venv manifest for Python *(small effort, high reproducibility value)*

For Python repos, save `pip freeze` output per PR as `samples/<set>/<repo>-<pr>/venv-requirements.txt`. Future runs use that file directly instead of iterating to discover missing deps.

### O3. Snapshot what we measured, not what we ran *(small effort, audit value)*

Save complexity-tool output JSON per snapshot per PR alongside the markdown summary. Lets future analyses re-aggregate without re-running tools.

## Priority ranking

| # | Fix | Where | Effort | Value | Notes |
|---|---|---|---|---|---|
| 1 | V1: prescriptive volley | prompt | tiny | huge | kills "no-op from descriptive volley"; fastapi 14962 would have been an active trial |
| 2 | V2: adversarial reconcile | prompt | tiny | high | kills "reconcile-failure-to-reject"; cli/cli 12695 would not have been no-op |
| 3 | S1: complexity gate before bug-hunt | structure | small | high | kills "scalar-up-but-tests-pass"; fastapi 15022 would have been no-op (better than wrong-direction) |
| 4 | S2: build in hunt-code | structure | tiny | high | reuse R6 lesson; PR 24483 would have been caught earlier |
| 5 | C1: pre-selection feasibility | selection | small | medium | raises eligibility rate ~75% → ~95% |
| 6 | R1: parity null in P2 | registration | tiny | huge | resolves "did P2 pass?" ambiguity |
| 7 | C2: revision-in-scope condition | selection | tiny | medium | rejects degenerate trajectories like cli/cli 12696 |
| 8 | S4: blind-blind precondition | structure | zero | clarification | already implicit, make explicit |
| 9 | R2: drop ≥3-reviewer req | registration | tiny | medium | acknowledges blinding failure |
| 10 | V4: per-language spec template | prompt | medium | medium | avoids verbal patching across languages |
| 11 | S3: hunt-spec → re-volley loop | structure | medium | medium | replaces reconcile with iteration |
| 12 | R3: precise no-op classification | registration | small | medium | clarifies P3 intent-to-treat |
| 13 | V3: implementation evidence | prompt | tiny | medium | catches lying-about-changes |
| 14 | R4: register language-cost | registration | tiny | low | sets expectations |
| 15 | O1: serialize tests across PRs | operations | zero | reliability | codify R5 |
| 16 | O2: per-PR venv manifest | operations | small | reproducibility | for Python |
| 17 | O3: save complexity JSON | operations | small | audit | descriptive |
| 18 | S5: slim hunt-code | structure | small | small | possibly redundant after S1+S2 |

## v2 minimum viable change set

If v2 ships only the top 4 changes (V1, V2, S1, S2), it would address:
- Both classes of "no-op due to forge defect" (descriptive volley, reconcile failure)
- Both classes of "tests pass but quality regressed" (scalar-up, build break)

These are the highest-leverage prompt + structure fixes. Everything below is refinement.

## Open questions for v2

**Q1 [LOCKED]: complexity gate threshold = δ = 0.05** (same as trajectory boundary). One number, two uses.

**Q2 [LOCKED]: Reviewer-in-the-loop after merge** (S6). Same model (Gemini 3.1) used in-pipeline and Phase 7. Pre-approval bias acknowledged; outcome quality > measurement purity. Iteration: convergence on zero comments OR impasse on shrinking comments, N=10 as rare-case safety bound.

**Q3 [LOCKED by exclusion]: No single-agent path.** Sub-blind-blind PRs are not eligible (S4 unified with C3). Every accepted PR runs blind-blind.

**Q4 [LOCKED]: Parity null on P3** = prefer-C_llm rate ∈ [40%, 60%]. R1 covers both P2 and P3 with the dual-threshold framing.

**Q5 [LOCKED]: Hunt-code stays broad, iterates to zero-findings convergence.** Per existing /bug-hunt skill default. Cheap in the common case (single pass, zero findings).
