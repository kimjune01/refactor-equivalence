# Sharpened Spec Final: Refactoring Claims

## Accepted Claims

1. **`packages/core/src/context/contextCompressionService.ts`, `ContextCompressionService.setState`: replace the explicit `clear` plus `for...of Object.entries` loop with `this.state = new Map(Object.entries(stateData))`.**
   - Testable claim: loaded file records are identical after `setState`, and the full suite still passes.
   - Justification: constructing the map directly removes mutation steps and mirrors the inverse of object-entry serialization.

2. **`packages/core/src/context/contextCompressionService.ts`, `compressHistory` pass 1: move the `i >= cutoff` guard before inspecting `functionCall.args`.**
   - Testable claim: only files read within the protected window are still added to `protectedFiles`, and the full suite still passes.
   - Justification: a single early `continue` removes the duplicated protected-window checks inside both `paths` and `filepath` branches.

3. **`packages/core/src/context/contextCompressionService.ts`, `compressHistory` and `applyCompressionDecision`: extract the repeated read-tool response parsing into a private `getReadToolOutput(part: Part)` helper returning `{ response, output } | undefined`.**
   - Testable claim: non-read function responses and missing or non-string outputs are still skipped, and the full suite still passes.
   - Justification: the same `functionResponse` name and output validation appears twice, so a narrow helper removes duplicated guard code without adding a new abstraction boundary outside the class.

4. **`packages/core/src/context/contextCompressionService.ts`, `compressHistory` and `applyCompressionDecision`: extract the repeated file-header parsing into a private `parseFilepathFromOutput(output: string): string | undefined`.**
   - Testable claim: both supported formats, `--- path ---\n` and a first line containing `---`, still resolve to the same filepath, unparseable outputs are still skipped, and the full suite still passes.
   - Justification: centralizing this parser prevents the two call sites from drifting and removes duplicated regex and fallback-line parsing.

5. **`packages/core/src/context/contextCompressionService.ts`, `compressHistory` and `applyCompressionDecision`: extract the repeated header-stripping block into a private `stripFileHeader(output: string): string`.**
   - Testable claim: outputs beginning with `--- ` still drop the first line when a newline exists, all other outputs stay unchanged, and the full suite still passes.
   - Justification: a small pure helper removes duplicated string slicing and makes the compression input rule explicit.

6. **`packages/core/src/context/contextCompressionService.ts`, `compressHistory` state update block: reuse the `PendingFile` content hash instead of recomputing it in pass 3.**
   - Testable claim: `contentHash` values written to state are unchanged, cached-summary invalidation still triggers on content changes, and the full suite still passes.
   - Justification: computing the same SHA-256 slice once per pending file removes redundant work and keeps hash ownership with the pending-file metadata.

7. **`packages/core/src/context/contextCompressionService.ts`, `compressHistory` pending-file type: remove unused `contentToProcess` and `lines` fields from `PendingFile`, keeping only `filepath`, `rawContent`, `preview`, `lineCount`, and the claimed `contentHash`.**
   - Testable claim: routing requests still receive the same filepath, preview, and line count, and the full suite still passes.
   - Justification: dropping fields never read after `pendingFiles.push` reduces object shape noise in the central loop.

8. **`packages/core/src/context/contextCompressionService.ts`, `batchQueryModel`: collapse the double object check around `decision` into a single `if (decision && typeof decision === 'object' && decision.level)` branch.**
   - Testable claim: invalid, missing, or level-less routing decisions are still ignored, valid decisions still override defaults, and the full suite still passes.
   - Justification: the current `typeof decision !== 'object'` guard is immediately repeated by the next condition.

9. **`packages/core/src/context/contextCompressionService.ts`, class fields and constructor: make `config` and `stateFilePath` `private readonly` constructor-initialized properties.**
   - Testable claim: construction and all method behavior remain unchanged, and the full suite still passes.
   - Justification: marking immutable dependencies as readonly documents lifecycle constraints and reduces the mutable surface of a new class.

10. **`packages/cli/src/config/config.ts`, `loadCliConfig` context-management block: inline the boolean defaults into `const useGeneralistProfile = !!settings.experimental?.generalistProfile` and `const useContextManagement = !!settings.experimental?.contextManagement`.**
    - Testable claim: absent settings still resolve to `false`, truthy boolean settings still enable the profile/config, and the full suite still passes.
    - Justification: this follows common local boolean coercion style and removes unnecessary nullish coalescing on boolean flags.

11. **`packages/core/src/config/config.ts`, constructor context-management defaults block: introduce a local `const contextManagement = params.contextManagement` and read defaults from it.**
    - Testable claim: all default values and provided overrides remain unchanged, and the full suite still passes.
    - Justification: the constructor currently repeats `params.contextManagement` through a large nested literal, which obscures the defaulting rules.

