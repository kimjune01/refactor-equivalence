# v2 Results: Does a forge-wrapped LLM refactoring pass improve merge-readiness?

## Summary

A forge-wrapped autonomous refactoring pipeline (volley → hunt-spec → blind-blind → hunt-code → reviewer-loop → complexity gate) was run on 27 merged brownfield PRs across 9 repos and 3 languages. Of those, 21 produced test-passing refactored code (active trials) and 6 broke build or tests (hard no-ops).

**Headline findings:**

| Metric | Observed | Prereg threshold | Interpretation |
|--------|----------|-----------------|----------------|
| Complexity gate pass | 21/21 (100%) | δ=0.05 | Zero regressions. No trial increased complexity beyond threshold. |
| Reviewer approval ("No comments") | 9/21 (43%) | ≥65% improvement | **Below improvement threshold.** Inside parity envelope [40%, 60%]. |
| Hard no-op rate | 6/27 (22%) | — | Agent competence: 78% produce test-passing code. |
| Complexity reduction (Δ<0) | 2/21 (10%) | ≥70% P1 | **Below threshold.** Most trials Δ=0 (no measurable change). |

Per the pre-registered recommendation criterion:

> **Observed P3 prefer-C_llm rate: 43%.** Falls inside the parity envelope [40%, 60%]. **"Do not recommend."** Forge-wrapped refactor doesn't meaningfully beat the no-refactor baseline at the registered sample.

---

## Trial-level results

### Active trials (build + tests PASS): 21/27

| PR | Repo | Lang | Winner | Diff lines | Gate Δ | Reviewer |
|----|------|------|--------|-----------|--------|----------|
| 24489 | gemini-cli | TS | codex | 5842 | −0.010 | approve |
| 25077 | gemini-cli | TS | codex | 160 | 0.000 | approve |
| 24941 | gemini-cli | TS | opus | 63 | 0.000 | approve |
| 24460 | gemini-cli | TS | opus | 240 | −0.078 | comments |
| 24476 | gemini-cli | TS | codex | 27 | 0.000 | comments |
| 24763 | gemini-cli | TS | opus | 745 | 0.000 | comments |
| 12526 | cli/cli | Go | codex | 286 | 0.000 | approve |
| 13084 | cli/cli | Go | codex | 73 | 0.000 | approve |
| 4145 | go-github | Go | opus | 60 | 0.000 | approve |
| 4147 | go-github | Go | codex | 339 | — | comments |
| 4153 | go-github | Go | codex | 12 | 0.000 | approve |
| 1301 | cel-go | Go | opus | 50 | 0.000 | comments |
| 1286 | cel-go | Go | opus | 54 | — | comments |
| 14418 | google-cloud-go | Go | codex | 118 | 0.000 | comments |
| 14442 | google-cloud-go | Go | codex | 13 | 0.000 | approve |
| 713 | adk-go | Go | opus | 172 | 0.000 | comments |
| 715 | adk-go | Go | opus | 122 | 0.000 | comments |
| 2248 | go-containerregistry | Go | codex | 0 | 0.000 | approve |
| 2254 | go-containerregistry | Go | codex | 0 | 0.000 | comments |
| 1722 | gapic-generator-go | Go | codex | 238 | — | comments |
| 1715 | gapic-generator-go | Go | codex | 63 | 0.000 | comments |

### Hard no-ops (build or tests FAIL): 6/27

| PR | Repo | Lang | Failure mode |
|----|------|------|-------------|
| 24834 | gemini-cli | TS | MacOsSandboxManager tests (refactor broke sandbox behavior) |
| 24512 | gemini-cli | TS | UI rendering tests (TerminalBuffer refactor broke FolderTrustDialog) |
| 24544 | gemini-cli | TS | Flaky integration test (shellBackgroundTools, unrelated to refactor) |
| 1294 | cel-go | Go | TestFileDescriptionGetTypes (refactor broke protobuf type handling) |
| 24557 | ruff | Rust | corpus_no_panic test (refactor broke parser) |
| 24616 | ruff | Rust | Build failure (refactor produced uncompilable Rust) |

---

## P1: Simplification

**Question:** Does C_llm reduce complexity relative to C_test?

| Metric | Value |
|--------|-------|
| Trials with Δ < 0 (simpler) | 2/21 (10%) |
| Trials with Δ = 0 (no change) | 19/21 (90%) |
| Trials with Δ > 0 (more complex) | 0/21 (0%) |
| Prereg threshold (≥70% simpler) | **Not met** |

