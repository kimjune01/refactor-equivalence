# Work Log

## 2026-04-14

### 19:30 — Session start: prereg design with Dexter Horthy

Discussion about the prework blog post surfaced a third axis for PR review: complexity trajectory (the slop-slope). Predicate and transformation are axes 1 and 2; most agents skip axis 3. Decided to design an experiment testing whether an LLM refactoring pass after tests pass can control this axis.

### 19:45 — Repo and prereg scaffolding

Created `~/Documents/refactor-equivalence/`. Initial prereg: equivalence class framing, three claims (simplification, convergence, merge-readiness), 30 PRs from gemini-cli. Refactoring prompt v1 drafted. Extraction script scaffolded.

### 20:00 — Codex review rounds 1-3

Volleyed prereg with GPT-5.4 three times. Major changes: separated three claims, failed refactors stay in dataset, clean-room procedure (strip .git, no network), post-cutoff PRs only, C_final renamed from C_merge, operational C_test definition, multiple reviewers per PR, mixed-effects model, pilot for feasibility only, futility conditions.

### 20:15 — Simplified failure model

Test-passing is a precondition, not a variable. Agent either produces a member of the equivalence class (measure it) or doesn't (no-op, scored as C_test). Dropped the five-category failure taxonomy. The interesting failure is the slop-slope: passing tests while increasing complexity.

### 20:25 — Repo selection

Primary: google-gemini/gemini-cli (15 PRs). Secondary candidates: kubernetes (Go), rust-lang/rust (Rust), llvm (C++), django (Python) — 3 PRs each, expandable to 10. Caliber bar locked, specific repos not locked. Queen's-table argument: if it works on the strictest repos, down-induction to simpler ones is plausible.

### 20:30 — C_test definition fix

Backport C_final tests onto earlier commits. C_test = earliest commit where merge-time tests pass. Ensures same behavioral contract across all snapshots.

### 20:35 — Bias toward larger PRs

Minimum 100 LOC, maximum 2000 LOC. Prefer larger within range. Maximal surprise: if refactoring works on large PRs, small ones are implied.

### 20:40 — Cut convergence, add three-class directional model

Dropped distance-to-C_final as a metric. C_final is a directional proxy, not ground truth. Each trial classified: past C_final (strongest evidence), short of C_final (improved but not enough), wrong direction (slop-slope). Reviewer-judged trajectory is headline; scalar complexity calibrates.

### 20:50 — Measurement confidence: reviewer-judged + scalar calibration

Codex recommended (and we adopted): reviewer classification is primary, scalar is calibration. Boundary threshold δ set after pilot. Sensitivity analysis across multiple metrics. Disagreements are findings about metric validity.

### 20:55 — Prompts directory

Created `prompts/meta/generate-repo-prompt.md` (metaprompt for repo-specific prompts), `prompts/meta/reviewer-task.md` (two-phase reviewer instructions), updated `prompts/refactor-v1.md` (agent gets diff + allowed files, fewer concepts > fewer lines).

### 21:00 — Scientific method audit pass

Walked the prereg through all 20 thinkers from the /reading/scientific-method/ collection. Two real catches: Popper (P2 bar too low, raised from 30% to 50%) and Feynman (dev/test circularity, added non-overlap requirement). Added trail commitment, acknowledged narrow causal claim, dropped memorization threat per Chinese Room.

### 21:05 — Blog: prereg checklist

Created `/reading/scientific-method/prereg-audit/` with 20 questions from the collection. Moved to `/methodology` as blog post `2026-04-14-prereg-audit.md`. Renamed to "Prereg Checklist." Copyedited. Agent audience made explicit.

### 21:15 — Ran own checklist against own prereg

Five gaps fixed: Q3 assumptions listed, Q8 competing explanations, Q12 paradigm assumption, Q16 PPV estimate, Q20 expansion is exploratory not confirmatory.

### 21:25 — Edit-set leak fixed

Reverted LLM edit scope from C_base→C_final to C_base→C_test. C_final file list is information leakage. Two-analysis rule for no-ops: intent-to-treat for P3, observed-only for mixed model.

### 21:35 — Forge pipeline as procedure

Replaced single-shot refactoring prompt with full forge pipeline: volley (sharpen) → blind-blind-merge (opus + codex) → bug-hunt (adversarial review) → volley (clean). Prompts and metaprompts updated to describe forge input spec.

### 21:40 — GPT-5.4 training cutoff confirmed: August 31, 2025

Binding cutoff is the later of the two forge models. PRs merged after September 2025 are eligible.

### 21:45 — Slop-slope attribution

Gmail confirmed: Dexter Horthy coined "slop-slope" in his email reply to the prework post. Credited in both the prereg and the prework blog post.

### 21:50 — Prework post updated

Added "The third axis" section crediting Dexter, explaining the slop-slope, linking to the experiment repo.

### 21:55 — Batch expansion rule

