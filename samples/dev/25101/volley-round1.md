# Volley round 1: sharpened refactor claims

## Accepted claims, ordered by confidence

1. In `packages/core/src/tools/write-file.ts`, change `WriteFileToolInvocation.execute` parameter destructuring from `{ abortSignal: abortSignal }` to `{ abortSignal }`.
   - Testable claim: behavior is unchanged because the same `AbortSignal` value is bound to the same local name and the full suite still passes.
   - Justification: removes a redundant alias introduced during the options-bag migration.

2. In `packages/core/src/tools/complete-task.ts`, change `CompleteTaskInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
   - Testable claim: behavior is unchanged because `abortSignal` is currently unused in this invocation and the full suite still passes.
   - Justification: avoids binding a fake local solely to satisfy the interface.

3. In `packages/core/src/tools/complete-task.ts`, simplify `CompleteTaskInvocation.execute` by computing `outputValue` once from either `this.outputConfig.outputName` or `'result'`, then computing `submittedOutput` once with the existing `processOutput` special case.
   - Testable claim: return shape, `llmContent`, `returnDisplay`, `data.taskCompleted`, and string-vs-JSON formatting are unchanged, and the full suite still passes.
   - Justification: removes duplicated string/JSON formatting branches and the mutable `submittedOutput`/`outputValue` setup.

4. In `packages/core/src/tools/complete-task.ts`, flatten `CompleteTaskTool.validateToolParamValues` by returning early for the no-`outputConfig` case before handling schema validation.
   - Testable claim: the same missing-result and Zod-validation errors are returned for the same inputs, and the full suite still passes.
   - Justification: reduces the nested `if/else` structure around two mutually exclusive validation modes.

5. In `packages/core/src/tools/complete-task.ts`, invert `CompleteTaskTool.buildParameterSchema` so the default `{ result: string }` schema returns immediately when `outputConfig` is absent, then handle the structured-output schema without an outer `if`.
   - Testable claim: the generated schema for both configured and unconfigured completion tools is unchanged, and the full suite still passes.
   - Justification: removes one indentation level in the higher-complexity branch.

6. In `packages/core/src/tools/topicTool.ts`, keep `UpdateTopicInvocation.execute(_options: ExecuteOptions)` as an unused options parameter rather than destructuring an unused `abortSignal`.
   - Testable claim: behavior remains unchanged because no execution option is currently read and the full suite still passes.
   - Justification: preserves the interface with the least local indirection.

7. In `packages/core/src/tools/shellBackgroundTools.ts`, change `ListBackgroundProcessesInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
   - Testable claim: behavior is unchanged because list-background-process execution does not read the signal and the full suite still passes.
   - Justification: removes unused destructuring from a method that only reads session state.

8. In `packages/core/src/tools/ls.ts`, change `LSToolInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
   - Testable claim: directory listing output and path validation are unchanged because the signal is unused, and the full suite still passes.
   - Justification: avoids manufacturing an unused local variable.

9. In `packages/sdk/src/tool.ts`, change `SdkToolInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring both `{ abortSignal: _abortSignal, updateOutput: _updateOutput }`.
    - Testable claim: SDK tool action execution and result formatting are unchanged because neither option is read, and the full suite still passes.
    - Justification: removes two unused aliases from a wrapper that delegates only to `this.action`.

10. In `packages/core/src/tools/trackerTools.ts`, change `TrackerCreateTaskInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
    - Testable claim: created task fields and return display are unchanged because the abort signal is unused, and the full suite still passes.
    - Justification: removes unused destructuring from the create-task path.

11. In `packages/core/src/tools/trackerTools.ts`, change `TrackerUpdateTaskInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
    - Testable claim: update behavior, error handling, and return display are unchanged because the abort signal is unused, and the full suite still passes.
    - Justification: removes unused destructuring from the update-task path.

12. In `packages/core/src/tools/trackerTools.ts`, change `TrackerGetTaskInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
    - Testable claim: missing-task and found-task responses are unchanged because the abort signal is unused, and the full suite still passes.
    - Justification: removes unused destructuring from the get-task path.

13. In `packages/core/src/tools/trackerTools.ts`, change `TrackerListTasksInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
    - Testable claim: filtering and returned todo display are unchanged because the abort signal is unused, and the full suite still passes.
    - Justification: removes unused destructuring from the list-task path.

14. In `packages/core/src/tools/trackerTools.ts`, change `TrackerAddDependencyInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
    - Testable claim: self-dependency rejection, service call behavior, and return display are unchanged because the abort signal is unused, and the full suite still passes.
    - Justification: removes unused destructuring from the dependency path.

15. In `packages/core/src/tools/trackerTools.ts`, change `TrackerVisualizeInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
    - Testable claim: empty-graph and rendered-graph responses are unchanged because the abort signal is unused, and the full suite still passes.
    - Justification: removes unused destructuring from the visualization path.

16. In `packages/core/src/test-utils/mock-tool.ts`, change `MockModifiableToolInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring unused `abortSignal` and `updateOutput`.
    - Testable claim: mock execution still calls `executeFn(this.params)` and returns the same default result, and the full suite still passes.
    - Justification: removes test utility noise introduced by the new options-bag signature without editing any test file.

17. In `packages/core/src/tools/tool-registry.ts`, change `DiscoveredToolInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring unused `abortSignal` and `updateOutput`.
    - Testable claim: external command invocation arguments and result handling are unchanged because neither option is used, and the full suite still passes.
    - Justification: removes unused aliases from a wrapper that only invokes the configured command.

