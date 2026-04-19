## Comment 1 — Clear `cmdCleanup` in error handlers to prevent double-invocation
**Severity**: nice-to-have
**File**: packages/core/src/services/shellExecutionService.ts:814
**Request**: Add `cmdCleanup = undefined;` immediately after `cmdCleanup?.();` in the `catch` block of `childProcessFallback` (and make the identical change in the `catch` block for `executeWithPty` around line 1249).
**Why**: While the underlying sandbox cleanup functions safely ignore errors on double execution, clearing the reference matches the pattern you established in the success paths (`closeCommand` and `finalize`), preventing an unnecessary secondary execution if the process lifecycle events (like `onExit`) still fire during teardown.
