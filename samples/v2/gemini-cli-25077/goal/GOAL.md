# PR #25077 — perf(sandbox): optimize Windows sandbox initialization via native ACL application

## PR body

## Summary

This PR optimizes the Windows sandbox initialization performance by offloading file system ACL modifications from Node.js to the native C# helper (`GeminiSandbox.exe`). This eliminates the overhead of spawning multiple `icacls.exe` processes.

## Details

- **Native ACL Application**: Updated `GeminiSandbox.cs` to apply ACLs natively using .NET's `FileSystemSecurity` and P/Invoke (`SetNamedSecurityInfo`).
- **Bulk Processing via Manifests**: `WindowsSandboxManager.ts` now aggregates allowed and forbidden paths into temporary manifest files, which are passed to the helper via `--allowed-manifest` and `--forbidden-manifest` flags.
- **Improved Isolation**: The native helper now sets the "Low Mandatory Level" integrity label and adds explicit "Deny FullControl" rules for forbidden/secret files directly in the process setup phase.

## Related Issues

N/A

## How to Validate

Execute the unit and integration tests on a Windows environment:
```bash
npm run test -w @google/gemini-cli-core -- src/sandbox/windows
npm run test -w @google/gemini-cli-core -- src/services/sandboxManager.integration.test.ts
```

## Pre-Merge Checklist

- [ ] Updated relevant documentation and README (if needed)
- [x] Added/updated tests (if needed)
- [ ] Noted breaking changes (if any)
- [ ] Validated on required platforms/methods:
  - [ ] MacOS
  - [x] Windows
    - [x] npm run
    - [ ] npx
    - [ ] Docker
  - [ ] Linux


## Linked issues
(none)