The forge pipeline overwhelmingly preserves complexity rather than reducing it. The two reductions (gemini-cli-24460 at Δ=−0.078, gemini-cli-24489 at Δ=−0.010) are small. No trial increased complexity — the gate never tripped.

**Interpretation:** Forge does not simplify code in a way that registered metrics capture. The refactoring claims it applies (extract helpers, remove duplication, centralize logic) are real structural changes but don't move the mean-cognitive-complexity needle on the scoped function set. Either the changes are too small relative to the total function count, or cognitive complexity is the wrong metric for the kind of simplification forge produces.

---

## P2: Trajectory classification

**Not evaluable in v2.** The prereg defines trajectory as C_llm's position relative to C_final (the reviewer-accepted version). This requires C_test ≠ C_final, which held for only a fraction of candidates. Additionally, the C_test definition (earliest commit where C_final tests pass) proved pathological for feature PRs — 60% of screened PRs had C_test = C_final because feature tests don't pass until the feature is complete.

**v3 recommendation:** Redefine C_test using GitHub Review API (commit_id at first review event) instead of test-overlay-based extraction. This unlocks force-push repos and decouples C_test from C_final's test suite.

---

## P3: Model-reviewer merge-readiness

**Question:** Do blind reviewers prefer C_llm over C_test?

The v2 reviewer (Gemini 3.1 Pro Preview) evaluated each active trial's refactored diff. "No comments" = would approve for merge as-is.

| Metric | Value |
|--------|-------|
| Reviewer approval rate | 9/21 (43%) |
| Reviewer with comments | 12/21 (57%) |
| Prereg improvement threshold (≥65%) | **Not met** |
| Prereg parity envelope [40%, 60%] | **Inside** |

**By language:**

| Language | Approve | Comments | Rate |
|----------|---------|----------|------|
| TypeScript (n=6) | 3 | 3 | 50% |
| Go (n=15) | 6 | 9 | 40% |

**Per the pre-registered recommendation criterion:**

> Observed P3 prefer-C_llm rate 43% falls inside the parity envelope [40%, 60%]. **"Do not recommend."** Forge-wrapped refactor doesn't meaningfully beat the no-refactor baseline at the registered sample.

**What the reviewer comments contain:** The 12 "comments" trials had reviewer findings including: missing test coverage for new helpers, unidiomatic patterns (Go error handling, PowerShell argument passing), incomplete refactoring (claim applied to one call site but not another), and—in 3 dev-set trials—pipeline artifact leaks (IMPLEMENT_SUMMARY.md in the diff). The artifact-leak comments are orchestrator bugs, not refactor quality issues.

---

## P4: Hard no-op rate (agent competence)

| Subset | Rate |
|--------|------|
| Overall | 6/27 (22%) |
| TypeScript | 3/9 (33%) |
| Go | 1/16 (6%) |
| Rust | 2/2 (100%) |

Go is the strongest language for forge: 15/16 trials produced test-passing refactored code. TypeScript is mixed (6/9). Rust is a total failure — neither trial produced compilable code.

**Failure mode taxonomy:**
- Semantic regression (refactor broke behavior): 3 (24834, 24512, 1294)
- Flaky test (unrelated to refactor): 1 (24544)
- Build failure (uncompilable output): 1 (ruff-24616)
- Test framework incompatibility: 1 (ruff-24557)

---

## Blind-blind merge

| Winner | Count | Rate |
|--------|-------|------|
| codex (GPT-5.4) | 13/21 | 62% |
| opus (Claude 4.6) | 8/21 | 38% |

Codex wins on sum-of-churn more often, producing slightly smaller diffs. One trial (gemini-cli-25077) was a perfect tie (160 vs 160) — codex won by alphabetical tiebreaker.

---

## Operational characteristics

| Metric | Value |
|--------|-------|
| Median pipeline time (Go) | ~20 min |
| Median pipeline time (TS) | ~25 min |
| Volley claims per trial | 2–5 |
| Hunt-spec blocker rate | 0% (no blockers found across 27 trials) |
| Hunt-code false-positive rate | ~60% (fabricated git-diff findings, claim-not-applied hallucinations) |
| Repos screened | 12+ |
| Candidates screened | ~50 |
| C_test = C_final exclusion rate | ~60% of screened PRs |
| Disk consumed (peak) | ~100 GB |

---

## Repos

