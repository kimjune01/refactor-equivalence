# Pilot decisions — locked 2026-04-15

Per PREREG.md §Pilot Decisions. These decisions were pending until the pilot informed them; they are now locked and apply to all test-set extraction, refactoring, and analysis from this date forward. Any change after this point requires a registered amendment.

## 1. Complexity tool and configuration

**Tool**: `scripts/measure_complexity.mjs` — AST walker built on `@typescript-eslint/typescript-estree`.

**Parser version**: `@typescript-eslint/typescript-estree` bundled with the target cleanroom's `node_modules`. Each PR's measurement must be run from inside its cleanroom to pin to the project's actual TypeScript parser version, so that parser differences don't leak into the metric. Pinned version is logged in each PR's measurement record.

**Node runtime**: ≥ 22.x.

**Parse options**: `{ loc: true, range: true, jsx: true }`. No project file resolution (pure syntactic parse, avoids cross-file contamination).

**Per-function metrics**:
- Cyclomatic: +1 per `if`, `for`, `while`, `do-while`, `case` with test, `catch`, `?:`, and each `&&`/`||`/`??` in a logical expression. Base 1 for the function itself.
- Cognitive: Sonar-style model — +1 per nesting-incrementing structure, +nesting-level for nesting increments, +1 per logical short-circuit operator.
- Max nesting depth.
- LOC (`end_line - start_line + 1`).

**Per-snapshot aggregation**:
- Sum of function counts across scoped files.
- Weighted mean cyclomatic and cognitive across all scoped functions (weight = function count per file).
- Max cyclomatic, max cognitive, max nesting across all scoped functions.
- Total scope LOC (sum of file-level LOC, not function-level).

**Scope**: union of `*.ts` and `*.tsx` files (excluding `*.test.{ts,tsx}`) present in either C_test OR C_llm. Files in C_final only are **not** in scope — they reflect reviewer-expanded work outside the refactoring target.

**Primary scalar**: weighted mean cognitive complexity across touched functions.

**Secondary scalars**: weighted mean cyclomatic, max cyclomatic, max cognitive, max nesting, function count, total LOC.

**Language scope**: TypeScript only. Secondary-repo languages (Go, Rust, Python) will require separate tool selection, locked at the point of their extraction.

## 2. Review presentation format

**Delivery**: per-PR markdown bundle committed to `samples/<set>/<PR>/review-bundle.md` with sibling files `diff-A.patch`, `diff-B.patch`, `diff-C_final.patch` (patched in for Phase 2).

**Diff format**: unified diff with default 3-line context. Labels rewritten to neutral `a/<path>` and `b/<path>`. No syntax highlighting; plain text.

**Presentation order**: sequential, not side-by-side. Reviewer reads Candidate A entirely, then Candidate B, then (Phase 2) C_final.

**A/B assignment**: deterministic by `shasum -a 256 "$PR" | cut -c1` — first hex char maps to 0 or 1 based on high bit. Seed recorded in `review-assignment.json`. This is the only non-informational structure visible to the reviewer.

**Reviewer-facing content**: PR title, PR body, neutral task description, the three diffs (staged in two phases). Everything else — original discussion, commit messages, review comments, post-C_test commits, other reviewers' answers, which candidate is LLM — is withheld.

## 3. Reviewer population criteria

**Primary reviewer**: Gemini 3.1 Pro Preview via Vertex AI (`gemini-3.1-pro-preview`). No conflict — does not participate in blind-blind-merge.

**Secondary reviewers** (test set only; pilot was n=1):
- Claude Sonnet 4.5 (different model identity from Opus 4.6; family-adjacent conflict noted as a limitation)
- OpenAI GPT-5 via the OpenAI API (non-codex; different model family from Codex GPT-5.4)

**No-self-review rule**: a model that participated in generating `C_llm` may not review that trial. In practice this disqualifies Opus and Codex from all forge-wrapped trials, since both generate blind-blind candidates.

**Reviewer count per PR**: target ≥3. Given the no-self-review rule, the test set achieves 3 by using Gemini 3.1 Pro + Sonnet 4.5 + GPT-5. If any model is unavailable at review time, the trial proceeds with available non-conflicted reviewers and the count is recorded. Below-target reviewer counts are reported; the sample is not discarded.

**Model invocation parameters**:
- Gemini: `--approval-mode yolo`, default temperature, single prompt per phase.
- Sonnet 4.5 and GPT-5: single prompt per phase, default temperature, no tools needed beyond file reading.

**Determinism**: each invocation is a single call; no multi-round deliberation. The pilot's gemini runs confirmed the instrument is stable at n=1 per PR; adding parallel reviewers for variance measurement is part of the test set protocol, not the pilot.

## 4. C_random generator specifics

