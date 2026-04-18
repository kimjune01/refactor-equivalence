## Accepted Claims

### C1 — Use Virtual Subagent Tool Names In Plan Policy
**File**: packages/core/src/policy/policies/plan.toml:108
**Change**: In the "Allow specific subagents in Plan mode" rule, replace `toolName = "invoke_agent"` plus the `argsPattern` regex with `toolName = ["codebase_investigator", "cli_help"]`, and update the adjacent comment to say the rule relies on `invoke_agent` virtual alias matching.
**Goal link**: This clarifies the Policy Engine enhancement that treats `agent_name` as a virtual tool alias for subagents.
**Justification**: Expressing the allowlist as subagent tool names removes duplicated JSON-argument regex matching and makes the policy depend directly on the alias mechanism introduced for unified `invoke_agent`.

### C2 — Use Virtual Subagent Tool Names For Dynamic Remote Agent Policy
**File**: packages/core/src/agents/registry.ts:394
**Change**: In `AgentRegistry.addAgentPolicy`, change the remote-agent dynamic rule from `toolName: AgentTool.Name` with an `argsPattern` matching `"agent_name"` to `toolName: definition.name`, and remove the now-unused `argsPattern` construction and `AgentTool` import if no longer referenced in the file.
**Goal link**: This clarifies that remote-agent confirmation policy is also mediated through the same virtual tool alias path used for existing subagent policies.
**Justification**: Using the agent name as the policy key removes a second, registry-local way of parsing `invoke_agent` arguments and keeps policy matching centralized in `PolicyEngine`.

## Rejected

- Delete `packages/core/src/agents/subagent-tool.ts`: although the production registration path no longer uses per-agent tools, existing tests import and exercise `SubagentTool`, so deleting it would break the current suite unless test files were also changed.
- Refactor `AgentTool.DelegateInvocation.buildChildInvocation` to instantiate `SubagentToolWrapper` directly: this would require coordinating the wrapper's browser-agent branch and would currently conflict with `agent-tool.test.ts` expectations for a browser definition shaped as a remote agent.
- Rename `DelegateInvocation` in `packages/core/src/agents/agent-tool.ts`: this is behavior-preserving, but the private class name is not user-visible and the rename would be a cosmetic cleanup rather than a clearer expression of the unified invocation goal.
- Change prompt snippets to add explicit instructions about passing the task text in `prompt`: this would alter model-visible behavior and prompt snapshot expectations, so it is not a bounded behavior-preserving refactor claim.
- Update `docs/core/subagents.md` or `docs/reference/policy-engine.md`: documentation changes may be relevant to the PR goal, but those files are not in `allowed-files.txt`.
- Clean up unrelated eval and workflow changes from the artifact: those files are in the broad allowed set, but they are outside the stated goal of unified subagent invocation and policy aliasing.
