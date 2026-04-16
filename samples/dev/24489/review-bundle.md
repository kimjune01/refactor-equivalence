# Blind merge-readiness review — PR 24489

## PR metadata (reviewer sees)

**Title:** feat(core): refactor subagent tool to unified invoke_subagent tool

**Body:**

## Summary

Refactors specialized subagent tools into a single, unified `invoke_agent` tool and updates the Policy Engine to support virtual tool aliases for subagents.

## Details

- **Unified Tooling**: Introduced `invoke_agent` in `packages/core` as the standard mechanism for subagent delegation, replacing the previous 1:1 tool-to-agent mapping.
- **Policy Engine Enhancement**: Updated `PolicyEngine` to automatically treat the `agent_name` argument of `invoke_agent` as a virtual tool name. This ensures that existing safety policies (e.g., denying `codebase_investigator`) remain functional without requiring rule updates.
- **Prompt Refactoring**: Updated both modern and legacy prompt snippets to instruct the model to use `invoke_agent`.
- **Testing**: Added unit tests in `policy-engine.test.ts` for virtual alias matching and updated `subagents.eval.ts` to verify successful delegation via the new unified tool.
- **Documentation**: Updated `subagents.md` and `policy-engine.md` to reflect the new invocation pattern and policy syntax.

## Related Issues

Related to the effort of simplifying the main agent's toolset and improving context efficiency.

## How to Validate

1. **Unit Tests**: Run `npm test -w @google/gemini-cli-core` to verify Policy Engine and prompt rendering logic.
2. **Evals**: Run `npm run test:evals -- subagents.eval.ts` to ensure the model correctly uses the unified tool for delegation.
3. **Policy Verification**:
   - Create a local policy denying a specific subagent (e.g., `codebase_investigator`).
   - Verify that calling `invoke_agent` with that `agent_name` results in a `DENY` decision.

## Pre-Merge Checklist

- [x] Updated relevant documentation and README (if needed)
- [x] Added/updated tests (if needed)
- [x] Noted breaking changes (if any)
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
