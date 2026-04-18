## Accepted Claims

1. **C1 — Factor PowerShell exit-code enforcement**
   **File**: .github/workflows/ci.yml:430
   **Change**: In the Windows `Run tests and generate reports` step, introduce a small local PowerShell wrapper/function for npm invocations that runs the command and immediately exits with `$LASTEXITCODE` when nonzero, then replace the three repeated `npm run ...` plus `if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }` pairs in that step with calls to the wrapper.
   **Goal link**: This clarifies the Windows CI error-swallowing fix by making exit-code propagation the invariant of every npm test command in the PowerShell step.
   **Justification**: The behavior remains the same, but the failure-handling rule is expressed once instead of being manually duplicated after each command.

## Rejected

- Use `getErrorMessage` for unreadable-directory catch blocks in `packages/core/src/utils/bfsFileSearch.ts`: rejected due to hunt finding F1, which identifies this as a blocker because `getErrorMessage` changes user-visible warning text for non-`Error` throw/rejection values compared with the current `.message ?? 'Unknown error'` behavior.
- Remove the unreachable command-prefix narrowing guard in `packages/core/src/policy/config.ts`: rejected due to hunt finding F2, which warns that this policy cleanup is orthogonal to the stated Windows CI and cross-platform test-fix goal.
- Compute quota reset display text once per model row in `packages/cli/src/ui/components/StatsDisplay.tsx`: rejected due to hunt finding F3, which warns that this quota UI cleanup is orthogonal to the stated Windows CI and cross-platform test-fix goal.
- Reintroduce `packages/cli/src/nonInteractiveCliAgentSession.ts` or the `getAgentSessionNoninteractiveEnabled()` branch in `packages/cli/src/nonInteractiveCli.ts`: this would restore a deleted execution path and change observable non-interactive behavior rather than refactor the accepted implementation.
- Restore `displayContent` to `AgentSend.message` in `packages/core/src/agent/types.ts`, `packages/core/src/agent/legacy-agent-session.ts`, and `packages/core/src/agent/mock.ts`: this would cross a core public protocol boundary and undo a behavioral shape change in the artifact.
- Change `packages/core/src/utils/retry.ts` to check `signal.aborted` again after `fn()` or after retry delays: this may alter cancellation timing and thrown errors, so it is a behavior change rather than a bounded refactor.
- Replace `JSON.parse(content) as ToolCallData` in `packages/core/src/utils/checkpointUtils.ts` with the existing Zod schema in `getCheckpointInfoList`: this would reject malformed but currently truthy non-string `messageId` values and therefore changes edge-case behavior.
- Restore the `typeof rawFilePath === 'string'` guard in `generateCheckpointFileName` in `packages/core/src/utils/checkpointUtils.ts`: this is safer, but it changes the current behavior for truthy non-string `file_path` values from throwing to returning `null`.
- Remove quotes from non-Windows workspace arguments in `.github/workflows/ci.yml`: it is not needed for Bash correctness, but keeping all workspace invocations quoted is harmless and consistent with the Windows CI goal.
- Reintroduce persisted policy `modes` in `packages/core/src/scheduler/policy.ts`, `packages/core/src/policy/config.ts`, `packages/core/src/policy/types.ts`, and `packages/core/src/confirmation-bus/types.ts`: this would restore removed semantics around approval-mode scoping and is not behavior-preserving.
