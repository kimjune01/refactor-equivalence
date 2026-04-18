## Accepted Claims

### C1 — Factor PowerShell exit-code enforcement
**File**: .github/workflows/ci.yml:430
**Change**: In the Windows `Run tests and generate reports` step, introduce a small local PowerShell wrapper/function for npm invocations that runs the command and immediately exits with `$LASTEXITCODE` when nonzero, then replace the three repeated `npm run ...` plus `if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }` pairs in that step with calls to the wrapper.
**Goal link**: This clarifies the Windows CI error-swallowing fix by making exit-code propagation the invariant of every npm test command in the PowerShell step.
**Justification**: The behavior remains the same, but the failure-handling rule is expressed once instead of being manually duplicated after each command.

### C2 — Use the shared error-message helper for unreadable directories
**File**: packages/core/src/utils/bfsFileSearch.ts:81
**Change**: Import `getErrorMessage` from `./errors.js` and use it in both async and sync unreadable-directory catch blocks instead of casting `unknown` to `Error` and reading `.message`.
**Goal link**: This supports the path and filesystem cross-platform test fixes by using the codebase's existing error-normalization idiom for filesystem failures.
**Justification**: It removes two unsafe assertions and restores one shared helper for the same warning text construction without changing normal `Error` output.

### C3 — Remove unreachable narrowing guard inside command-prefix policy updates
**File**: packages/core/src/policy/config.ts:571
**Change**: Delete the `TOOLS_REQUIRING_NARROWING.has(toolName) && !message.commandPrefix` guard from the `if (message.commandPrefix)` branch of `createPolicyUpdater`, leaving the existing `argsPattern` guard in the `else` branch intact.
**Goal link**: This reduces accidental complexity in policy updates touched by the cross-platform test cleanup while keeping the sensitive-tool narrowing check where it can actually fire.
**Justification**: The condition is unreachable because the enclosing branch already requires `message.commandPrefix`, so removing it preserves behavior and eliminates dead code.

### C4 — Compute quota reset display text once per model row
**File**: packages/cli/src/ui/components/StatsDisplay.tsx:360
**Change**: Inside the `rows.map` callback in `ModelUsageTable`, compute a `resetText` local from `row.bucket?.resetTime ? formatResetTime(row.bucket.resetTime, 'column') : ''` and render that value in the reset column instead of calling `formatResetTime` twice in the JSX ternary.
**Goal link**: This clarifies the quota display changes that were part of getting exposed UI behavior passing consistently by keeping row formatting logic with the other per-row derived values.
**Justification**: It preserves rendered output while removing duplicated formatter calls and simplifying the reset-column expression.

## Rejected

- Reintroduce `packages/cli/src/nonInteractiveCliAgentSession.ts` or the `getAgentSessionNoninteractiveEnabled()` branch in `packages/cli/src/nonInteractiveCli.ts`: this would restore a deleted execution path and change observable non-interactive behavior rather than refactor the accepted implementation.
- Restore `displayContent` to `AgentSend.message` in `packages/core/src/agent/types.ts`, `packages/core/src/agent/legacy-agent-session.ts`, and `packages/core/src/agent/mock.ts`: this would cross a core public protocol boundary and undo a behavioral shape change in the artifact.
- Change `packages/core/src/utils/retry.ts` to check `signal.aborted` again after `fn()` or after retry delays: this may alter cancellation timing and thrown errors, so it is a behavior change rather than a bounded refactor.
- Replace `JSON.parse(content) as ToolCallData` in `packages/core/src/utils/checkpointUtils.ts` with the existing Zod schema in `getCheckpointInfoList`: this would reject malformed but currently truthy non-string `messageId` values and therefore changes edge-case behavior.
- Restore the `typeof rawFilePath === 'string'` guard in `generateCheckpointFileName` in `packages/core/src/utils/checkpointUtils.ts`: this is safer, but it changes the current behavior for truthy non-string `file_path` values from throwing to returning `null`.
- Remove quotes from non-Windows workspace arguments in `.github/workflows/ci.yml`: it is not needed for Bash correctness, but keeping all workspace invocations quoted is harmless and consistent with the Windows CI goal.
- Reintroduce persisted policy `modes` in `packages/core/src/scheduler/policy.ts`, `packages/core/src/policy/config.ts`, `packages/core/src/policy/types.ts`, and `packages/core/src/confirmation-bus/types.ts`: this would restore removed semantics around approval-mode scoping and is not behavior-preserving.
