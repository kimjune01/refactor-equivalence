# Blind merge-readiness review — cli/cli PR 12526

## PR metadata

**Title:** `gh pr edit`: new interactive prompt for assignee selection, performance and accessibility improvements

**Body:**

## Description

Implements multiselect with search for `gh pr edit` assignees, addressing performance and accessibility issues in large organizations. Part of larger work to improve the reviewer and assignee experience in `gh`.

## Key changes

- **New `MultiSelectWithSearch` prompter**: Adds a search sentinel option to multiselect lists, allowing dynamic fetching of assignees via API search rather than loading all org members upfront
- **`SuggestedAssignableActors` API**: New GraphQL query to fetch suggested actors for an assignable (Issue/PR) node with optional search filtering
- **`gh pr edit` assignee flow**: Wires up the new prompter for interactive assignee selection when `ActorIsAssignable` feature is detected
- **Prompter interface expansion**: Both `surveyPrompter` and `accessiblePrompter` implement the new method, with full test coverage
- **Preview command**: Adds `multi-select-with-search` to `gh preview prompter` for testing

## Notes for reviewers

- This PR only covers assignees for `gh pr edit`; reviewers will follow in a subsequent PR

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