Group sequential: run batches, look at results, expand if uncertain. No fixed maximum sample size. Stopping rule is confidence, not a number. Every expansion decision logged before next batch. Q20 answer updated.

### 22:00 — Reviewer model: Gemini 3.1

No self-review conflict — Gemini doesn't participate in forge (opus + codex). Vertex AI credentials at ~/Downloads/atom.json. Do not commit credentials.

### 22:05 — Slop-slope attribution confirmed

Gmail thread with Dexter Horthy confirmed: he coined "slop-slope" in his reply to the prework post. Credited in both the prereg (formal definition) and the prework blog post (new "third axis" section linking to HumanLayer and the experiment repo).

### 22:10 — Batch expansion rule

Group sequential stopping: run batches, look at results, expand if uncertain. No fixed max sample size. Evidence compounds across batches. Every expansion decision logged before next batch. Aligns with Ramdas Q20 — peeking is fine when the trail is published.

### 22:15 — Gemini CLI configured for Vertex AI

Installed gemini CLI v0.38.0. Service account: `junekim@qvs-atom-gcp-research.iam.gserviceaccount.com`. Model: `gemini-3.1-pro-preview`. Credentials at `~/Downloads/atom.json` (do not commit). Required env: `GOOGLE_GENAI_USE_VERTEXAI=true`, `GOOGLE_CLOUD_LOCATION=global`. zshrc alias set with default model and `--approval-mode auto_edit`.

### 22:25 — All three agents verified writing to /tmp

| Agent | Command | Write flag |
|-------|---------|------------|
| Claude Opus 4.6 | `claude` | auto-edit (default) |
| Codex GPT-5.4 | `codex exec` | `-s danger-full-access` |
| Gemini 3.1 Pro | `gemini` | `--approval-mode yolo --include-directories <workspace>` |

Three models, three roles, no overlap: opus + codex forge, gemini reviews. All confirmed writing files in `/tmp/agent-verify/`.

### 22:30 — Prereg checklist audit (eating our own cooking)

Ran the 20-question prereg checklist against our own prereg. Five gaps fixed: Q3 assumptions, Q8 competing explanations, Q12 paradigm, Q16 PPV, Q20 sequential validity. The checklist caught real problems on its first use.

### 22:35 — Blog: prereg checklist copyedited

Agent audience made explicit. Questions 3/5/12/18 sharpened for agents. Closing rewrites: "registering a story" / "filtered final narrative." Codex reviewed, sharpen pass converged in one round.

**Status:** Prereg converged. All three agents verified. Gemini CLI configured. Ready to pull dev-set PRs from gemini-cli and start the pilot.

## 2026-04-15

### Session 2 start — dev-set extraction

Correct repo path is `google-gemini/gemini-cli`, not `google/gemini-cli`. Fixed across PREREG, BOOTSTRAP, README, worklog. Old name was GraphQL-unresolvable.

### Dev-set candidate pool

89 PRs in `samples/candidates-gemini-cli.json`, merged after 2025-09-01, 100–2000 LOC, APPROVED. Filter applied via `gh pr list --search "merged:>2025-09-01"` then jq size filter. All post-GPT-5.4 cutoff (2025-08-31).

### Pilot dev set locked: 5 PRs

`samples/dev/PILOT.md`: PRs 24483, 25101, 24489, 24437, 24623. All touch `packages/core`. All have ≥4 reviews and ≥2 commits. Diversity across feat/refactor/fix. Remaining 84 candidates reserved for test set — no overlap permitted until prompt freeze.

### Working clone at /tmp/refactor-eq-workdir/gemini-cli

Node 22, npm 10. `npm ci` clean (1296 packages, 17 known audit issues — acceptable for reproducibility). Monorepo with 7 workspaces. Core workspace test: `npm run test --workspace @google/gemini-cli-core` → `vitest run`.

### Extraction scaffolding

`scripts/find_c_test.sh`: walks PR commits oldest→newest, overlays C_final test files, runs locked test command, records earliest passing commit. Pilot PR is 24437 (8 files, 4 commits, smallest of the five — best feasibility canary).

PR 24437 snapshots: C_base=7d1848d, C_final=e169c700. Test files from C_final: `local-executor.test.ts`, `complete-task.test.ts`. Running core tests at C_final now to verify baseline passes in clean clone.

### Test-command lock for gemini-cli

Two pilot findings on the correctness gate:

1. **Pre-test build required.** `packages/core` self-imports `@google/gemini-cli-core`, and 5 test files fail resolution unless the package is built first. `posttest: build` in `package.json` is not adequate — we need `npm run build --workspace @google/gemini-cli-core` BEFORE `vitest run`.
2. **One environment-dependent test excluded.** `sandboxManager.integration.test.ts` asserts that sandboxed writes fail — but on a clean developer Mac without an enforced sandbox binary, the write succeeds and the test fails. Excluded from the locked test command. No pilot PR touches sandboxManager, so no analytic impact.

