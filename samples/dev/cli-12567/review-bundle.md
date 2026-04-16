# Blind merge-readiness review — cli/cli PR 12567

## PR metadata (reviewer sees)

**Title:** `gh pr edit`: Add support for Copilot as reviewer with search capability, performance and accessibility improvements

**Body:**

## Description

Adds Copilot Code Review (CCR) support and multiselect-with-search for reviewers in `gh pr edit`.

## Key changes

**API layer (`api/queries_pr.go`):**
- New `RequestReviewsByLogin` GraphQL mutation with `userLogins`, `botLogins`, `teamSlugs` (github.com only)
- New `SuggestedReviewerActors` query combining `suggestedReviewerActors`, collaborators, and org teams
- `ReviewerCandidate` interface with `ReviewerUser`, `ReviewerBot`, `ReviewerTeam` types
- `DisplayName()`/`DisplayNames()` methods for user-friendly display (e.g., "Copilot (AI)")
- Team slug extraction (`org/slug` → `slug`) moved into REST functions

**Query builder (`api/query_builder.go`):**
- Added `...on Bot{login}` to `prReviewRequests` for Copilot support (silently ignored on GHES)

**Edit command (`pkg/cmd/pr/edit/edit.go`):**
- `reviewerSearchFunc` for multiselect-with-search
- Split updates: `updatePullRequestReviewsGraphQL` (github.com) vs `updatePullRequestReviewsREST` (GHES)
- `partitionReviewersByType` to separate users, bots, teams
- `@copilot` flag support for `--add-reviewer`/`--remove-reviewer`

**Shared (`pkg/cmd/pr/shared/`):**
- `EditableReviewers` struct with separate `Default` (display) and `DefaultLogins` (API)
- `NewCopilotReviewerReplacer` for `@copilot` → `copilot-pull-request-reviewer`

## Notes for reviewers

- GHES compatibility: Bot fragment silently ignored; falls back to REST for mutations
- `requestReviewsByLogin` uses `union: false` (replace mode) to set the entire reviewer set
- Copilot bot logins get `[bot]` suffix in API layer before mutation

## Task description

Two candidate Go implementations of the PR's stated purpose are available as diffs from the same base commit. You will evaluate them in two phases. You may not see the original PR discussion, the version reviewers actually accepted, or which version was produced by an LLM.

Assume the test suite passes on both candidates. Your judgment is about merge-readiness on code quality and maintainability, not about correctness.

## Phase 1 — Forced choice

- **Candidate A**: `diff-A.patch`
- **Candidate B**: `diff-B.patch`

**Question:** Assuming tests pass, which version would you approve for merge?

Answer: A or B. Rationale 1–2 sentences. Note semantic concerns per candidate.

## Phase 2 — Trajectory classification

See C_final diff at `diff-C_final.patch` — the version reviewers accepted.

Classify Candidate A and Candidate B each as: past / short / wrong relative to C_final.

## Phase 3 — Blinding check

Did you believe any candidate was final/LLM-generated? Identifying signals?

## Output format

Write JSON:
```json
{
  "phase_1_choice": "A" | "B",
  "phase_1_rationale": "<1-2 sentences>",
  "phase_1_semantic_concerns": { "A": "<concern or null>", "B": "<concern or null>" },
  "phase_2_trajectory_A": "past" | "short" | "wrong",
  "phase_2_trajectory_B": "past" | "short" | "wrong",
  "phase_3_blinding": {
    "believed_a_final": true | false,
    "believed_b_final": true | false,
    "believed_a_llm": true | false,
    "believed_b_llm": true | false,
    "identifying_signals": "<sentence or null>"
  }
}
```
