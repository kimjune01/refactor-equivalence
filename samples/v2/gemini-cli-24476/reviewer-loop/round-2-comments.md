## Comment 1 — Simplify npm execution in CI
**Severity**: approve-blocker
**File**: .github/workflows/ci.yml:431
**Request**: Remove the `Invoke-NpmOrExit` function and array splatting (`@('run', ...)`). Instead, simply quote the package names (e.g., `"--workspace", "@google/gemini-cli"`) in the inline `npm run` commands, and follow each command with `if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }`.
**Why**: The goal is specifically to quote the arguments to prevent PowerShell from misinterpreting `@`; creating a custom wrapper function with array splatting is unnecessarily complex and diverges from standard, readable inline CI commands.

## Comment 2 — Remove out-of-scope non-interactive agent session feature
**Severity**: approve-blocker
**File**: packages/cli/src/nonInteractiveCli.ts:65
**Request**: Revert the addition of the `getAgentSessionNoninteractiveEnabled` logic block and remove the newly created `packages/cli/src/nonInteractiveCliAgentSession.ts` file entirely.
**Why**: Adding a new non-interactive agent session feature is completely out of scope for a PR solely focused on fixing Windows CI execution and resolving cross-platform test failures.

## Comment 3 — Remove out-of-scope ApprovalMode changes
**Severity**: approve-blocker
**File**: packages/core/src/confirmation-bus/types.ts:150
**Request**: Revert the addition of `ApprovalMode` and the `modes?: ApprovalMode[]` property, along with the corresponding additions in `packages/core/src/scheduler/policy.ts` (e.g., `getScopedApprovalModes`) and `packages/core/src/policy/config.ts`.
**Why**: Modifications to the confirmation bus, scheduler policies, and approval modes are feature expansions that are entirely unrelated to the stated goal of fixing CI workflows and test failures.

## Comment 4 — Remove out-of-scope JSON formatter error type change
**Severity**: approve-blocker
**File**: packages/core/src/output/json-formatter.ts:46
**Request**: Revert the change from `error.constructor.name` to `getErrorType(error)` and remove the `getErrorType` import.
**Why**: Tweaking how errors are formatted in the JSON output is a separate functional change that is not relevant to resolving cross-platform test failures.

## Comment 5 — Remove out-of-scope shell background tool log change
**Severity**: approve-blocker
**File**: packages/core/src/tools/shellBackgroundTools.ts:210
**Request**: Revert the change to the log header condition (removing `this.params.lines !== undefined`).
**Why**: Modifying the log header logic for background shell tools is completely out of scope for a PR focused on fixing tests and CI configurations.