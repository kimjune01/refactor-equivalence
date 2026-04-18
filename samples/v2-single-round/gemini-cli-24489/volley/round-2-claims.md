## Accepted Claims

### C1 — Centralize Agent Input Key Selection
**File**: packages/core/src/agents/agent-tool.ts:106
**Change**: In `AgentTool`, extract the repeated input-schema property inspection from `mapParams` and `DelegateInvocation.withUserHints` into a shared private helper that returns the target input key while preserving current fallbacks: a single object-schema `properties` entry maps to that property, any object-schema `properties` record with zero or multiple entries falls back to `prompt`, and schemas where `properties` is absent or not an object keep the existing no-remap/no-hints behavior.
**Goal link**: This clarifies the unified `invoke_agent` adapter's responsibility for translating its generic `prompt` argument into each subagent's schema.
**Justification**: Reusing one key-selection rule removes duplicated schema probing in the new delegation path without changing the mapped arguments or hint-injection conditions.
**Hunt note**: Retained as narrowed for F1 because it now explicitly classifies `properties: {}` with the same `prompt` fallback as multi-property object schemas.

### C2 — Reuse Hinted Child Invocation Construction
**File**: packages/core/src/agents/agent-tool.ts:180
**Change**: In `DelegateInvocation`, add a private method that applies `withUserHints(this.mappedInputs)` and calls `buildChildInvocation`, then use it from both `shouldConfirmExecute` and `execute`.
**Goal link**: This keeps the unified `invoke_agent` execution path focused on delegation instead of repeating setup mechanics at each lifecycle entry point.
**Justification**: The confirmation and execution paths currently duplicate the same hinted-argument construction, and a local helper removes that accidental repetition while preserving the same child invocation type and inputs.

## Rejected

- Delete `packages/core/src/agents/subagent-tool.ts` now that `invoke_agent` is the unified entry point: this would break existing tests and any internal imports that still exercise the legacy per-agent tool class, so it is not test-preserving within the allowed non-test edit scope.
- Change `packages/core/src/prompts/snippets.ts` and `packages/core/src/prompts/snippets.legacy.ts` memory guidance to use `formatToolName(AGENT_TOOL_NAME)`: this would alter prompt snapshots and require test fixture updates, which are outside the allowed claim scope.
- Escape `definition.name` before building the dynamic remote-agent `argsPattern` in `packages/core/src/agents/registry.ts`: this would be a behavioral fix for regex metacharacters in agent names rather than a behavior-preserving refactor.
- Replace all string literals for `agent_name` with a new exported constant across agent, policy, prompt, and TOML files: this crosses several surfaces for a single parameter name and adds indirection where the current literal is part of user-visible tool schema and documentation.
- Refactor `PolicyEngine.check` virtual alias matching into a separate helper: the current alias block is short and local to one call site, so extracting it would add an abstraction without reducing meaningful complexity.
