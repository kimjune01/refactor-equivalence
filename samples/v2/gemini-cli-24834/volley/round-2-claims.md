## Accepted Claims

### C1 — Name the path-resolution helpers by boundary role
**File**: packages/core/src/services/sandboxManager.ts:364
**Change**: In `resolveSandboxPaths`, rename the local `expand` helper to `expandSandboxPathSet` and the local `filter` helper to `filterOutWorkspaceAndForbidden`, then update only their in-function call sites with no logic changes.
**Goal link**: This clarifies the centralized path resolution architecture by making the two local operations express symlink expansion and boundary filtering directly.
**Justification**: Replacing generic helper names with goal-specific names removes reader-dependent interpretation while preserving the exact resolved path sets returned today.

### C2 — Remove stale step numbering from Windows sandbox preparation comments
**File**: packages/core/src/sandbox/windows/WindowsSandboxManager.ts:283
**Change**: In `prepareCommand`, remove the numeric prefixes from the phase comments around workspace access, global includes, policy allowed paths, additional write paths, secret scanning, governance files, manifest creation, and helper command construction.
**Goal link**: This keeps the Windows manager focused on consuming the pre-resolved path struct rather than implying an outdated ordered algorithm.
**Justification**: The current comments repeat and skip numbers after the refactor, so removing the numbering reduces accidental structure without changing any code path.

### C3 — Return the sanitized Windows environment directly
**File**: packages/core/src/sandbox/windows/WindowsSandboxManager.ts:419
**Change**: Delete the `const finalEnv = { ...sanitizedEnv };` temporary in `prepareCommand` and set the returned `env` field to `sanitizedEnv` directly.
**Goal link**: This streamlines the Windows sandbox manager around the actual sandbox preparation work after path resolution.
**Justification**: `finalEnv` is a one-use shallow copy of a local object, so removing it eliminates unnecessary state without changing the environment values returned to callers.

## Rejected

- Use `resolvedPaths.globalIncludes` in `MacOsSandboxManager.prepareCommand` when building `allowedPaths`: this would change observable macOS sandbox profile behavior for symlinked include directories rather than being a behavior-preserving refactor, and the goal explicitly notes POSIX profile-builder cleanup as follow-up work.
- Use `resolvedPaths.globalIncludes` in `LinuxSandboxManager.prepareCommand` when passing `includeDirectories` to `buildBwrapArgs`: this would alter Linux bind/mask behavior for symlinked include directories and is not safely behavior-preserving against C_test.
- Replace `this.options.workspace` with `resolvedPaths.workspace` in macOS or Linux profile construction and governance-file setup: this would change which textual workspace path is emitted or touched when the workspace itself is a symlink.
- Remove the exported async `tryRealpath` from `packages/core/src/services/sandboxManager.ts`: it appears unused by non-test source, but tests import or spy on the export, and removing it would cross an observable module boundary.
- Change `resolveSandboxPaths` so relative inputs are rejected before `resolveToRealPath` normalizes them: although closer to the comment's "absolute path enforcement" wording, it would change current behavior for relative path inputs.
- Fold the Windows `grantLowIntegrityAccess` and `denyLowIntegrityAccess` realpath calls into `resolveSandboxPaths`: those helpers are also used for discovered secret files, so removing local resolution would change behavior for paths that do not originate from the resolved struct.
- Refactor or remove memory-test files, package metadata, or unrelated settings changes from the artifact: those files are in the allowed edit set, but they do not express the sandbox symlink bypass or Windows integration-test stabilization goal.
