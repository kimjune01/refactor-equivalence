# Improvements for prereg v2

Forward-looking design doc based on observations from the 16-PR pilot across gemini-cli (TS), cli/cli (Go), and fastapi (Python). Not amendments to the registered v1 protocol — a recipe for what to change in v2.

Categories below: **prompt fixes**, **forge structure**, **selection criteria**, **estimand registration**, **operational rules**. Each item is rated by expected information-gain-per-effort.

## Prompt-level fixes

### V1. Prescriptive-anchored volley *(tiny effort, huge value)*

**Problem observed (fastapi 14962):** codex's volley produced "ensure X behavior is preserved" claims. Opus interpreted them correctly as preservation-of-existing-state and made zero changes. Both candidates were no-ops.

**Fix:** add a precondition to the volley skill prompt:

> Each claim is a CHANGE: "Replace X with Y", "Inline Z", "Extract H from F". Claims that begin with "ensure", "preserve", or "keep" describe existing state and are NOT refactor claims — reject them. If you cannot find changes worth proposing, output an empty Accepted Claims list (this is allowed).

This is a precondition on the spec format, enforceable by the skill before downstream stages run. If the volley emits non-prescriptive claims, the spec fails preflight and is regenerated.

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

**Clarification (not a change):** blind-blind was always meant for large PRs. The skill itself can carry a precondition that gates it on diff size. Below threshold, single-agent (e.g., opus alone) is the path.

**Fix:** make the precondition explicit in the skill:

> Skip blind-blind merge IF total source-file diff < N lines. Use single-agent generation for small refactors.

Threshold N to be calibrated — pilot data shows opus and codex were byte-identical on PR 24437 (5 files, ~30 lines) and ≤4 files / ≤13 lines diverged on the 4 larger PRs (1000+ LOC). N=200 source lines is a reasonable starting threshold.

### S5. Hunt-code is mostly redundant with prior gates *(observation, possible removal)*

**Observed:** hunt-code returned "No findings" on most cli/cli expansion PRs. Defects that landed in C_llm were typically caught by either hunt-spec (most useful), the complexity gate (S1), or the build step (S2). Hunt-code-as-currently-prompted is doing redundant work.

**Possible fix:** retain hunt-code only as a final pre-PR-creation safety net checking exported-symbol stability, gofmt/lint compliance, and out-of-scope edits — not behavior reverification (already done by S2). Slim its prompt.

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

## Estimand registration changes

### R1. Register parity null alongside improvement threshold *(tiny effort, huge value)*

**Problem observed (retro R8):** P2 was registered as "past ≥ 50%" — an improvement threshold. Without a parity null, "did P2 pass" is ambiguous when observed past is 12-20%: that could mean "the LLM is broken" or "the LLM is at parity, beating the bar would have been a bonus." We can't tell.

**Fix:** register both thresholds explicitly:

```
P2 evaluation:
  Parity null distribution: past ∈ [25%, 45%], short ∈ [40%, 55%], wrong ∈ [10%, 20%]
  Improvement threshold: past ≥ 50%

  Reject parity null IF observed distribution falls outside parity envelope (in any direction)
  Accept improvement IF past ≥ 50%
  If parity holds AND improvement does not: report "matches reviewer judgment, does not exceed it"
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

**Q1: How conservative should the complexity gate be?** δ=0.05 was the boundary threshold for trajectory classification. Same threshold for the gate? Or stricter (δ=0.0, any complexity increase rejects)? Stricter rejects more refactors as no-ops; looser lets through marginal regressions.

**Q2: Should the gate include max-complexity, or only mean?** Pilot showed max complexity is sticky (refactors don't touch the worst functions). A gate on mean alone might miss regressions in heavyweight functions. A gate on max would be more aggressive.

**Q3: Should reviewer Phase 7 be folded into the forge as an inline gate?** The Phase 1 forced choice between C_test and C_llm could itself be a gate: if reviewers prefer C_test, fall back to C_test as no-op. Pros: aligns forge success with the experiment's primary outcome. Cons: makes Phase 7 part of the pipeline rather than a separate evaluation, contaminating the design.

**Q4: Single-agent default for small PRs?** S4 makes blind-blind precondition explicit. What's the right default for sub-threshold PRs — single opus, single codex, or rotate?

**Q5: Should v2 register a parity null on P3 too?** Currently P3 has only an improvement threshold (≥65%). Same R8 logic applies: under parity what would we expect? If LLM and reviewer judgments are equally noisy, a 50/50 split is the parity null and 65% is meaningful improvement. Worth making explicit.
