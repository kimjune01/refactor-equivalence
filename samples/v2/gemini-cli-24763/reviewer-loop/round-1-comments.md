## Comment 1 — Missing refactor in childProcessFallback
**Severity**: approve-blocker
**File**: packages/core/src/services/shellExecutionService.ts:505
**Request**: Apply the `try...finally` refactoring to `childProcessFallback` to ensure `cmdCleanup?.()` is called regardless of how the process terminates (e.g., by wrapping the returned `result` promise in an async wrapper that has a `finally` block).
**Why**: The PR description explicitly states that `childProcessFallback` in `ShellExecutionService` must be refactored to use `try...finally` blocks for guaranteed cleanup, but this file was completely omitted from the diff.

## Comment 2 — Missing refactor in executeWithPty
**Severity**: approve-blocker
**File**: packages/core/src/services/shellExecutionService.ts:830
**Request**: Apply the `try...finally` refactoring to `executeWithPty` to ensure `cmdCleanup?.()` is called regardless of how the process terminates (e.g., by wrapping the returned `result` promise in an async wrapper that has a `finally` block).
**Why**: The PR description explicitly states that `executeWithPty` in `ShellExecutionService` must be refactored to use `try...finally` blocks for guaranteed cleanup, but this file was completely omitted from the diff.
