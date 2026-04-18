## Accepted Claims

### C1 — Remove duplicate proactive permission comment
**File**: packages/core/src/sandbox/utils/proactivePermissions.ts:74
**Change**: Delete one of the two identical JSDoc blocks immediately preceding `getProactiveToolSuggestions`.
**Goal link**: This clarifies the proactive permission helper introduced for sandbox usability.
**Justification**: Removing the duplicated comment preserves behavior while eliminating accidental copy-paste noise around the core new helper.

### C2 — Drop redundant workspace equality check
**File**: packages/core/src/policy/policy-engine.ts:667
**Change**: In the additional-permission workspace guard, replace the condition `!isSubpath(workspace, p) && workspace !== p` with `!isSubpath(workspace, p)`.
**Goal link**: This clarifies the goal of requiring explicit confirmation for additional permission paths outside the workspace.
**Justification**: `isSubpath(workspace, p)` already returns true when the two paths are equal, so the extra equality check adds no behavior and makes the boundary rule harder to read.

### C3 — Gate proactive suggestions after command need is known
**File**: packages/core/src/tools/shell.ts:257
**Change**: In `ShellToolInvocation.shouldConfirmExecute`, parse the command and call `isNetworkReliantCommand(rootCommand, subCommand)` before awaiting `getProactiveToolSuggestions(rootCommand)`, and only fetch suggestions inside the `needsNetwork` branch.
**Goal link**: This keeps proactive permission checks focused on commands that actually need expanded sandbox access.
**Justification**: The current order probes home/cache paths for commands such as `npm test` that will not use the result, so moving the suggestion lookup behind the existing need check removes unnecessary work without changing confirmation outcomes.

### C4 — Avoid passing empty sandbox permissions during normal shell execution
**File**: packages/core/src/tools/shell.ts:529
**Change**: Build a local merged `SandboxPermissions | undefined` from explicit `additional_permissions` and `proactivePermissionsConfirmed`, and pass `undefined` to `ShellExecutionService.execute` when neither source contains network, read, or write permissions.
**Goal link**: This makes the shell execution path express the difference between ordinary sandboxed execution and execution with expanded permissions.
**Justification**: An unconditional `{ fileSystem: { read: [], write: [] } }` object is accidental structure that downstream code treats the same as no permissions, so omitting it when empty preserves behavior while simplifying the data flow.

### C5 — Iterate denial text sources once
**File**: packages/core/src/sandbox/utils/sandboxDenialUtils.ts:71
**Change**: In `parsePosixSandboxDenials`, create a `const sources = [output, errorOutput].filter((s): s is string => !!s)` and run each path-extraction regex over each source, resetting `lastIndex` before each source.
**Goal link**: This clarifies the improved sandbox denial detection by making stdout and error-message parsing follow one path.
**Justification**: The current loop duplicates the same regex execution for `output` and `errorOutput`, and consolidating it preserves extracted paths while reducing branching inside the parser.

## Rejected

- Remove the `yolo` property from `SandboxModeConfig` and the platform managers: although `getModeConfig('yolo')` currently sets `network: true` and `readonly: false`, deleting the flag could change behavior for any caller that passes a `modeConfig` with `yolo: true` directly.
- Narrow `isNetworkReliantCommand('git')` to only remote-oriented git subcommands: this may be a product improvement, but it changes observable proactive confirmation behavior and is not a behavior-preserving refactor.
- Move `ShellToolInvocation.simplifyPaths` to a shared sandbox utility file: this would add a new exported helper for a single current call site and broaden the public surface without a goal-driven need.
- Change `sandbox-default.toml` default `readonly = false` back to `true`: this would directly alter the sandbox usability behavior chosen by the artifact rather than refactoring its expression.
- Add or update tests for the accepted claims: test files are outside the requested edit scope, and the claims are intended to be validated by the existing C_test suite.
