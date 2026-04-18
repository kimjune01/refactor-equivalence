## Accepted Claims

### C1 — Name AgentTool override parameters directly
**File**: packages/core/src/agents/agent-tool.ts:77
**Change**: In `AgentTool.createInvocation` and the `DelegateInvocation` constructor, rename `_toolName` and `_toolDisplayName` to `toolName` and `toolDisplayName`, and pass those renamed parameters through unchanged to `BaseToolInvocation`.
**Goal link**: This clarifies the unified `invoke_agent` tool's delegated display-name path.
**Justification**: These parameters are used to preserve the unified tool identity, so removing the unused-parameter convention reduces misleading first-pass scaffolding without changing values or behavior.

### C2 — Share schema property-name extraction in AgentTool
**File**: packages/core/src/agents/agent-tool.ts:96
**Change**: Add a private helper in `agent-tool.ts` that returns the sole property name only when an input schema has a record-valued `properties` object with exactly one key, and use it from both `AgentTool.mapParams` and `DelegateInvocation.withUserHints`; keep each caller's current fallback behavior, with `mapParams` falling back to `{ prompt }` and `withUserHints` returning the original args unless it can append to a string-valued primary key.
**Goal link**: This clarifies how the unified `invoke_agent` `prompt` argument is mapped onto an individual subagent's input schema.
**Justification**: The same schema inspection logic appears in two blocks, and centralizing only that extraction removes duplication while preserving the existing mapping and hint-injection semantics.

### C3 — Inline policy virtual-call construction
**File**: packages/core/src/policy/policy-engine.ts:560
**Change**: Replace the separate `toolCallsToTry` array construction with a direct `toolNamesToTry.some((name) => ruleMatches(rule, { ...toolCall, name }, ...))` at the rule-match site.
**Goal link**: This clarifies the Policy Engine enhancement that treats `agent_name` as a virtual alias for `invoke_agent`.
**Justification**: The intermediate array only materializes cloned calls for one loop, so inlining the clone where matching occurs makes the alias path more direct without changing rule ordering or match results.

### C4 — Update the unified tool registration comment
**File**: packages/core/src/config/config.ts:3625
**Change**: Change the comment above `maybeRegister(AgentTool, ...)` from `Register Subagent Tool` to `Register unified agent invocation tool`.
**Goal link**: This aligns the main tool registry with the goal of replacing per-subagent tools with a single `invoke_agent` entry point.
**Justification**: The current comment preserves legacy terminology and makes the registration look like the old specialized subagent-tool path, while the code now registers the unified tool.

## Rejected

- Delete `packages/core/src/agents/subagent-tool.ts` as dead legacy code: the file is still imported by existing non-allowed test files and may remain part of the internal direct-subagent invocation surface, so deleting it would not be a bounded behavior-preserving refactor.
- Move `AgentTool.buildChildInvocation` onto `SubagentToolWrapper`: `packages/core/src/agents/subagent-tool-wrapper.ts` is outside the allowed edit set, and the wrapper's `build()` path would also change the browser-agent override name/display behavior unless it grew a new API.
- Replace dynamic remote-agent policy rules in `AgentRegistry.addAgentPolicy` with `toolName: definition.name` virtual-alias rules: although this would express the new alias model more directly, it could change matching for direct agent-named tool calls or precedence around `invoke_agent` plus `argsPattern` rules.
- Apply `invoke_agent` virtual aliases to safety checker matching as well as policy-rule matching: this would broaden when safety checkers run and is therefore an observable policy behavior change, not a pure refactor.
- Rename the `promptProvider` section key from `agentContexts` to `subAgents`: the existing key may be part of user-facing prompt-section configuration, so changing it could alter which prompt sections are enabled or disabled.
- Remove the browser-agent special case from `AgentTool.buildChildInvocation`: browser delegation intentionally constructs `BrowserAgentInvocation`, so removing the branch would change execution behavior.
