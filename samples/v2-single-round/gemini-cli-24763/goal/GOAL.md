# PR #24763 — fix(core): ensure robust sandbox cleanup in all process execution paths

## PR body

## Summary
Fix memory leaks and resource exhaustion in sandboxed process execution. This PR adds missing sandbox cleanup calls and wraps all process execution logic in robust `try...finally` blocks to ensure sidecar processes and temporary files are reliably terminated across all success, error, and early-abort paths.

## Details
The original implementation missed calling `prepared.cleanup?.()` in several execution paths, leading to resource leaks. Additionally, standard event handlers were insufficient to guarantee cleanup during synchronous throws or aborted generators.

Changes included in this PR:
1. **Added Missing Cleanups:** Ensure `cleanup` is invoked in previously unhandled success and error paths.
2. **Refactored to `try...finally`:** Upgraded all sandbox process execution methods to use `try...finally` blocks for guaranteed execution, regardless of how the process terminates.

Affected areas:
- `SandboxedFileSystemService`: `read_file` and `write_file` paths.
- `GrepTool`: Success and error paths.
- `ToolRegistry`: Success and error paths for both tool discovery and invocation.
- `shell-utils`: `spawnAsync` and `execStreaming` paths.
- `ShellExecutionService`: `childProcessFallback` and `executeWithPty` paths.

## Related Issues
Mentioned in https://github.com/google-gemini/gemini-cli/pull/24480 review.

## How to Validate
Run the core tests that use the sandbox and shell execution:
`npm test -w @google/gemini-cli-core -- src/utils/sandboxUtils.test.ts src/services/sandboxedFileSystemService.test.ts src/tools/grep.test.ts src/tools/tool-registry.test.ts src/services/shellExecutionService.test.ts`

## Pre-Merge Checklist
- [ ] Updated relevant documentation and README (if needed)
- [x] Added/updated tests (if needed)
- [ ] Noted breaking changes (if any)
- [x] Validated on required platforms/methods:
  - [x] MacOS
    - [x] npm run

## Linked issues
(none)
