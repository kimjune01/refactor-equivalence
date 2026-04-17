# PR #24460 — fix(core): enhance sandbox usability and fix build error

## PR body

## Summary

Enhance sandbox usability by introducing proactive permissions and improved denial detection. This PR addresses issues where users might be blocked by sandbox restrictions without clear feedback or easy ways to grant permissions.

## Details

- Refactored `SandboxManager` and `ShellTool` to support proactive permission checks.
- Improved the feedback mechanism when a command is denied by the sandbox.
- Updated `shell.test.ts` to reflect the changes in `SandboxManager` access via `Config`.
- Fixed a build error in `shell.test.ts` where `sandboxManager` was incorrectly assigned.

## Related Issues

N/A

## How to Validate

1. Run `npm test -w @google/gemini-cli-core -- src/tools/shell.test.ts` to ensure shell tool tests pass.
2. Run a command that is normally denied by the sandbox and verify the improved denial message.
3. Verify that proactive permissions are working as expected.

## Pre-Merge Checklist

- [ ] Updated relevant documentation and README (if needed)
- [x] Added/updated tests (if needed)
- [ ] Noted breaking changes (if any)
- [x] Validated on required platforms/methods:
  - [x] MacOS
    - [x] npm run


## Linked issues

(none)
