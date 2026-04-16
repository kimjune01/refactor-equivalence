# Blind merge-readiness review — cli/cli PR 12696

## PR metadata (reviewer sees)

**Title:** Add `--query` flag to `project item-list`

**Body:**

## Description

Fixes https://github.com/cli/cli/issues/12664

### Acceptance Criteria

**Given** I am targeting github.com
**When** I run `project item-list` with the `--query` flag
**Then** the query is respected in the results

```
➜ ./bin/gh project item-list 9 --owner williammartin --format json --query "assignee:williammartin-cli-triaging"
{
  "items": [
    {
      "assignees": [
        "williammartin-cli-triaging"
      ],
      "content": {
        "body": "test",
        "number": 25,
        "repository": "williammartin-test-org/test-repo",
        "title": "test title",
        "type": "Issue",
        "url": "https://github.com/williammartin-test-org/test-repo/issues/25"
      },
      "id": "PVTI_lAHOABiW9s4A1ms7zgY4CN4",
      "repository": "https://github.com/williammartin-test-org/test-repo",
      "title": "test title"
    }
  ],
  "totalCount": 1
}

➜  ./bin/gh project item-list 9 --owner williammartin --format json --query "assignee:babakks"
{
  "items": [],
  "totalCount": 0
}
```

**Given** I am targeting a version of GHES that doesn't support the query flag
**When** I run `project item-list` with the `--query` flag
**Then** I receive an informative error

```
➜ ✗ GH_HOST=ghe.io ./bin/gh project item-list 9 --owner williammartin --format json --query "assignee:babakks"
the `--query` flag is not supported on this GitHub host; most likely you are targeting a version of GHES that does not yet have the query field available
```

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
