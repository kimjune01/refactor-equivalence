# PR #24489 — feat(core): refactor subagent tool to unified invoke_subagent tool

## PR body

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


## Linked issues

(none)