18. In `packages/core/src/tools/write-todos.ts`, change `WriteTodosToolInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
    - Testable claim: todo serialization and returned content are unchanged because the signal is unused, and the full suite still passes.
    - Justification: removes an unused binding from a pure in-memory update.

19. In `packages/core/src/tools/activate-skill.ts`, change `ActivateSkillInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
    - Testable claim: skill lookup, activation, and error return behavior are unchanged because the signal is unused, and the full suite still passes.
    - Justification: removes unused destructuring from synchronous validation logic.

20. In `packages/core/src/tools/ask-user.ts`, change `AskUserInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
    - Testable claim: confirmation outcome handling and returned question payload are unchanged because the signal is unused, and the full suite still passes.
    - Justification: removes an unused local alias in a method driven by stored confirmation state.

21. In `packages/core/src/tools/enter-plan-mode.ts`, change `EnterPlanModeInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
    - Testable claim: cancel and proceed outputs are unchanged because the signal is unused, and the full suite still passes.
    - Justification: removes unused destructuring from a simple state transition.

22. In `packages/core/src/tools/exit-plan-mode.ts`, change `ExitPlanModeInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
    - Testable claim: plan validation, write behavior, and result output are unchanged because the signal is unused, and the full suite still passes.
    - Justification: removes unused destructuring from the invocation signature.

23. In `packages/core/src/tools/get-internal-docs.ts`, change `GetInternalDocsInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
    - Testable claim: docs-root lookup and output formatting are unchanged because the signal is unused, and the full suite still passes.
    - Justification: removes an unused alias from a read-only metadata tool.

24. In `packages/core/src/tools/memoryTool.ts`, change `MemoryToolInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
    - Testable claim: memory file path resolution, modification handling, and returned content are unchanged because the signal is unused, and the full suite still passes.
    - Justification: removes an unused signal binding from a method that does not support cancellation.

25. In `packages/core/src/tools/shellBackgroundTools.ts`, change `ReadBackgroundOutputInvocation.execute` to accept `_options: ExecuteOptions` instead of destructuring `{ abortSignal: _signal }`.
    - Testable claim: delay handling, process lookup, and output formatting are unchanged because the signal is unused, and the full suite still passes.
    - Justification: removes unused destructuring from a method controlled by `delay_ms` and process state.

## Rejected claims

1. Do not refactor `packages/core/src/agents/local-executor.ts` `parseToolCallArgs` or `processFunctionCalls`, even though the spec mentions the new JSON-string parsing block.
   - Reason: `packages/core/src/agents/local-executor.ts` is not listed in `FORGE_ALLOWED_FILES.txt`, so any edit would violate the allowed edit set.

2. Do not move `CompleteTaskTool` registration or completion handling back into `LocalAgentExecutor`.
   - Reason: that would touch `packages/core/src/agents/local-executor.ts`, which is outside the allowed edit set, and would reverse the feature's main extraction.

3. Do not edit any `*.test.ts`, `*.test.tsx`, or snapshot test file to codify these claims.
   - Reason: the task explicitly forbids test-file edits; verification must come from the existing suite.

4. Do not rename `ExecuteOptions.abortSignal`, `ExecuteOptions.updateOutput`, `shellExecutionConfig`, or `setExecutionIdCallback`.
   - Reason: those names are public API surface in `packages/core/src/tools/tools.ts` and are now used across core, CLI, A2A, and SDK call sites.

5. Do not make `ExecuteOptions.abortSignal` optional to avoid unused parameters in simple tools.
   - Reason: it weakens the new execution contract and risks missing cancellation wiring at call sites.

6. Do not remove `ExecuteOptions` from simple tool invocation files by using `any` or an untyped `_options` parameter.
   - Reason: it hides the interface guarantee and reduces type checking rather than reducing implementation complexity.

7. Do not change `packages/cli/src/ui/key/keyBindings.ts` command copy further.
   - Reason: command descriptions are user-facing behavior, not refactoring, and the current diff already made a behavioral copy change.

8. Do not undo the `packages/a2a-server/src/commands/memory.ts` `signal` to `abortSignal` local rename.
   - Reason: the new name matches the migrated options-bag terminology and reverting it would be style churn without complexity reduction.

9. Do not collapse the new `ExecuteOptions` object back into positional `execute(signal, updateOutput, options)` calls.
   - Reason: that changes the direction of the feature-wide API migration and would touch many call sites without simplifying the accepted surface.

10. Do not add a shared helper for tools that ignore `ExecuteOptions`.
    - Reason: a new abstraction would add indirection for a one-line signature pattern and is explicitly discouraged by the refactor spec.

11. Do not introduce a `stringifyOutput` helper exported from `complete-task.ts` for the duplicated string/JSON formatting.
    - Reason: the duplication is local to one method and can be simplified inline without adding another named concept.

12. Do not edit `packages/core/src/tools/tools.ts` to fix the pre-existing duplicated `/**` comment before `ForcedToolDecision`.
    - Reason: it is outside the behavior introduced by `FORGE_INPUT_DIFF.patch` and would be unrelated cleanup.

13. Do not add comment-only claims for `ExecuteOptions` JSDoc in `packages/core/src/tools/tools.ts` or `packages/core/src/core/coreToolHookTriggers.ts`.
    - Reason: documentation alignment may be useful later, but it is not an independently testable complexity reduction.

14. Do not make import-spacing-only changes in `packages/core/src/tools/complete-task.ts`.
    - Reason: formatter-only edits are outside the requested complexity-focused refactor claims.
