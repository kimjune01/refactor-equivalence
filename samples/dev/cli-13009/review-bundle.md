# Blind merge-readiness review — cli/cli PR 13009

## PR metadata

**Title:** Use login-based assignee mutation on github.com

**Body:**

Fixes https://github.com/cli/cli/issues/13000

## Description

`gh pr create -a @me` fails with `could not assign user: 'xx' not found` when the user interactively adds metadata (reviewers, labels, etc.) during the PR creation flow, because the assignee login cannot be resolved to a node ID from the cached metadata that only contains the interactively selected fields. This has been broken since the actor assignee work shipped a few weeks ago.

While investigating, we found that all assignee flows on github.com were still going through an unnecessary bulk fetch and ID resolution step, even though the API already supports assigning by login directly. This PR fixes the original bug and migrates all assignee paths to use the login-based approach.
## To Fix

This PR migrates all github.com assignee flows to pass logins directly to the mutation, and wires up the multi-select with search UX. This experience avoids bulk fetching of IDs. GHES retains the legacy ID-based path unchanged.

### Before

| Path | Bulk fetch? | ID resolution? |
|------|------------|----------------|
| `gh pr create -a` | ❌ Yes | ❌ Yes |
| `gh pr create -a` + interactive metadata | ❌ Yes (does not work) | ❌ Yes (does not work) |
| `gh pr create` interactive assignees | ❌ Yes (static list) | ❌ Yes |
| `gh issue create -a` | ✅ No | ✅ No |
| `gh issue create` interactive assignees | ❌ Yes (static list) | ❌ Yes |
| `gh pr edit` interactive | ✅ No | ⚠️ Yes |
| `gh pr edit --add-assignee` | ❌ Yes | ❌ Yes |
| `gh issue edit` interactive | ❌ Yes (static list) | ❌ Yes |
| `gh issue edit --add-assignee` | ❌ Yes | ❌ Yes |

### After

| Path | Bulk fetch? | ID resolution? |
|------|------------|----------------|
| `gh pr create -a` | ✅ No | ✅ No |
| `gh pr create -a` + interactive metadata | ✅ No | ✅ No |
| `gh pr create` interactive assignees | ✅ No (search) | ✅ No |
| `gh issue create -a` | ✅ No | ✅ No |
| `gh issue create` interactive assignees | ✅ No (search) | ✅ No |
| `gh pr edit` interactive | ✅ No (search) | ✅ No |
| `gh pr edit --add-assignee` | ✅ No | ✅ No |
| `gh issue edit` interactive | ✅ No (search) | ✅ No |
| `gh issue edit --add-assignee` | ✅ No | ✅ No |

## Key Changes

- Fix the missing `state.ActorAssignees = true` in `pr create` that caused the original bug
- On github.com, assignee logins now go straight to the `replaceActorsForAssignable` mutation via its `actorLogins` field. No more fetching all assignable actors just to resolve a login to a node ID
- The `--add-assignee` and `--remove-assignee` flag paths for both `pr edit` and `issue edit` skip the bulk fetch entirely on github.com. A new `AssigneeLogins()` method computes the final set from logins directly
- All interactive assignee selection now uses `MultiSelectWithSearch` on github.com:
  - `pr create` and `issue create` via `MetadataSurvey` (new `assigneeSearchFunc` parameter, backed by new `SearchRepoAssignableActors` repo-level API)
  - `issue edit` wired up with `AssigneeSearchFunc` (previously missing, was using static list)
  - `pr edit` already had search, now simplified (actor accumulation hack removed)
- `AssigneeSearchFunc` extracted to shared location, `actorsToSearchResult` helper shared by both repo-level and node-level search functions
- Fixed a bug where `Editable.Clone()` was silently dropping `AssigneeSearchFunc` and `ReviewerSearchFunc`

## Reviewer Notes

- The `replaceActorsForAssignable` mutation has always accepted `actorLogins` alongside `actorIds` on github.com. We just never used it until now
- `AssigneeIds()` on `Editable` is now only called on GHES. On github.com, `AssigneeLogins()` is used instead
- `MetadataSurvey` now accepts an `assigneeSearchFunc` parameter alongside the existing `reviewerSearchFunc`
- Create flows use `SearchRepoAssignableActors` (repo-level, no issue/PR ID needed), edit flows use `SuggestedAssignableActors` (node-level)
- GHES flows are completely unchanged, they still use `RepositoryAssignableUsers` + `assigneeIds`

## Acceptance & Regression Testing

**16 scenarios tested** across github.com and GHES (3.20), all passing: [Acceptance test results](https://gist.github.com/BagToad/d472cc6dfeb3aa482494a72c894f08a8)

Covers `pr create`, `issue create`, `pr edit` (flags + interactive), `issue edit` (flags + interactive), multi-issue edit, remove-all-assignees, and zero-bulk-fetch verification on both hosts.

The full automated acceptance test suite (`go test -tags=acceptance ./acceptance`) was also run locally against github.com with all relevant tests passing.

## Task

Two candidate Go implementations. Phase 1: forced choice. Phase 2: trajectory after seeing C_final. Phase 3: blinding check.

## Phase 1
- Candidate A: `diff-A.patch`
- Candidate B: `diff-B.patch`

Assuming tests pass, which version to approve for merge? A or B. Rationale 1–2 sentences. Note semantic concerns.

## Phase 2
See `diff-C_final.patch`. Classify A and B as past/short/wrong relative to C_final.

## Phase 3
Did you identify any candidate as final/LLM/identifiable?

## Output JSON
{
  "phase_1_choice": "A" | "B",
  "phase_1_rationale": "...",
  "phase_1_semantic_concerns": { "A": "..." or null, "B": "..." or null },
  "phase_2_trajectory_A": "past" | "short" | "wrong",
  "phase_2_trajectory_B": "past" | "short" | "wrong",
  "phase_3_blinding": {
    "believed_a_final": bool, "believed_b_final": bool,
    "believed_a_llm": bool, "believed_b_llm": bool,
    "identifying_signals": "..." or null
  }
}
