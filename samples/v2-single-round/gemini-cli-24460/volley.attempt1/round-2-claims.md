## Accepted Claims

### C1 — Remove Duplicate Proactive Permissions Comment
**File**: packages/core/src/sandbox/utils/proactivePermissions.ts:74
**Change**: Delete one of the two identical JSDoc blocks immediately above `getProactiveToolSuggestions`, leaving a single description for the exported function.
**Goal link**: The goal adds proactive permission suggestions; a single function comment states that intent without visual noise.
**Justification**: Removing the duplicated comment reduces accidental draft clutter while preserving the function signature and all behavior.

### C2 — Centralize Command Name Normalization
**File**: packages/core/src/sandbox/utils/proactivePermissions.ts:44
**Change**: Add a small private `normalizeCommandName(commandName: string): string` helper in this module and use it in both `isNetworkReliantCommand` and `getProactiveToolSuggestions` instead of repeating `commandName.toLowerCase().replace(/\.exe$/, '')`.
**Goal link**: The goal relies on consistently recognizing tools that need proactive sandbox permissions.
**Justification**: Centralizing the normalization makes the recognition rule explicit and removes duplicated string handling without changing any returned permissions.

### C3 — Align Proactive Confirmation Comments With Actual Tool Scope
**File**: packages/core/src/tools/shell.ts:249
**Change**: Update the comments in `shouldConfirmExecute` and `getConfirmationDetails` that describe proactive expansion so they refer to known network-reliant tools, not only Node.js ecosystem tools.
**Goal link**: The goal mentions proactive permissions generally, and the implementation applies them to `git`, `ssh`, `curl`, and `wget` as well as package managers.
**Justification**: Correcting the comments removes misleading implementation narrative without affecting confirmation flow.

### C4 — Build Execution Additional Permissions Through a Local Merge
**File**: packages/core/src/tools/shell.ts:529
**Change**: In `ShellToolInvocation.execute`, compute a local `additionalPermissions` value immediately before the `ShellExecutionService.execute` call by merging `this.params[PARAM_ADDITIONAL_PERMISSIONS]` and `this.proactivePermissionsConfirmed`, and pass that local variable instead of constructing the nested object inline in the service options.
**Goal link**: The goal adds explicit and proactive permission expansion paths; naming the merged permissions makes the handoff to sandbox execution direct.
**Justification**: This keeps the existing merge behavior but removes a large inline options expression from the execution call, making the permission flow easier to audit.

## Rejected

- Move `simplifyPaths` out of `ShellToolInvocation` into a shared sandbox utility: it currently has one production call site and depends on shell-specific presentation heuristics for denied-path suggestions, so moving it would create a broader abstraction than the goal requires.
- Remove the `getWorkspace()` method from `SandboxManager` and read the target directory directly in `PolicyEngine`: this would cross the sandbox manager interface boundary introduced by the artifact and would require touching every implementation contract, not just simplifying expression of the goal.
- Remove proactive suggestions from post-execution denial handling because `shouldConfirmExecute` already handles known commands: this would change observable behavior when a command is allowed initially but later fails with sandbox-denial output, including the expansion-required path covered by shell sandbox heuristic tests.
- Revert the default sandbox policy `readonly = false`: this is a behavioral policy change, not a behavior-preserving refactor, and it would alter the sandbox mode semantics rather than clean up the implementation.
- Consolidate `sandbox_expansion` confirmation construction between `ShellToolInvocation` and `scheduler.ts`: `scheduler.ts` is not in the allowed edit set, so this would be out of scope for the requested claims.
