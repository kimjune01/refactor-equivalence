## Comment 1 — Out of scope configuration change
**Severity**: approve-blocker
**File**: packages/cli/src/config/config.ts:941
**Request**: Revert the addition of `allowedEnvironmentVariables: settings.security?.environmentVariableRedaction?.allowed,`.
**Why**: This change is unrelated to the PR goal of fixing memory leaks and resource exhaustion in sandboxed process execution paths, and should be handled in a separate, dedicated PR.

## Comment 2 — Variable shadowing in ToolRegistry
**Severity**: nice-to-have
**File**: packages/core/src/tools/tool-registry.ts:117
**Request**: Rename the outer `cleanup` variable (declared as `let cleanup = () => {};` and initialized with `cleanupOnce`) to something like `sandboxCleanup`. 
**Why**: The inner `cleanup()` function defined inside the Promise shadows the outer `cleanup` variable, which makes the code confusing to read, even though the `finally` block resolves to the correct outer variable.

## Comment 3 — Duplication of cleanupOnce utility
**Severity**: nice-to-have
**File**: packages/core/src/services/sandboxedFileSystemService.ts:14
**Request**: Extract the `cleanupOnce` helper function into a shared utility file (e.g. `packages/core/src/utils/shell-utils.ts` or `packages/core/src/utils/sandboxUtils.ts`) instead of duplicating it 4 times across different files.
**Why**: Deduplicating this utility function reduces boilerplate and adheres to the DRY principle.