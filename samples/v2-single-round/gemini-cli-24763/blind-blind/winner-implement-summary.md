# Implementation Summary

## Applied Claims

### C1 — Use a read-file lifecycle finally for sandbox cleanup
**File**: `packages/core/src/services/sandboxedFileSystemService.ts`
Wrapped the child-process promise in `readTextFile` with `try { return await new Promise(...) } finally { prepared.cleanup?.() }`. Removed duplicated `prepared.cleanup?.()` calls from `close` and `error` handlers.

### C2 — Use a write-file lifecycle finally for sandbox cleanup
**File**: `packages/core/src/services/sandboxedFileSystemService.ts`
Wrapped the child-process promise in `writeTextFile` with `try { await new Promise(...) } finally { prepared.cleanup?.() }`. Removed duplicated `prepared.cleanup?.()` calls from `close` and `error` handlers.

### C3 — Cleanup grep command probing with one finally block
**File**: `packages/core/src/tools/grep.ts`
Wrapped the `await new Promise(...)` process probe in `isCommandAvailable` with `try...finally`, moved `cleanup?.()` to the `finally`, and removed it from `close` and `error` handlers.

### C4 — Use try/finally for discovered tool invocation cleanup
**File**: `packages/core/src/tools/tool-registry.ts`
In `DiscoveredToolInvocation.execute`, added `try...finally` immediately after sandbox preparation covering `spawn`, stdin writes, listener registration, and the child-process wait promise. Moved `cleanupFunc?.()` to `finally`, removed it from `onClose` and `onError`.

### C5 — Use try/finally for tool discovery cleanup
**File**: `packages/core/src/tools/tool-registry.ts`
In `discoverAndRegisterToolsFromCommand`, wrapped the `await new Promise<void>(...)` close/error wait in `try...finally`. Moved `cleanupFunc?.()` to `finally`, removed it from the promise's `error` and `close` handlers.

### C6 — Cleanup spawnAsync through an outer finally
**File**: `packages/core/src/utils/shell-utils.ts`
Wrapped the returned child-process promise in `spawnAsync` with `try { return await new Promise(...) } finally { prepared.cleanup?.() }`. Removed cleanup calls from `close` and `error` handlers.

### C7 — Cleanup execStreaming after the full streaming lifecycle settles
**File**: `packages/core/src/utils/shell-utils.ts`
Added an outer `try...finally` in `execStreaming` starting immediately after sandbox preparation, covering `spawn`, readline setup, the generator streaming loop, and generator teardown. Moved `prepared.cleanup?.()` to the outer `finally`. Removed cleanup calls from the early-error path, `checkExit`, and the late `error` handler.

## Files Modified
- `packages/core/src/services/sandboxedFileSystemService.ts` (C1, C2)
- `packages/core/src/tools/grep.ts` (C3)
- `packages/core/src/tools/tool-registry.ts` (C4, C5)
- `packages/core/src/utils/shell-utils.ts` (C6, C7)
