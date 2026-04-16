# Volley round 1 — sharpened claims

## Claim 1 — Use the public tool-name barrel for complete_task constants
In `packages/core/src/agents/local-executor.ts:76-77`, import `COMPLETE_TASK_TOOL_NAME` from `../tools/tool-names.js` instead of `../tools/definitions/base-declarations.js`, keeping the `CompleteTaskTool` import unchanged.

Before:
```ts
import { CompleteTaskTool } from '../tools/complete-task.js';
import { COMPLETE_TASK_TOOL_NAME } from '../tools/definitions/base-declarations.js';
```

After:
```ts
import { CompleteTaskTool } from '../tools/complete-task.js';
import { COMPLETE_TASK_TOOL_NAME } from '../tools/tool-names.js';
```

Why: This matches the surrounding tool imports that consume stable tool identity constants through `tool-names.ts` instead of reaching into the lower-level definitions module.

## Claim 2 — Remove redundant missing-argument validation after JSON-schema validation
In `packages/core/src/tools/complete-task.ts:80-105`, simplify `CompleteTaskTool.validateToolParamValues` so it relies on `BaseDeclarativeTool.validateToolParams`/`SchemaValidator` for required-property and type checks, retaining only the zod `safeParse` check for structured output and the whitespace-only check for the default `result` string.

Before:
```ts
if (this.outputConfig) {
  const outputName = this.outputConfig.outputName;
  if (params[outputName] === undefined) {
    return `Missing required argument '${outputName}' for completion.`;
  }
  const validationResult = this.outputConfig.schema.safeParse(params[outputName]);
  ...
} else {
  const resultArg = params['result'];
  if (
    resultArg === undefined ||
    resultArg === null ||
    (typeof resultArg === 'string' && resultArg.trim() === '')
  ) {
    return 'Missing required "result" argument...';
  }
}
```

After:
```ts
if (this.outputConfig) {
  const outputName = this.outputConfig.outputName;
  const validationResult = this.outputConfig.schema.safeParse(params[outputName]);
  ...
} else if (
  typeof params['result'] === 'string' &&
  params['result'].trim() === ''
) {
  return 'Missing required "result" argument...';
}
```

Why: The custom missing/null branches duplicate schema validation that has already run, so removing them leaves one validation layer responsible for basic shape and keeps this method focused on extra semantic checks.

## Claim 3 — Centralize the default result parameter name inside CompleteTaskTool
In `packages/core/src/tools/complete-task.ts:22`, add a private module constant such as `const RESULT_PARAM = 'result';`, then replace the repeated literal at `packages/core/src/tools/complete-task.ts:69`, `packages/core/src/tools/complete-task.ts:76`, `packages/core/src/tools/complete-task.ts:96`, and `packages/core/src/tools/complete-task.ts:159` with `RESULT_PARAM`; keep user-facing error text unchanged.

Before:
```ts
properties: {
  result: { ... },
},
required: ['result'],
...
const resultArg = params['result'];
...
outputValue = this.params['result'];
```

After:
```ts
const RESULT_PARAM = 'result';
...
properties: {
  [RESULT_PARAM]: { ... },
},
required: [RESULT_PARAM],
...
const resultArg = params[RESULT_PARAM];
...
outputValue = this.params[RESULT_PARAM];
```

Why: The new tool repeats its fallback parameter name across schema, validation, and execution; a local constant removes that duplication without changing the public API.

## Claim 4 — Share output serialization in CompleteTaskInvocation.execute
In `packages/core/src/tools/complete-task.ts:125-179`, add a small private module helper near the invocation class, for example `function formatSubmittedOutput(output: unknown): string { return typeof output === 'string' ? output : JSON.stringify(output, null, 2); }`, and use it in `CompleteTaskInvocation.execute` at `packages/core/src/tools/complete-task.ts:153-156` and `packages/core/src/tools/complete-task.ts:160-163`.

Before:
```ts
submittedOutput =
  typeof outputValue === 'string'
    ? outputValue
    : JSON.stringify(outputValue, null, 2);
...
submittedOutput =
  typeof outputValue === 'string'
    ? outputValue
    : JSON.stringify(outputValue, null, 2);
```

After:
```ts
submittedOutput = formatSubmittedOutput(outputValue);
...
submittedOutput = formatSubmittedOutput(outputValue);
```

Why: This removes duplicated string-or-JSON formatting logic from the two output paths while keeping the same result strings.

## Claim 5 — Replace the unused catch binding in JSON-string argument parsing
In `packages/core/src/agents/local-executor.ts:1051-1061`, change `catch (_)` to `catch` in the `functionCall.args` JSON parse block.

Before:
```ts
} catch (_) {
  debugLogger.warn(...);
}
```

After:
```ts
} catch {
  debugLogger.warn(...);
}
```

Why: The caught value is never used, so omitting the binding removes unnecessary local state from the newly added parsing branch.

## Claim 6 — Use the complete_task constant in its own validation error text
In `packages/core/src/tools/complete-task.ts:102`, replace the hardcoded `complete_task` substring in the default-result validation error with `${COMPLETE_TASK_TOOL_NAME}` while preserving the exact rendered message.

Before:
```ts
return 'Missing required "result" argument. You must provide your findings when calling complete_task.';
```

After:
```ts
return `Missing required "result" argument. You must provide your findings when calling ${COMPLETE_TASK_TOOL_NAME}.`;
```

Why: The tool name is already imported as a constant, and using it here avoids a second source of truth for the same identifier.

## Rejected
- Re-introduce inline `complete_task` handling in `LocalAgentExecutor.processFunctionCalls`: this would undo the main extraction and restore the large branch that the diff intentionally moved into a tool class.
- Move `agentToolRegistry.registerTool(new CompleteTaskTool(...))` before `agentToolRegistry.sortTools()` in `LocalAgentExecutor.create`: this could change tool declaration ordering, especially relative to discovered and MCP tools, so it is not a behavior-preserving refactor.
- Remove the `complete_task` allow rule from `packages/core/src/policy/policies/read-only.toml`: policy decisions are observable behavior, and read-only mode must still permit the lifecycle tool.
- Remove the JSON-string `functionCall.args` parsing block from `LocalAgentExecutor.processFunctionCalls`: the diff explicitly adds support for stringified arguments, so deleting it would remove feature behavior.
- Extract the JSON-string argument parsing block into a new helper: the block is currently used once, and adding a helper would add indirection contrary to the spec's direction to inline one-off helpers.
- Export `CompleteTaskInvocation` through a barrel or add new public type aliases for completion result data: this expands public surface area and is not required for the refactor.
- Remove the existing `export` from `CompleteTaskInvocation`: even if the class appears unused outside tests today, removing a newly exported symbol is a public API change risk.
- Touch `packages/core/src/tools/complete-task.test.ts` or `packages/core/src/agents/local-executor.test.ts`: tests are explicitly outside the allowed edit target for implementation, and the task says not to add new tests.
