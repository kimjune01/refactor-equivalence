# PR #24834 — fix(core): resolve windows symlink bypass and stabilize sandbox integration tests

## PR body

## Summary

This PR resolves persistent flakiness and 60-second timeouts in the `sandboxManager.integration.test.ts` suite on Windows CI runners, and fixes a critical vulnerability where Windows sandboxed processes could bypass `forbiddenPaths` restrictions by accessing files via symlinks.

To achieve this, we optimized the test workspace isolation strategy and fundamentally refactored how the sandbox manages path resolution across all operating systems to ensure symlink targets are explicitly evaluated and secured.

## Details

**1. Centralized Path Resolution Architecture:**
- Introduced `ResolvedSandboxPaths`, a structured interface that acts as the "Source of Truth" for all sandbox boundaries (workspace, global includes, policy-allowed paths, and dynamic read/write permissions).
- Refactored `resolveSandboxPaths` to centralize all symlink expansion, absolute path enforcement, and deduplication logic. Every path category now automatically yields both the symlink and its real target, preventing bypasses across all OS sandbox engines.
- Streamlined `WindowsSandboxManager` to fully consume the pre-resolved struct, eliminating redundant local loops and improving the robustness of ACL applications (e.g., distinguishing between files and directories for inheritance flags).
- *Note:* macOS and Linux managers have been minimally updated to consume the new interface fields. A follow-up PR will fully refactor their internal profile builders to remove remaining redundant path logic.

**2. Stabilized Sandbox Integration Tests:**
- **Isolated Workspaces:** Replaced `process.cwd()` with isolated temporary directories. This prevents false positives and massively speeds up `icacls` execution on Windows runners by using `os.tmpdir()`.
- **Standardized Execution:** Eliminated dependencies on native shell utilities (`powershell.exe`, `touch`, `curl`). The `Platform` test helper now exclusively uses `process.execPath` (`node -e`), which resolved a specific Windows hang caused by launching `powershell.exe` from the `%TEMP%` directory with a Low Mandatory Level token.
- **Refined Assertions:** Split read/write inheritance tests into distinct assertions and added an `assertResult` helper to bundle command context directly into failure messages.

## Related Issues



## How to Validate

1. Ensure you are on a Windows machine or VM.
2. Run the core integration tests: `npm test -w @google/gemini-cli-core -- src/services/sandboxManager.integration.test.ts`
3. Verify that all tests pass rapidly (without 60s timeouts) and that the test output confirms the symlink write-block assertions are succeeding.
4. Run `npm run preflight` to ensure cross-platform path resolution typing is fully sound.

## Pre-Merge Checklist

- [ ] Updated relevant documentation and README (if needed)
- [x] Added/updated tests (if needed)
- [ ] Noted breaking changes (if any)
- [ ] Validated on required platforms/methods:
  - [x] MacOS
    - [x] npm run
    - [ ] npx
    - [ ] Docker
    - [ ] Podman
    - [ ] Seatbelt
  - [x] Windows
    - [x] npm run
    - [ ] npx
    - [ ] Docker
  - [x] Linux
    - [x] npm run
    - [ ] npx
    - [ ] Docker

## Linked issues
(none)