Locked test command (recorded in `prompts/repos/gemini-cli.md`): build core, then `cd packages/core && npx vitest run --exclude '**/sandboxManager.integration.test.ts'`. 338 files / 6574 tests pass at C_final (e169c700).

### Running find_c_test on PR 24437

`scripts/find_c_test.sh` walks PR commits oldest→newest, overlays C_final test files, runs the locked test command, records the earliest passing commit as C_test. Running now for PR 24437 across its 4 commits.

### PR 24437: C_test = ffd11f5f, 2 post-test commits of substantive revision

find_c_test walked 4 commits. Commit 1 (`9a47b201`) fails — first commit doesn't yet implement complete_task trimming. Commit 2 (`ffd11f5f`, "trim 'result' parameter in complete_task validation") is the earliest passing commit → C_test. Commits 3–4 are post-tests-pass revision (`066ee62b` "explicitly verify tool name", `e169c700` "use helper for tool argument parsing"). The C_test→C_final delta touches one source file (`local-executor.ts`, 71 lines) — substantive and within scope.

Allowed edit set at C_test: 6 source files, 436 LOC of churn from C_base.

### Clean-room pitfall: relative workspace symlinks

First clean-room build symlinked `node_modules` wholesale from the source clone. The workspace self-links (`node_modules/@google/gemini-cli-core -> ../../packages/core`) are relative, so they resolved to the SOURCE clone's packages, not the clean-room's — breaking isolation (tests would run source-clone code regardless of what we put in the clean-room).

Fix: run `npm ci --prefer-offline` inside the clean-room (~20s warm). `build_cleanroom.sh` updated. Re-verified: 338 test files / 6574 tests pass at C_test inside the clean-room, matching C_final counts.

### Forge pipeline complete for PR 24437 — C_llm produced

Full forge pipeline: Volley (sharpen) → Hunt-spec → Blind-blind-merge → Hunt-code → Volley-clean. All steps converged.

**Volley (sharpen).** Round 1: codex produced 6 claims. Round 2: I rejected one (Claim 2 — removing missing-arg checks would break 4 test assertions). 5 claims accepted, spec stable.

**Hunt-spec.** Round 1: codex found 2 warnings — (1) import convention rationale was overbroad (narrowed to consumers *outside* tools/), (2) RESULT_PARAM replacement targets imprecise (made all 4 edits explicit). Fixed spec. Round 2: zero findings.

**Blind-blind-merge.** Opus subagent + codex subprocess, same spec, separate /tmp dirs. Both produced *byte-identical* output. Convergent blind implementation — merge trivial.

**Hunt-code.** Gemini 3.1 Pro adversarial review. Zero findings.

**Volley-clean.** One round: 15 insertions / 15 deletions, no dead code, naming consistent. Converged immediately.

**C_llm diff from C_test.** 2 files, 30 lines changed:
- `local-executor.ts`: import rerouted to tool-names.js, `catch (_)` → `catch`
- `complete-task.ts`: `RESULT_PARAM` constant, `formatSubmittedOutput` helper, `${COMPLETE_TASK_TOOL_NAME}` in error text

Tests: 338 files / 6574 tests / 28 skipped — **identical to C_test baseline**.

Artifact: `/tmp/refactor-eq-workdir/forge/24437/c_llm_diff.patch` (93 lines).

### C_random spec drafted

`prompts/meta/c-random.md` — TypeScript-specific transformation family: local renames, independent statement reordering, redundant parenthesization. Validated against both correctness (tests pass) and non-simplification (reject seeds that reduce complexity by more than δ). Edit budget to be calibrated after pilot observes `C_llm` magnitudes. Secondary-repo language families deferred to post-pilot.

### 18:18 — PR 24437 forge pipeline complete

PR 24437 forge pipeline complete. C_llm produced: 5/5 claims, opus+codex identical, gemini zero findings. Tests green (6574/6574). First pilot trial end-to-end feasibility confirmed.

### 18:25 — PR 24437 complexity measurement: C_llm is "past C_final"

Measured with `scripts/measure_complexity.mjs` (typescript-estree AST walker — cyclomatic, cognitive, nesting, LOC).

C_llm's mean cognitive complexity across touched functions: **10.27** (C_test: 10.84, C_final: 10.39). C_llm is past C_final on both primary scalar measures. Max-function complexity unchanged (processFunctionCalls stays at 43 CC / 77 cognitive across all snapshots). Zero LOC growth in C_llm vs +41 in C_final.

Full metrics in `samples/dev/24437-metrics.md`. This is n=1 pilot data. Scalar trajectory class agrees with "past C_final" — awaits reviewer classification for headline label.

**Pilot PR 24437 status:** Forge pipeline ✓, measurements ✓, trajectory scalar ✓. Remaining: blind review (deferred until all 5 PRs have C_llm), C_random (deferred post-pilot).

### 20:45 — Scope expansion: cli tests and parallel FS contention

Remaining pilot PRs (24483, 24489, 24623, 25101) touch both `packages/core` and `packages/cli`. Expanded the locked test command: build all workspaces, then run vitest in core (with sandboxManager exclusion) AND cli. Added ~100s per PR for cli tests.