**Transformation family (TypeScript)**:
1. Local variable and parameter renames (exported symbols and JSDoc-named parameters excluded).
2. Independent statement reordering within a basic block (no shared writes, no call-order constraints).
3. Redundant parenthesization of already-parenthesizable sub-expressions.

**Edit budget per PR**: 50% of `|C_llm - C_test|` absolute LOC delta, rounded up to 10 lines. Computed per-PR after `C_llm` is produced. Floor of 10 edits if the delta is 0.

**Random seed**: `sha256(PR_number || "random" || attempt_N)` first 8 hex digits → decimal. Attempts increment if a seed produces an invalid control.

**Validation**:
1. Locked test command must pass on `C_random`.
2. Scoped mean cognitive complexity after the transformation must not decrease by more than δ=0.05 relative to `C_test`. (Prevents accidental simplification.)

**Invalid-control handling**: on failure, regenerate with the next seed, up to 5 attempts. If 5 attempts fail, `C_random` is recorded as invalid for that PR and excluded from control comparisons for that trial.

**Scope**: only source files in C_test's allowed edit set. Never touches tests.

**Language scope**: TypeScript only for now. Secondary-repo language families are deferred until secondary extraction begins.

## 5. Boundary threshold δ

**δ = 0.05** on mean cognitive complexity.

Justification: pilot observed |C_llm − C_final| deltas ranging 0.01–0.12. Reviewer-classified "past" corresponded to scalar delta 0.08 (24483). Scalar-boundary trials (delta < 0.05) were all reviewer-classified as "short" or "wrong." Fixing δ at 0.05 aligns scalar boundary with reviewer-uncertain region: trials with scalar delta < 0.05 should not be classified on scalar alone; reviewer judgment decides.

Under this δ, the pilot's scalar labels would be:
- Clearly past: 2/5 (24437 at 0.12, 24483 at 0.08)
- Boundary: 3/5 (24489 at 0.03, 24623 at 0.04, 25101 at 0.01)
- Clearly wrong: 0/5

Reviewer labels gave: 1 past, 3 short, 1 wrong. Agreement on the 2 clearly-past scalar labels was 1/2 (24437 was reviewer-classified short despite scalar past). Boundary cases offered no scalar guidance — exactly as δ intends.

## 6. Secondary repo expansion trigger

**Expand a secondary repo from 3 to 10 PRs if any of:**

- **Forced-choice preference for C_llm drops below 50% at n=3.** Primary achieved 80%; a secondary below 50% is a conflict worth resolving with more data.
- **Wrong-direction rate ≥ 2/3 trials.** Primary observed 1/5 = 20%; a secondary at 2/3 = 67% would be dramatically higher and warrants confirmation.
- **Zero "past" trials.** If a secondary yields 0 past in 3 trials while primary showed any past, expand to see whether the effect transfers.

Any of these triggers expansion. All three not-triggered means the secondary result is consistent with primary; no expansion needed.

**Documentation**: every expansion decision and its rationale is logged in the work log before the expanded batch begins, per PREREG §Batch expansion.

## 7. PR size bound adjustments

**Bounds retained at 100–2000 changed source lines**, but the measurement point is clarified:

- "Changed source lines" = additions + deletions as counted by `git diff --numstat`, on the diff from C_base to C_test, filtered by `:(exclude)**/*.test.{ts,tsx}` `:(exclude)docs/**` `:(exclude)schemas/**` `:(exclude)**/package-lock.json` `:(exclude)**/__snapshots__/**` `:(exclude)**/*.snap`.
- Applied at C_test, not at C_final. A PR whose scope shrank during review may have a C_base → C_final diff within bounds while its C_base → C_test diff is larger.

**Pilot observation**: PR 24489 had a C_base → C_test diff of 3099 source lines — above the registered 2000 cap. The PR was selected by its final-state add+del count (1268) which is within bounds; the C_test state had extra work that was subsequently narrowed during review. The PR stays in the pilot analysis (trail commitment: published alongside).

**For the test set**: candidates are filtered at selection time by their C_base → C_test source line count computed with the exclusion list above. PRs whose C_test state exceeds 2000 source lines are dropped even if the final PR is within bounds.

---

## Locked-as-of-today but flagged for v2 reconsideration

These aren't part of the 7 pilot decisions but are worth noting alongside them:

- **Blinding failure**: pilot revealed gemini correctly identified C_llm as LLM-generated in 5/5 trials. Blinding is fundamentally compromised on stylistic signatures. Accepted for this study with the caveat that reported P3 results are measured despite near-total blinding failure. V2 should explore style normalization or larger reviewer panels.
- **Parity null missing for P2** (retro R8): the 50% "past" threshold was registered as an improvement threshold without a parity baseline. Observed 20% is inside the plausible parity envelope but below parity's "past" lower bound. "Did P2 pass?" is ambiguous because we didn't register what parity looked like. V2 decision to register both.
