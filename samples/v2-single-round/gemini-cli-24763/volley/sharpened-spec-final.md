## Accepted Claims

### C1 — Use a read-file lifecycle finally for sandbox cleanup
**File**: packages/core/src/services/sandboxedFileSystemService.ts:62
**Change**: In `SandboxedFileSystemService.readTextFile`, wrap the spawned child-process promise in `try { return await new Promise(...) } finally { prepared.cleanup?.() }`, and remove the duplicated `prepared.cleanup?.()` calls from the `close` and `error` handlers.
**Goal link**: The goal calls for robust sandbox cleanup in process execution paths, especially by using `try...finally`.
**Justification**: A single `finally` attached to the read operation expresses that cleanup belongs to the sandboxed process lifecycle rather than to individual event branches, while preserving the existing success and failure results.

### C2 — Use a write-file lifecycle finally for sandbox cleanup
**File**: packages/core/src/services/sandboxedFileSystemService.ts:129
**Change**: In `SandboxedFileSystemService.writeTextFile`, wrap the spawned child-process promise in `try { await new Promise(...) } finally { prepared.cleanup?.() }`, and remove the duplicated `prepared.cleanup?.()` calls from the `close` and `error` handlers.
**Goal link**: The goal specifically names the sandboxed `write_file` path as needing guaranteed cleanup.
**Justification**: Moving cleanup to the write operation's `finally` block removes branch-level duplication and makes the cleanup guarantee independent of which child-process terminal event fires.

### C3 — Cleanup grep command probing with one finally block
**File**: packages/core/src/tools/grep.ts:351
**Change**: In `GrepToolInvocation.isCommandAvailable`, wrap the `await new Promise((resolve) => { ... })` process probe in `try...finally`, call `cleanup?.()` from the `finally`, and remove the cleanup calls from the `close` and `error` handlers.
**Goal link**: The goal identifies `GrepTool` success and error paths as cleanup-sensitive sandbox process execution.
**Justification**: A single cleanup point after the availability probe completes keeps the boolean outcomes unchanged while making sandbox cleanup an invariant of the probe rather than duplicated event-handler work.

### C4 — Use try/finally for discovered tool invocation cleanup
**File**: packages/core/src/tools/tool-registry.ts:96
**Change**: In `DiscoveredToolInvocation.execute`, start a `try...finally` immediately after sandbox preparation and after `cleanupFunc` is assigned, covering `spawn`, stdin writes, listener registration, and the existing child-process wait promise; call `cleanupFunc?.()` in the `finally`, remove the cleanup call from `onClose`, and keep `onError` limited to recording `error = err`.
**Goal link**: The goal calls out `ToolRegistry` tool invocation success and error paths.
**Justification**: The invocation already funnels normal process completion through the wait promise, and expanding the `try...finally` boundary to include spawn and stdin setup makes sandbox cleanup cover synchronous failures without changing stdout, stderr, code, signal, or error handling.
**Hunt note**: Retained as narrowed for F1 because the `finally` now begins immediately after sandbox preparation and covers the synchronous failure points identified by the finding.

### C5 — Use try/finally for tool discovery cleanup
**File**: packages/core/src/tools/tool-registry.ts:397
**Change**: In `ToolRegistry.discoverAndRegisterToolsFromCommand`, wrap the spawn plus the subsequent `await new Promise<void>(...)` close/error wait in `try...finally`, call `cleanupFunc?.()` in the `finally`, and remove the cleanup calls from the promise's `error` and `close` handlers.
**Goal link**: The goal names `ToolRegistry` discovery success and error paths as requiring cleanup.
**Justification**: Treating discovery cleanup as the final step of the spawned discovery command removes duplicated branch cleanup and also covers synchronous failures between sandbox preparation and event registration without changing discovery parsing behavior.

### C6 — Cleanup spawnAsync through an outer finally
**File**: packages/core/src/utils/shell-utils.ts:850
**Change**: In `spawnAsync`, wrap the returned child-process promise in `try { return await new Promise(...) } finally { prepared.cleanup?.() }`, and remove the cleanup calls from the `close` and `error` handlers.
**Goal link**: The goal explicitly includes `shell-utils` `spawnAsync` cleanup.
**Justification**: The helper's public result stays the same, but cleanup becomes a direct property of the async command execution rather than duplicated across the success and spawn-error branches.

### C7 — Cleanup execStreaming after the full streaming lifecycle settles
**File**: packages/core/src/utils/shell-utils.ts:971
**Change**: In `execStreaming`, add an outer `try...finally` that starts immediately after sandbox preparation and covers `spawn`, readline setup, the existing generator streaming loop, and generator teardown; call `prepared.cleanup?.()` from that outer `finally`, and remove the cleanup calls from the early-error, `checkExit`, and late `error` handler branches while preserving the existing process-exit wait and abort behavior.
**Goal link**: The goal specifically calls for robust cleanup in `execStreaming`, including aborted or early-closed generators.
**Justification**: Making cleanup cover all work after sandbox preparation ensures synchronous setup failures, normal streaming completion, aborts, and early generator close all release the sandbox while preserving line streaming and allowed-exit-code handling.
**Hunt note**: Retained as narrowed for F2 because the cleanup guard now covers the pre-teardown synchronous failure points identified by the finding, including `spawn` and readline creation.

## Rejected

- Add cleanup handling to `packages/core/src/services/shellExecutionService.ts` `childProcessFallback` and `executeWithPty`: rejected because `packages/core/src/services/shellExecutionService.ts` is not present in `allowed-files.txt`, even though the goal text mentions it.
- Introduce a shared helper for all sandboxed child-process cleanup across `SandboxedFileSystemService`, `GrepTool`, `ToolRegistry`, and `shell-utils`: rejected because it would be a broader abstraction spanning unrelated modules, and the goal can be expressed more cleanly with bounded local `try...finally` refactors.
- Change `SandboxManager.prepareCommand` or the `SandboxedCommand.cleanup` contract to make cleanup idempotent globally: rejected because `packages/core/src/services/sandboxManager.ts` is outside the allowed edit set and would cross a shared service API boundary.
- Remove the `try/catch` around sandbox preparation in `GrepToolInvocation.isCommandAvailable`: rejected because that fallback intentionally preserves command probing when sandbox preparation fails, and changing it would alter observable behavior.
