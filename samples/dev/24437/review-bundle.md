# Blind merge-readiness review — PR 24437

## PR metadata (reviewer sees)

**Title:** fix(core): ensure complete_task tool calls are recorded in chat history

**Body:**

## Summary

This PR refactors the `complete_task` tool from a special-case internal handler in `LocalAgentExecutor` into a first-class `BaseDeclarativeTool`. This change ensures that `complete_task` tool calls are properly scheduled and recorded in the chat history, addressing an issue where the final step of a subagent session was missing from persistent recordings.

## Details

- Created `CompleteTaskTool` and `CompleteTaskInvocation` to handle task completion and output submission.
- Updated `LocalAgentExecutor` to register and use the new tool.
- Removed custom logic for `complete_task` in `processFunctionCalls` and `executeTurn`.
- Added unit tests for `CompleteTaskTool`.
- Updated `LocalAgentExecutor` tests to reflect the new architecture.
- Explicitly allowed `complete_task` in the `read-only.toml` policy.

## Related Issues

Refers to a reviewer feedback from a previous PR.

## How to Validate

1. Run unit tests for `CompleteTaskTool`: `npm test packages/core/src/tools/complete-task.test.ts`
2. Run unit tests for `LocalAgentExecutor`: `npm test packages/core/src/agents/local-executor.test.ts`
3. Verify that `complete_task` tool calls are now present in session recordings when running subagents.

## Pre-Merge Checklist

- [ ] Updated relevant documentation and README (if needed)
- [x] Added/updated tests (if needed)
- [ ] Noted breaking changes (if any)
- [x] Validated on required platforms/methods:
  - [x] MacOS
    - [x] npm run

## Task description

Two candidate implementations of the PR's stated purpose are available as diffs from the same base commit. You will evaluate them in two phases. You may not see the original PR discussion, the version reviewers actually accepted, or which version was produced by an LLM.

Assume the test suite passes on both candidates. Your judgment is about merge-readiness on code quality and maintainability, not about correctness.

## Phase 1 — Forced choice

Read both diffs:

- **Candidate A**: `diff-A.patch`
- **Candidate B**: `diff-B.patch`

**Question:** Assuming tests pass, which version would you approve for merge?

Answer: A or B.

Record your rationale in 1–2 sentences. If either version raises a semantic concern (behavior change not visible in the diff, likely regression, dangerous pattern), note it.

## Phase 2 — Trajectory classification

After Phase 1, you are shown a third diff: `diff-C_final.patch`. This is the version reviewers accepted on the merged PR.

Classify Candidate A and Candidate B relative to C_final, into one of three classes each:

- **Past C_final** — simpler than C_final and you would still approve it (simpler + no new correctness or clarity concerns)
- **Short of C_final** — improved over C_test but leaves complexity that C_final removed
- **Wrong direction** — no meaningful improvement, or worse than C_test

## Phase 3 — Blinding check

After Phases 1 and 2, answer:

- Did you believe any candidate was the final version?
- Did you believe any candidate was LLM-generated?
- Did any style, polish, or diff shape let you identify which candidate was which?

## Output format

Return a single JSON object with these fields:

```json
{
  "phase_1_choice": "A" | "B",
  "phase_1_rationale": "<1-2 sentences>",
  "phase_1_semantic_concerns": {
    "A": "<concern or null>",
    "B": "<concern or null>"
  },
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