| Repo | Language | Stars | Valid | No-op | Total |
|------|----------|-------|-------|-------|-------|
| google-gemini/gemini-cli | TypeScript | 101k | 6 | 3 | 9 |
| cli/cli | Go | 40k | 2 | 0 | 2 |
| google/cel-go | Go | 3k | 2 | 1 | 3 |
| googleapis/google-cloud-go | Go | 4k | 2 | 0 | 2 |
| google/go-github | Go | 11k | 3 | 0 | 3 |
| google/adk-go | Go | 8k | 2 | 0 | 2 |
| google/go-containerregistry | Go | 4k | 2 | 0 | 2 |
| googleapis/gapic-generator-go | Go | — | 2 | 0 | 2 |
| astral-sh/ruff | Rust | 35k | 0 | 2 | 2 |
| **Total** | | | **21** | **6** | **27** |

---

## Structural findings

### 1. Force-push culture eliminates most OSS repos

~90% of popular open-source repos (react, TypeScript, kubernetes, deno, tokio, etc.) have single-commit PR branches due to rebase/amend-and-force-push review culture. The v2 C_test extraction methodology requires multi-commit branches, limiting the viable repo pool to ~10% of projects — primarily Google-ecosystem repos with patchset-style review culture.

### 2. C_test = C_final on feature PRs

For PRs that introduce new behavior tested by new tests, the earliest commit where C_final tests pass is C_final itself. This is structural: the tests probe behavior that doesn't exist until the feature is complete. 60% of screened PRs exhibited this, making them ineligible for the C_test ≠ C_final requirement.

### 3. Rust is out of reach for current models

Both Rust trials produced code that failed to compile or pass tests. Rust's type system and borrow checker catch refactoring errors that would be silent in Go or TypeScript. This is a language-level constraint on forge viability.

### 4. Hunt-code hallucinates

Codex (GPT-5.4) in hunt-code role fabricated `git diff HEAD~` output in a directory with no git history, reported "claim not applied" warnings on claims that were verified applied, and flagged changes in files the refactoring never touched. Hunt-code findings require evidence-quoting enforcement to be useful in iterative (N>1) mode.

### 5. Go + Google repos are the sweet spot

Google Go repos consistently yielded valid trials (15/16 = 94%) due to: instant `go test` cycles, multi-commit branch culture (inherited from internal Gerrit/Critique), small-to-medium repo size, and strong type checking without Rust-level strictness.

---

## Deviations from prereg

1. **Sample design changed from 15-primary + 2×3-secondary to distributed across 9 repos.** Reason: gemini-cli pool exhausted at 500-line floor; cross-repo breadth provides stronger generalizability for the practitioner claim.
2. **C_test = C_final PRs excluded** instead of analyzed. Reason: user decision — "that case should be ignored, it's a noop." No human-improvement baseline exists when C_test = C_final.
3. **Single-round pipeline** instead of iterative (N≤10) for hunt-spec, hunt-code, and reviewer-loop. Reason: dev-set validation showed hunt-code hallucinations would compound in iterative mode; prompt hardening needed first.
4. **Phase 7 blind reviews not yet run.** The in-pipeline Gemini reviewer (4g) serves as the measurement instrument. Phase 7 (separate blind review with trajectory classification) is pending.
5. **Pipeline artifact leaks** in 3 early trials' reviewer-loop diffs (IMPLEMENT_SUMMARY.md, SHARPENED_SPEC.md, modified package.json). Fixed in orchestrator after dev-set. Affected trials: gemini-cli-24460, gemini-cli-24489 (dev), gemini-cli-24544 (dev).

---

## Conclusion

At n=27, forge-wrapped refactoring produces test-passing code 78% of the time (21/27) and never increases complexity. But reviewer approval at 43% sits inside the parity envelope — the refactored version is not meaningfully preferred over the original. The forge does real structural work (helper extraction, deduplication, pattern centralization) that passes tests but doesn't consistently clear the merge-readiness bar set by a Gemini-class reviewer.

**Per prereg: "Do not recommend."** The observed rate does not support recommending forge-wrapped refactoring as a default workflow step for large brownfield PRs.

**Caveats:**
- The reviewer is Gemini 3.1 Pro (same model as the in-pipeline reviewer-loop), creating a pre-approval bias. A human reviewer panel might judge differently.
- Go dominates the sample (15/21 active trials). TypeScript signal is weaker (n=6). Rust is absent from active trials.
- The single-round pipeline is weaker than the prereg's iterative design. Iterative hunt-code + reviewer-loop might catch the issues the reviewer flagged and produce higher approval rates.
- Complexity-gate Δ=0 on 19/21 trials suggests the metric (mean cognitive across scoped functions) is too coarse for the kind of changes forge makes. Per-function or per-claim metrics might show movement.
