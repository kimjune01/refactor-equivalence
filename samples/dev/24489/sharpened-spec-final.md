# Final Sharpened Refactor Claims

## Accepted Claims

1. **`packages/core/src/agents/agent-tool.ts` - `AgentTool.mapParams` and `DelegateInvocation.withUserHints`: extract only the repeated one-property input-schema key selection into one private helper in the same file, while preserving each caller's existing fallback behavior.**  
   Test claim: behavior remains unchanged because both callers still use the single schema property name when `inputSchema.properties` is a record with exactly one key; `AgentTool.mapParams` must still fall back to `{ prompt }` when the schema is not a record, lacks record `properties`, or does not have exactly one property, while `DelegateInvocation.withUserHints` must still return the original args without appending user hints when `inputSchema.properties` is not a record. The full suite should still pass with `npm run build --workspace @google/gemini-cli-core` followed by `cd packages/core && npx vitest run --exclude '**/sandboxManager.integration.test.ts'`.  
   Justification: it removes duplicated schema-shape branching introduced by the unified `invoke_agent` tool and keeps the shared one-property mapping rule in one place without broadening hint injection.

2. **`packages/core/src/agents/agent-tool.ts` - `DelegateInvocation.buildChildInvocation`: replace the final `else` branch after the remote-agent return with a direct local-agent return.**  
   Test claim: the browser, remote, and local dispatch order is unchanged because the browser and remote branches already return before the local fallback; the full suite should still pass.  
   Justification: it flattens control flow in the new invocation dispatcher without changing which child invocation class is selected.

3. **`packages/core/src/agents/agent-tool.ts` - `DelegateInvocation.shouldConfirmExecute` and `DelegateInvocation.execute`: move the repeated `withUserHints(this.mappedInputs)` plus `buildChildInvocation(...)` sequence into a private `buildHintedChildInvocation()` helper.**  
   Test claim: confirmation and execution still build the same child invocation from the same hinted arguments, so scheduler and subagent tests should continue to pass.  
   Justification: it removes duplicated setup in the two lifecycle methods that must stay behaviorally aligned.

4. **`packages/core/src/agents/local-executor.ts` - `parseToolArguments`: rewrite the function to return parsed arguments directly from each branch instead of mutating a local `args` object with `Object.assign`, preserving the existing handling for all JSON parse outcomes.**  
   Test claim: string JSON object arguments, invalid JSON strings, object arguments, missing arguments, and valid JSON strings that parse to arrays, primitives, or `null` produce the same `{ args, error? }` outcomes; in particular, valid non-object JSON string values must continue returning `{ args: {} }` with no error rather than being returned as args or treated as invalid. Local-executor and agent tests should continue to pass.  
   Justification: it makes the new JSON-string parsing path easier to read by eliminating mutable accumulation that is not needed.

5. **`packages/core/src/agents/registry.ts` - `addAgentPolicy`: return early when `definition.kind !== 'remote'` before checking for policy-engine rules.**  
   Test claim: local agents still get no dynamic policy rule and remote agents still respect user-defined policy rules before adding the dynamic `invoke_agent` ask-user rule; policy and registry tests should continue to pass.  
   Justification: it removes irrelevant policy checks for local agents after the refactor changed local agents to be covered by the blanket `invoke_agent` allow rule.

6. **`packages/core/src/policy/policy-engine.ts` - `PolicyEngine.check`: collapse the nested `toolCall.name === AGENT_TOOL_NAME`, `isRecord(toolCall.args)`, and `typeof subagentName === 'string'` checks into a single local `subagentName` extraction block.**  
   Test claim: virtual alias matching still appends only string `agent_name` values for `invoke_agent` calls, so existing policy decisions should not change.  
   Justification: it reduces indentation in the new agent-tool alias logic while preserving the same guard conditions.

7. **`evals/automated-tool-use.eval.ts` - both assertions: extract the duplicated shell-command argument parsing into one local `getCommand(call)` helper.**  
   Test claim: both eval assertions still inspect the same `run_shell_command` arguments for `eslint --fix` and `prettier --write`; eval behavior is unchanged.  
   Justification: it removes copy-pasted JSON/string argument handling introduced around the eval cleanup.

8. **`evals/frugalSearch.eval.ts` - "should use grep or ranged read for large files" assertion: reuse the file-level `getGrepParams` helper instead of defining a second identical `getParams` helper inside the assertion.**  
   Test claim: the assertion still parses each tool call's args the same way before checking full reads and valid attempts.  
   Justification: it eliminates a local duplicate that obscures the eval's actual behavioral checks.

9. **`packages/core/src/services/sandboxManager.ts` - `resolveSandboxPaths`: inline the one-use `filteredAllowed` variable into the returned `allowed` property.**  
   Test claim: the same sanitized allowed paths are filtered against workspace and forbidden identities before returning, so sandbox-manager tests should continue to pass.  
   Justification: it removes a temporary name that no longer carries extra meaning after the function was simplified to return only `allowed` and `forbidden`.

10. **`packages/core/src/telemetry/trace.ts` - `runInDevTraceSpan`: remove `restOfSpanOpts` and pass the remaining span options directly through a clearer destructuring name such as `spanOptions`.**  
    Test claim: the same `SpanOptions` object is passed to `tracer.startActiveSpan`, and the shared `sessionId` attribute remains set inside metadata, so telemetry behavior is unchanged.  
    Justification: it clarifies the new API after `sessionId` was removed from every call site.

## Rejected

1. **Refactor `packages/core/src/tools/complete-task.ts` to simplify `CompleteTaskInvocation.execute`.**  
   Rejected because `packages/core/src/tools/complete-task.ts` is not listed in `FORGE_ALLOWED_FILES.txt`, even though the spec summary mentions complete-task handling.

2. **Move `COMPLETE_TASK_TOOL_NAME` and `COMPLETE_TASK_DISPLAY_NAME` between `base-declarations.ts`, `coreTools.ts`, and `tool-names.ts`.**  
   Rejected because `packages/core/src/tools/definitions/base-declarations.ts` and `packages/core/src/tools/definitions/coreTools.ts` are outside the allowed edit set, and changing exported constants risks public API churn.

3. **Rename `AgentTool` params from `{ agent_name, prompt }` to camelCase internally and remap at the boundary.**  
   Rejected because the snake_case names are part of the model-facing schema and policy `argsPattern` matching, so the cleanup is not behavior-neutral.

4. **Replace `AgentTool`'s repeated inline parameter type with a new exported interface.**  
   Rejected because it adds type surface for a small local duplication, and the refactor spec explicitly discourages new interfaces or abstractions unless clearly necessary.

5. **Trim the returned description in `packages/core/src/tools/shell.ts` by returning `this.params.description.trim()` instead of `this.params.description`.**  
   Rejected because it changes user-visible text when descriptions contain leading or trailing whitespace, so it is not a pure refactor claim.

6. **Restore a separate `component-test-helper.ts` abstraction for backend component evals.**  
   Rejected because the diff deleted that file and no current non-test eval imports it; recreating it would add dead code rather than reducing complexity.

7. **Edit any `*.test.ts`, `*.test.tsx`, or snapshot file included in `FORGE_ALLOWED_FILES.txt`.**  
   Rejected because the task explicitly forbids touching test files, even when they appear in the allowed file list.
