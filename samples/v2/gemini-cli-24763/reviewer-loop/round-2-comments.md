## Comment 1 — Missing `try...finally` in SandboxedFileSystemService
**Severity**: approve-blocker
**File**: packages/core/src/services/sandboxedFileSystemService.ts:62
**Request**: Wrap the returned `Promise` in a `try { return await new Promise(...) } finally { prepared.cleanup?.() }` block in both `readTextFile` and `writeTextFile` (around line 124) instead of relying on `.on('close')` and `.on('error')` handlers.
**Why**: The PR goal explicitly states that all process execution logic must use `try...finally` blocks; currently, if `spawn` synchronously throws inside the Promise constructor, the event handlers are never attached and the cleanup is skipped.

## Comment 2 — Block-scoped cleanup leaked in childProcessFallback
**Severity**: approve-blocker
**File**: packages/core/src/services/shellExecutionService.ts:522
**Request**: Extract the `let cmdCleanup` declaration outside the `try` block, and ensure it gets called via `catch` or `finally` if process spawning or initialization fails synchronously.
**Why**: `cmdCleanup` is currently block-scoped inside the `try` block, meaning if `cpSpawn` synchronously throws, the `catch (e)` block cannot access it, leaking the sandbox resources.

## Comment 3 — Block-scoped cleanup leaked in executeWithPty
**Severity**: approve-blocker
**File**: packages/core/src/services/shellExecutionService.ts:854
**Request**: Move the `let cmdCleanup` declaration outside the `try` block, and ensure it gets called via `catch` or `finally` if `ptyInfo.module.spawn` throws.
**Why**: Similar to `childProcessFallback`, if process spawning synchronously throws, `cmdCleanup` is inaccessible from the `catch` block and the resource leaks.

## Comment 4 — Missing `try...finally` in GrepTool process check
**Severity**: approve-blocker
**File**: packages/core/src/tools/grep.ts:290
**Request**: In `isCommandAvailable`, wrap the `await new Promise(...)` that spawns the child process in a `try...finally { cleanup?.() }` block rather than relying on `.on('close')` and `.on('error')` events.
**Why**: A synchronous throw from `spawn` will completely bypass the Promise's event handlers, missing the cleanup.

## Comment 5 — Missing `try...finally` in ToolRegistry discovery
**Severity**: approve-blocker
**File**: packages/core/src/tools/tool-registry.ts:386
**Request**: Wrap the `proc = spawn(...)` call and the subsequent `await new Promise(...)` in a `try...finally { cleanupFunc?.(); }` block.
**Why**: If `spawn` throws synchronously, `cleanupFunc` will never be invoked because the execution skips over the Promise and exits the function.

## Comment 6 — Missing `try...finally` in shell-utils spawnAsync
**Severity**: approve-blocker
**File**: packages/core/src/utils/shell-utils.ts:846
**Request**: Refactor `spawnAsync` to use `try { return await new Promise(...) } finally { prepared.cleanup?.() }` instead of calling `prepared.cleanup?.()` inside the child's `.on('close')`/`.on('error')` handlers.
**Why**: Using a `finally` block around an `await`ed promise correctly guarantees cleanup even if `spawn` synchronously throws.

## Comment 7 — Incorrect `try...finally` placement in execStreaming
**Severity**: approve-blocker
**File**: packages/core/src/utils/shell-utils.ts:908
**Request**: Move the `const child = spawn(...)` call inside the `try` block and explicitly invoke `prepared.cleanup?.()` in the generator's `finally` block (lines 955-985).
**Why**: Currently, `spawn` is called before the `try` block, so if it throws synchronously, the generator's `finally` block is bypassed and `cleanup` is leaked.