Parallel FS contention: first attempt ran all 4 worktrees' tests concurrently — 3 failed on `logger.test.ts` and `write-file.test.ts` which both use shared `~/.gemini` state. Sequential re-run: all 4 pass cleanly at C_final. Lesson: across-PR parallelism is safe for build + volley + hunt-spec (no test runs), but test-running phases (find_c_test, verification) must be sequential.

Running find_c_test sequentially across all 4 remaining PRs. Worst case ~50 min, expected 20-30 min.

### 21:30 — All 4 remaining PRs: C_test reconstructed

| PR | C_test | Position | Post-test commits |
|----|--------|----------|-------------------|
| 24483 | `30d28fcb` | 1 of 2 | 1 |
| 24489 | `eb0fc840` | 8 of 10 | 2 |
| 24623 | `2357101a` | 1 of 3 | 2 |
| 25101 | `4ab03f18` | 2 of 5 | 3 |

100% reconstruction rate (5/5 including 24437). Futility condition #1 not triggered. PR 24489 had 7 failing earlier commits before first-pass — worth noting that the feature was iterated heavily during authoring.

### 21:40 — Clean-rooms built in parallel, forge inputs prepared

4 parallel cleanroom builds (git archive + npm ci): 24483 (18 files, 1123 LOC diff), 24489 (113 files, 6170 LOC diff), 24623 (48 files, 6679 LOC diff), 25101 (38 files, 1026 LOC diff). Allowed edit sets exclude tests, docs, schemas.

### 21:50 — Volley: 60 claims across 4 PRs; hunt-spec found real defects

Codex volley round 1 (parallel): 17/10/10/25 claims for 24483/24489/24623/25101. None had rejected items initially — codex defaults to additive when generating, only produces rejections when adversarially prompted. Consistent with training-data "good PRs are additive" bias.

Codex hunt-spec (parallel): real defects found in 3/4 PRs. Notably 24483's Claim 1 and Claim 10 would have triggered `__proto__` prototype-pollution by switching from manual `obj[k] = v` loops to `Object.fromEntries(map)`. 25101 clean. Reconciliation (also codex) moved problematic claims to rejection lists.

Final claim counts: 15/10/10/25 accepted, ~7-10 rejected each.

### 22:10 — Blind-blind merge: 8 agents in parallel, 85-90% convergence

4 opus subagents + 4 codex subprocesses executed the sharpened specs in parallel blind directories. All reported "Applied N/N claims."

Convergence per PR:
- 24483: 2/5 files differ between opus and codex outputs
- 24489: 4/20 differ
- 24623: 4/7 differ
- 25101: 2/15 differ

Merge strategy: smaller-churn wins per file (proxy for structural simplicity).

### 22:20 — Verification: 3/4 passed cleanly; 24483 TypeScript bug, patched

PR 24489, 24623, 25101: build + core tests + cli tests all pass at C_llm. Identical test counts to C_test. Behavior preserved.

PR 24483: TypeScript build error at `contextCompressionService.ts:351`. A refactored early-return `if (record.level === 'FULL') return part;` narrowed the type union so the downstream `case 'FULL':` in the switch became unreachable. TypeScript correctly flagged it (error TS2678).

**Important:** hunt-spec missed this. The build catch is exactly what phase 4 (hunt-code / bug-hunt) is supposed to surface. One-line patch applied; rebuild green. Noting as a forge pipeline limitation: if hunt-spec doesn't include a type-check step, dead-switch-case type errors only surface post-merge. For future runs, suggest wiring `tsc --noEmit` into the spec-hunt prompt context.

### 22:30 — Model-role correction

I used gemini for hunt-code on PR 24437 (zero findings). Per prereg and /bug-hunt skill: **codex** is the adversarial reviewer in the forge pipeline. Gemini is reserved for phase 7 blind merge-readiness review (primary reviewer, no-self-review rule applies *there*, not to forge-internal hunt-code).

For consistency, re-running PR 24437's hunt-code with codex and running all 4 remaining PRs' hunt-code with codex.

### 22:50 — Pilot complete: 5/5 PRs, all past or boundary-past C_final, zero slop-slope

Full scoped measurements in `samples/dev/pilot-results.md`. Headline:

**All 5 C_llm ≤ C_final on mean cognitive complexity.** 3/5 clearly past (Δ ≤ -0.04), 2/5 within boundary δ=0.05. Zero wrong-direction, zero no-op.

**C_llm ≤ C_test on LOC in all 5 PRs.** C_final > C_test on LOC in all 5 (reviewers pushed additions, LLM pushed subtraction — the cleanest observable expression of the slop-slope hypothesis).

Max-function complexity is sticky across the board — the refactor and the reviewers both left the heaviest functions alone.

