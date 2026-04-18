## Accepted Claims

### C1 — Name used AgentTool override parameters directly
**File**: packages/core/src/agents/agent-tool.ts:76
**Change**: In `AgentTool.createInvocation` and the `DelegateInvocation` constructor, rename `_toolName` and `_toolDisplayName` to `toolName` and `toolDisplayName`, and pass those names through to `BaseToolInvocation`.
**Goal link**: This clarifies the unified `invoke_agent` tool's delegated display-name path.
**Justification**: The parameters are not unused, so removing the underscore convention reduces misleading first-pass scaffolding without changing the invocation values or behavior.

### C2 — Share single-property schema probing in AgentTool
**File**: packages/core/src/agents/agent-tool.ts:106
**Change**: Add a private helper in `agent-tool.ts` that returns the sole property name from an object schema, when one exists, and use it from both `mapParams` and `DelegateInvocation.withUserHints` instead of repeating `isRecord(properties)` and `Object.keys(properties)` logic.
**Goal link**: This clarifies how the unified `invoke_agent` `prompt` argument is mapped onto an individual subagent's input schema.
**Justification**: The same schema-key decision currently appears in two blocks, and centralizing that one decision removes duplication while preserving the existing fallback to `prompt` or no hint injection.

### C3 — Inline policy virtual-call construction
**File**: packages/core/src/policy/policy-engine.ts:560
**Change**: Replace the separate `toolCallsToTry` array construction with a direct `.some((name) => ruleMatches(rule, { ...toolCall, name }, ...))` over `toolNamesToTry`.
**Goal link**: This clarifies the Policy Engine enhancement that treats `agent_name` as a virtual alias for `invoke_agent`.
**Justification**: The intermediate array only materializes cloned calls for one loop, so inlining the clone at the match site makes the alias matching path more direct without changing rule ordering or match semantics.

### C4 — Update the unified tool registration comment
**File**: packages/core/src/config/config.ts:3625
**Change**: Change the comment above `maybeRegister(AgentTool, ...)` from `Register Subagent Tool` to `Register unified agent invocation tool`.
**Goal link**: This aligns the main tool registry with the goal of replacing per-subagent tools with a single `invoke_agent` entry point.
**Justification**: The current comment preserves legacy terminology and makes the registration look like the old specialized subagent-tool path, while the code now registers the unified tool.

## Rejected

- Delete `packages/core/src/agents/subagent-tool.ts` as dead legacy code: the file is still imported by existing non-allowed test files, so deleting it without test changes would break the existing suite.
- Move `SubagentToolWrapper` or `SubagentTool` delegation code into `AgentTool`: `subagent-tool-wrapper.ts` is outside the allowed edit set, and folding that boundary into `agent-tool.ts` would be larger than a bounded refactor claim.
- Replace dynamic remote-agent policy rules in `AgentRegistry.addAgentPolicy` with `toolName: definition.name` virtual-alias rules: this could change matching precedence and behavior for policies that currently rely on `invoke_agent` plus `argsPattern`.
- Validate `AgentTool` arguments against each subagent schema before building a child invocation: that would be observable behavior, because the unified tool intentionally maps `{ agent_name, prompt }` onto agent-specific schemas instead of requiring callers to provide those schemas directly.
- Remove the browser-agent special case from `AgentTool.buildChildInvocation`: browser delegation uses `BrowserAgentInvocation` even though browser definitions can look remote, so removing the branch would change execution behavior.
- Add `invoke_agent` to `TOOL_LEGACY_ALIASES` for every subagent name: the aliases are static built-in tool renames, while subagent names are dynamic registry entries and cannot be represented safely in that map.