12. **`packages/core/src/config/config.ts`, `agentHistoryProviderConfig`: destructure `historyWindow` and `messageLimits` from `this.contextManagement` before returning the provider config.**
    - Testable claim: returned provider config values are unchanged, and the full suite still passes.
    - Justification: short local names make the config mapping easier to audit without changing the public getter.

13. **`packages/core/src/tools/web-fetch.ts`, `executeExperimental`: cache `const contextManagementEnabled = this.context.config.isContextManagementEnabled()` once before response handling and reuse it for all truncation checks.**
    - Testable claim: truncation is still skipped when context management is enabled and applied when disabled, and the full suite still passes.
    - Justification: the method asks the same config question four times in one response path, adding repetition without improving clarity.

14. **`packages/core/src/tools/web-fetch.ts`, `executeFallback`: cache `const contextManagementEnabled = this.context.config.isContextManagementEnabled()` before building `finalContentsByUrl`.**
    - Testable claim: fallback content still bypasses budget allocation when context management is enabled and still uses water-filling truncation when disabled, and the full suite still passes.
    - Justification: naming the mode once makes the branch condition clear and avoids repeated config access as this method evolves.

15. **`packages/core/src/context/contextCompressionService.ts`, `applyCompressionDecision`: replace the `if / else if` compression selector with a `switch (record.level)`.**
    - Testable claim: `PARTIAL`, `SUMMARY`, `EXCLUDED`, `FULL`, and unknown levels produce the same output or early return as today, and the full suite still passes.
    - Justification: the branch is a closed dispatch on `FileLevel`, so a switch makes each case independent and easier to scan.

## Rejected

1. **Rename `getMemoryContextManager` back to `getContextManager`.**
   - Reason: this would undo the diff's intended API rename and touch multiple call sites; it is not a simplification safely bounded to one independent change.

2. **Move `generalistProfile` from `packages/core/src/context/profiles.ts` into `packages/core/src/config/config.ts`.**
   - Reason: the profile is exported through `packages/core/src/index.ts` and imported by CLI config, so moving it would change module boundaries rather than reduce local complexity.

3. **Remove `packages/core/src/context/types.ts` and put the context-management interfaces back in `packages/core/src/config/config.ts`.**
   - Reason: multiple newly changed files now import these types from `context/types.ts`; undoing the split would increase coupling and risk public export churn.

4. **Edit or add tests for `ContextCompressionService`, `AgentHistoryProvider`, or CLI config.**
   - Reason: the task explicitly forbids touching `*.test.ts` and `*.test.tsx` files.

5. **Change `ContextCompressionService.compressHistory` to use `getContextManagementConfig().enabled` instead of `isContextManagementEnabled()`.**
   - Reason: this adds coupling to the config object shape and is not simpler than the dedicated boolean method already introduced by the diff.

6. **Remove fallback summary generation from `AgentHistoryProvider.getSummaryText`.**
   - Reason: although summarization is now always enabled when truncation runs, the fallback still preserves behavior on model errors and is not dead code.

7. **Replace the web-fetch truncation branches with a shared file-level helper used by both fallback and experimental modes.**
   - Reason: the thresholds and warning strings differ in places, so a broader helper risks hiding behavior behind a generic abstraction.

8. **Change `ContextCompressionService.batchQueryModel` to validate model decisions against the `FileLevel` union at runtime.**
   - Reason: this is type tightening and behavioral hardening, not a behavior-preserving complexity refactor requested for this round.

9. **Refactor `MemoryContextManager` method names such as `getEnvironmentMemory` or `discoverContext`.**
   - Reason: those names pre-exist the diff's rename and are used across the allowed files; changing them would exceed the diff-scoped simplification goal.

10. **Remove `isContextManagementEnabled` from a2a-server test mocks or core test mocks.**
    - Reason: test files are outside the allowed non-test edit target for this task, and the mock method is still required by the production API shape.

11. **`packages/core/src/context/contextCompressionService.ts`, `ContextCompressionService.getState` and `saveState`: replace the duplicated `Map`-to-object loop with `Object.fromEntries(this.state)`.**
    - Reason: `Object.fromEntries` changes behavior for a `"__proto__"` state key by creating an own enumerable data property where the current assignment loop does not, so serialization would no longer be byte-for-byte equivalent.

12. **`packages/core/src/context/contextCompressionService.ts`, `batchQueryModel`: replace the manual schema `properties` loop with `Object.fromEntries(files.map(...))`.**
    - Reason: `Object.fromEntries` changes generated schema behavior for a `"__proto__"` filepath by creating an own schema property where the current assignment loop does not.