Pilot feasibility conditions all clear:
- C_test reconstruction rate: 5/5 = 100% (futility 1: no trigger)
- Reproducible tests: 5/5 pass sequentially at C_final (parallel collision issue noted, solvable)
- No-op rate: 0/5 = 0% after manual patch on 24483; strictly, 1/5 = 20% if we count the pre-patch broken state as no-op (still below 40% futility trigger)
- Metrics computable: 5/5
- PR size bounds appropriate: yes (4/5 PRs > 1000 LOC of refactor scope)

Next: reviewer-classified trajectory via phase 7 blind review (gemini primary, codex secondary where non-conflicted). That's the headline label per prereg.

### 23:10 — Prereg retrospective section appended (R1-R7)

Append-only retro on PREREG.md capturing lessons surfaced during pilot execution. R1 documents that the estimand is narrower than its wording (forge-wrapped, not LLM in general) and that a formal single-shot ablation isn't information-worth-trial — the practitioner prior is strong. R2 notes comparator-in-practice should have been named. R3 notes the reviewer additive bias reframe. R4 calls out small scalar deltas. R5-R7 are operational: parallel FS contention, hunt-code missed build-caught type error, codex volleys additively biased. Not amendments — the registered protocol stands.

### 23:20 — Phase 7 setup: gemini-only review path for pilot

Opus and codex both participated in blind-blind-merge on every pilot PR, so both are conflicted per prereg's no-self-review rule. Gemini is the only non-conflicted model. Prereg's ≥3 reviewer rule applies to the main sample, not the pilot (pilot is feasibility per prereg, question 5: "Can blind reviewers evaluate the diffs in reasonable time?"). Proceeding with gemini-only Phase 7 for pilot; locking 3-reviewer procedure for test set as pilot decision #3.

### 23:45 — Phase 7 results: P3 ✓ at 80%, P2 ✗, blinding failed 5/5

Gemini reviewed all 5 pilot PRs. **P3 cleared at 80%** (C_llm preferred in 4/5 forced-choice judgments, vs prereg target of 65%). **P2 failed at reviewer classification: 20% past C_final, 60% short, 20% wrong** — prereg target was past ≥50%, which isn't met.

Blinding completely failed: gemini correctly identified C_llm as LLM-generated in 5/5 PRs. Cited signatures: "aggressive destructuring," "DRYing helpers," "ES6 shorthand and clean interface fulfillment." The LLM's refactor moves have distinctive surface patterns gemini pattern-matches against. Critical for test set to address.

Scalar/reviewer disagreement: scalar said past-or-boundary-past on 5/5; reviewer says past on 1/5. The 3/5 boundary cases all collapsed to "short" under reviewer judgment. Scalar overestimates complexity improvement at small deltas.

Wrong direction documented on PR 25101: gemini flagged C_llm's out-of-scope logic rewrite in `complete-task.ts` — a move reviewers had actively reverted in the original PR's C_final. The LLM pipeline repeated a mistake reviewers already pushed back on. P4 (some refactors make things worse) has its first clean datum.

Full breakdown in `samples/dev/phase7-results.md`. Pilot is now information-complete on the registered outcomes; next is locking pilot decisions per prereg §Pilot Decisions.

### 23:55 — Retro R8: parity null vs improvement threshold

P2 was registered as an improvement threshold (past ≥ 50%) without a parity null. Under parity (LLM ≈ reviewer in taste), past would be ~30-40%, short ~40-50%, wrong ~10-20% just from symmetry around the median. Pilot observed 20/60/20 — inside the parity envelope but below its "past" lower bound. "Did P2 pass?" is ambiguous because we registered "beats" without specifying "matches." Filed as post-hoc analytical observation, not an amendment, to preserve prereg discipline. V2 design note: register both parity null and improvement threshold.

### 00:10 — Pilot decisions locked (PILOT_DECISIONS.md)

All 7 prereg-mandated pilot decisions locked: complexity tool config, review presentation format, reviewer population, C_random specifics, δ = 0.05, secondary expansion trigger, PR size bounds (clarified to measure at C_test). Blinding failure and P2 parity null flagged as v2 concerns, not blockers.

Notable: PR size is now explicitly measured at C_test, not C_final, with an exclusion list (tests, docs, schemas, lockfiles, snapshots). This clarifies a latent ambiguity that let PR 24489 (3099 C_test LOC) pass a selection filter based on C_final LOC (1268). 24489 stays in the pilot analysis per trail-commitment but wouldn't be eligible under the corrected bound.

Locked reviewer pool for test set: Gemini 3.1 Pro + Sonnet 4.5 + GPT-5. Gives 3 non-conflicted reviewers per PR even under the strict no-self-review rule.

### 00:25 — Secondary repo choice: cli/cli (Go)

Picked cli/cli over primary-depth test-set expansion. Justification: biggest expected-surprise candidate. Go is less represented in LLM training than TS/Python; `gofmt` normalizes surface style so LLM's typical "DRY this up" signatures are either inapplicable or immediately rejected by convention; no ternary / metaprogramming = less room for LLM-idiomatic consolidation; GitHub's own team has exacting review culture. If the slop-slope has language-specific limits, Go is where they'd show first.

