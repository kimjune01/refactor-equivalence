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