Scaffolding needed: go complexity tool (gocyclo + gocognit), Go-specific C_random transformation family, test command lock (`go test ./...` TBC), candidate pool extraction.

### 00:45 — cli/cli pilot (3 PRs) scaffolding + forge pipeline

Candidate selection: 12567 (1050 LOC, gh pr edit Copilot reviewer), 12695 (634 LOC, workflow run dispatch details), 12846 (302 LOC, squash merge commit msg). 12846 excluded post-reconstruction: C_test == C_final, no post-tests-pass revision (inclusion condition 5 violated). Replaced with 12696 (779 LOC, project item-list --query flag). All C_test reconstructions passed.

Go tooling: `scripts/measure_complexity_go.sh` wraps gocyclo + gocognit. `scripts/build_cleanroom_go.sh` does git archive + go mod download (shared module cache). Test command locked to `go test ./...`. Cleanroom takes ~20s with warm module cache.

Forge pipeline ran parallel across 3 PRs: volley (8/5/8 claims), hunt-spec (real findings on all 3 including exact prediction of 12695's test failure), reconcile, blind-blind-merge (opus+codex each 8/4/8 claims applied), merge (2, 1, 2 files differ), verify.

### 00:55 — cli/cli results: 1 clear past, 1 boundary, 1 no-op

Verification:
- **PR 12567**: tests pass. Hunt-code flagged blocker (CopilotActorLogin → CopilotAssigneeLogin rename broke public API — spec said to restore alias but implementation didn't). Test suite doesn't exercise this export; trial counts as in equivalence class.
- **PR 12695**: **TESTS FAIL** → **no-op**. Exact prediction from hunt-spec: the `return_run_details: true` leaks into all dispatch requests, breaking TestRun (~8 subtests). Reconcile step failed to reject the problematic claim despite hunt-spec warning. Per prereg: C_llm = C_test for metrics, counts as wrong-direction in P2 and reviewer-prefers-C_test in P3.
- **PR 12696**: clean, zero findings. Mean cognitive 2.08 → 1.97 (past C_final by 0.11) and **max cognitive 32 → 23** — first pilot case where C_llm touched the hottest function.

Reconcile-failure-to-reject is a real pipeline gap. Hunt-spec caught it, reconcile didn't act on the warning. Recommendation for v2: reconcile must verify that every test-breaking hunt finding results in either claim rejection or a narrowing that changes the claim's net effect. Current reconcile reads the findings but isn't adversarial enough.

No-op rate: 1/3 = 33% on cli/cli, 0/5 = 0% on gemini-cli. Combined pilot: 1/8 = 12.5%. Still below 40% futility threshold.

LOC direction note: unlike gemini-cli where C_final consistently added LOC, cli/cli's C_final is close to C_test (+5, 0, -3 LOC on the 3 PRs). Go reviewers appear more surgical about scope than gemini-cli reviewers. "Reviewer additive bias" may be culture-specific, not universal.

### 01:10 — cli/cli Phase 7 review: 2/3 prefer C_llm, 2/3 wrong-direction

Full results in `samples/dev/cli-phase7-results.md`. Headline: **P3 preserved on Go** (2/3 = 67%, above 65% threshold) but **trajectory classification shifted unfavorable** (0/3 past, 1/3 short, 2/3 wrong).

Key findings:
1. **PR 12567**: tests pass but gemini flagged CopilotActorLogin → CopilotAssigneeLogin API break that the LLM refactor didn't restore despite spec direction. Classic slop-slope: test-passing code that regresses public API. Phase 1 preference contradicts phase 2 classification (gemini preferred C_llm for merge but said wrong-direction for trajectory).
2. **PR 12696**: C_test ≡ C_final on measured scope (only post-test commit was a test file). Trajectory classification degenerate. Inclusion condition 5 is too permissive — should require revision on scope files, not just any file.
3. **PR 12695**: no-op, hunt-spec had predicted it but reconcile didn't properly reject the claim. Reconcile step needs to be more adversarial toward hunt findings.

No-op rate so far: 1/8 combined = 12.5%.

Cross-repo pattern: gemini-cli 4/5 prefer C_llm + 1/5 past + 1/5 wrong; cli/cli 2/3 prefer C_llm + 0/3 past + 2/3 wrong. Wrong-direction rate jumps from 20% to 67% going from TS to Go (small n, noisy). Combined wrong rate 3/8 = 37.5% approaching parity-null upper bound. Secondary-repo expansion trigger not met (wrong ≥ 2/3 was the trigger, but 2/3 of a 3-PR batch is 67% which DOES hit the trigger under pilot decision 6 — should expand cli/cli to 10 PRs before interpreting).

### 02:30 — cli/cli expanded to 10 per pilot decision #6

Full cli/cli: 9 PRs eligible (4 exclusions from a 13-PR pick list), P3 7/9 = 78%, traj 1 past / 4 short / 2 wrong / 2 no-op. Summary in samples/dev/cli-expansion-results.md. Pipeline failure modes documented: reconcile-failure-to-reject, stale cross-package test fixtures, build-fail at C_final from squash-merge, C_test==C_final.

### 03:45 — fastapi secondary 3-PR: 1 excluded, 1 no-op, 1 wrong

Python tooling scaffolded: measure_complexity_py.sh (radon + cognitive_complexity), find_c_test_py.sh (overlay with untracked cleanup). Venv setup cost ~90min iterating on missing deps (pyjwt, pwdlib, orjson, typer, starlette, uvicorn, fastapi[standard], pytest plugins).

Results:
- 14978 EXCLUDED: C_test == C_final
- 14962 NO-OP: volley produced *preservation* claims instead of *refactoring* claims; opus+codex both made 0 changes
- 15022 WRONG: codex's refactor increased scalar complexity +0.06 over C_test. Clean slop-slope scalar datum.

Observed new failure mode — "descriptive-vs-prescriptive volley": codex's sharpened claims described "what the diff does" instead of "how to simplify the diff further." Resulting implementations verify existing state rather than modifying it. Recommend v2 prompt change: phrase claims as verbs ("simplify X"), not preservations ("preserve behavior of X").

### 04:00 — Cross-repo summary committed

Consolidated pilot findings across gemini-cli (TS, 5 PRs), cli/cli (Go, 9 PRs), fastapi (Python, 2 eligible). Combined: n=16 eligible, 11 active trials. P3 79% (on repos where measured). P2 trajectory: 12.5% past, 43.75% short, 25% wrong. Under retro R8 parity envelope: past UNDER parity (LLM underperforms reviewer on simplification beyond C_final), short IN parity (roughly equivalent to reviewer), wrong AT parity upper bound.

Secondary repos still pending: ruff (Rust, not attempted — cargo toolchain cost), django (Python, similar expected setup cost to fastapi). Follow-up can add them with 3-PR batches.

Full summary: samples/dev/cross-repo-summary.md.

### 14:00 — v2 prereg prep: improvements.md authored, 9 items locked

improvements.md authored with 18 ranked items across prompt fixes, structure changes, selection criteria, registration, ops. Locked through conversation:

- V1: prescriptive volley with goal=issue(s)+PR-body, artifact=diff. Empty Accepted Claims list allowed.
- V2: adversarial reconcile — blocker findings → mandatory reject parent claim.
- S1: complexity gate δ=0.05 on scoped mean cognitive, fall back to C_test.
- S2: hunt-code runs full build, not just typecheck.
- S4+C3 unified: 500 LOC threshold = blind-blind precondition = experiment eligibility. No single-agent path. Cap raised to 5000.
- S5: hunt-code stays broad, iterates to zero-findings (per /bug-hunt skill default).
- S6: reviewer-in-the-loop after merge; Gemini 3.1 throughout (in-pipeline + Phase 7); convergence on zero comments OR impasse on shrinking, N=10 safety bound.
- R1: parity null + improvement threshold for both P2 (past ∈ [25-45%], improvement ≥ 50%) and P3 (prefer-C_llm ∈ [40-60%], improvement ≥ 65%).
- R5: survivorship bias acknowledgment. Estimand restricted to "drafts of merged brownfield PRs." Bias direction makes positive results conservative (helps P1/P2/P3 credibility) but understates real-world slop-slope (hurts P4 prevalence claim).

Now launching codex to draft PREREG_V2.md from improvements.md + v1 + pilot decisions. Will critique codex's draft as next-round volley — push back hard on items that don't match locked decisions.

### 14:30 — v2 round 2 applied: all agreed-on push-backs

Codex drafted PREREG_V2.md (846 lines). Critique applied 10 fixes:
- Removed 4i Clean pass (v1 holdover, cleanup organic in 4g+4h)
- Blind-blind merge rule: smaller-churn vs C_test, alpha on tie
- Hunt-spec now iterates (parallel to hunt-code), N=10 cap
- Hunt-code N=10 cap explicit
- Caps reset per re-entry (don't accumulate)
- Training cutoff table: Opus/Codex/Gemini/Sonnet/GPT-5; binding 2025-09 → eligibility 2025-10-01+
- Sample size: pre-select ceil(target/0.70) to absorb 30% exclusion rate
- C_random per-language families locked (TS/Go/Rust/Python); committed for primary, timebox-gated for secondary
- Consolidated exclusion glob table (tests/docs/schemas/lockfiles/generated/vendored)
- P1 has no parity null because C_random plays that role; flagged v1 gap

PREREG_V2.md now committed (895 lines). Still open: codex's draft has remaining items I didn't push back on (proposed V3/V4/C1/C2/R2/R3/R4/O1/O2/O3 are inherited as-is). Could lock or refine in another round if needed.

### 14:55 — v2 round 3+4: R2 locked, trail commitment expanded, simpler-over-rigorous heuristic applied

R2 locked: single reviewer (Gemini 3.1) sufficient; multi-reviewer optional for IRR calibration on a subset. Pilot blinding failed 5/5 — adding LLM reviewers averages over the same surface-pattern signal. Reviewer also gets goal anchor (issue + PR title + body), mirroring volley.

Trail commitment expanded to capture every pipeline artifact per trial under samples/<set>/<repo>-<pr>/: goal text, inputs, volley round transcripts, hunt-spec rounds, blind-blind diffs, merge decisions, complexity gate JSON, hunt-code rounds, build/test logs, reviewer-loop transcripts (comments + addresses per round), final C_llm + C_random + measurements, Phase 7 review JSONs, Python venv manifests. Plus cross-trial summaries (candidate pool, exclusion log, scaffolding cost, reviewer-loop convergence stats). Posterior analysis can re-run statistics, swap reviewer models, or change metrics without re-running the pipeline.

Simpler-over-rigorous heuristic applied to remaining open items:
- Stat analyses: report rates + deltas; formal tests only if close to threshold
- V4 per-language template: short idiom notes, not exhaustive style guides  
- R4 scaffolding cost: log it, don't formalize
- All previously "proposed" items now marked locked: V3, V4, C1, C2, R2, R3, R4, O1, O2, O3

PREREG_V2.md final-ish at ~895 lines. Could send to codex for adversarial pass to surface anything I missed.

### 15:15 — v2 round 5: v3-prep layer

Added explicit v3-prep layer to PREREG_V2.md and seeded v3_questions.md (4 questions inherited from v1 pilot). Per-trial: anomalies.md + deviations.md populated in-flight. Cross-trial: v3_questions.md (running backlog) + failure_modes_v2.md (auto-aggregated at v2 end). The trail captures not just what happened but what surprised us about it, so v3 — if needed — starts from concrete observed gaps rather than retrospective reconstruction.

### 16:30 — v2 rounds 6-8: codex hostile-review applied + checklist audit + power-expansion path

Round 6 batched all of codex's hostile-review fixes:
- C_random dropped (control too weak to support inference)
- Reviewer protocol simplified: codex already adversarial throughout (hunt-spec, hunt-code), so one final reviewer (Gemini) is enough; no Sonnet/GPT-5 calibration
- Complexity gate moved to ship-time (after hunt-code + reviewer-loop converge)
- Blind-blind merge: whole-model selection (not per-file) to avoid Frankenstein candidates
- Estimand restated to "large drafts" to match the actual sample (down-induction implies small)
- P3 renamed "human merge-readiness" → "model-reviewer merge-readiness" (construct-mismatch fix)
- "What this would show" tightened: positive result supports forge bundle, not generic refactor pass

Round 7: ran 20-question prereg-checklist audit via codex hostile-review. Result: 8 PASS, 11 PARTIAL, 1 N/A. Cheap fixes added:
- Q20: hard cap (25 primary, 10 secondary) per repo; v1 was unbounded
- Q16: back-of-envelope power statement (~62% P3, ~58% P2 past at n=27); calls out small-n descriptive vs inferential
- Q8: each competing explanation annotated with v3 adjudication arm
- Saved PREREG_V2_audit.md as trail artifact

Round 8: power-expansion path locked. If sample is underpowered, add another secondary repo at 3 PRs rather than lift per-repo caps. Trades scaffolding cost for sample size; preserves language/culture diversity.

PREREG_V2.md is registerable. 8 commits across v2 prep. Open work: register the prereg, decide ruff/django (or other) secondary additions, run dev set.

### 17:00 — v2 round 11: scope tightened to TS/Go/Rust, doc tightened, 11 rounds total

Final scope locks:
- Drop django + fastapi (Python). v1 pilot showed Python setup was 90min of dep iteration; both eligible PRs no-opped. v3_questions pre-seed 7 captures "does forge work on Python?" as open question.
- Keep cli/cli (Go) + ruff (Rust) as secondaries.
- N=10 caps stay (surprise is bigger at 10 than 3 per user).
- Iterative hunt-spec stays (user's actual usage pattern).
- Sample: 21 minimum (15 + 2x3), 45 maximum (25 + 2x10).
- Power expansion = add repos (re-add Python first), don't lift per-repo caps.

Doc tightened: "Changes from v1" was numbered prose; now a bullet list. Per-repo registered-tools dropped Python entries. Sample-size totals simpler. PREREG_V2.md now ~1030 lines (was ~895 before rounds 6-10 added codex-hostile-review responses + analysis stance + recommendation criterion; back to readable density).

11 total v2-prep rounds. Next: register the prereg, then start v2 dev-set extraction on gemini-cli.

### 17:30 — v2 round 12: dev-env timebox locked

2-hour wall-clock to first passing build at C_final per repo. Timebox hit → drop the repo, substitute the next eligible secondary. No infrastructure-debugging iteration. Codifies the de facto v1 pilot behavior (fastapi dropped after ~90min). Protects the experiment from being held hostage by recalcitrant repo setup.
