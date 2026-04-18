## Accepted Claims

### C1 — Name the low-integrity SID once
**File**: packages/core/src/sandbox/windows/GeminiSandbox.cs:186
**Change**: Add a private `LowIntegritySid` string constant near the token/ACL constants and use it in both `ConvertStringSidToSid(...)` during token lowering and `new SecurityIdentifier(...)` in `ApplyBulkAcls`.
**Goal link**: This clarifies the native ACL and Low Mandatory Level work called out by the goal.
**Justification**: Replacing two string literals with one named constant removes accidental duplication around the same Windows integrity identity without changing any ACLs or helper arguments.

### C2 — Extract low-integrity label application
**File**: packages/core/src/sandbox/windows/GeminiSandbox.cs:467
**Change**: Move the SDDL selection, `ConvertStringSecurityDescriptorToSecurityDescriptor`, `GetSecurityDescriptorSacl`, `SetNamedSecurityInfo`, and `LocalFree` block from the allowed-path loop into a private helper such as `ApplyLowIntegrityLabel(string path, bool isDirectory)`, called after the existing allow ACE is set.
**Goal link**: This isolates the native SACL label operation that replaces the old `/setintegritylevel` `icacls` call.
**Justification**: Keeping DACL allow-rule setup separate from mandatory-label P/Invoke setup makes the native ACL implementation easier to audit while preserving the same warning and continue-on-error behavior from `ApplyBulkAcls`.

### C3 — Split per-path ACL mutations from the bulk loop
**File**: packages/core/src/sandbox/windows/GeminiSandbox.cs:436
**Change**: Replace the bodies of the forbidden and allowed `foreach` loops in `ApplyBulkAcls` with calls to small private helpers, for example `ApplyDenyAcl(path, lowSid)` and `ApplyAllowAcl(path, lowSid)`, leaving the loops responsible only for iteration and warning handling.
**Goal link**: This expresses the goal's two manifest categories, forbidden and allowed, as two native ACL operations.
**Justification**: Separating loop control from file-versus-directory ACL mutation removes nested branching from the bulk processor without changing which paths are skipped, denied, or granted.

### C4 — Factor manifest file creation
**File**: packages/core/src/sandbox/windows/WindowsSandboxManager.ts:416
**Change**: Introduce a local helper in `prepareCommand`, such as `writeManifest(fileName: string, paths: Iterable<string>): string`, that joins the temp directory, writes `Array.from(paths).join('\n')`, and returns the manifest path; use it for both `forbidden.txt` and `allowed.txt`.
**Goal link**: This clarifies that `WindowsSandboxManager` now prepares bulk manifest inputs for the native helper.
**Justification**: Factoring the duplicated write blocks reduces incidental file-writing boilerplate while preserving manifest names, contents, argument ordering, and cleanup behavior.

## Rejected

- Move manifest creation into a shared module or exported helper: out of scope for the allowed edit set unless a new file were added, and no other production caller currently needs the abstraction.
- Reintroduce `allowedCache` or `deniedCache` in `WindowsSandboxManager`: this would add state around a design whose goal is per-command bulk native application, and it risks changing which ACL attempts and warnings happen for each sandbox invocation.
- Stop writing an empty `forbidden.txt` or `allowed.txt` when a set is empty: this would change the helper argument shape asserted by existing Windows sandbox tests and make the manifest protocol conditional.
- Merge the forbidden and allowed manifest files into one tagged manifest: this would change the `GeminiSandbox.exe` command-line contract and require coordinated test and helper parser changes, not a behavior-preserving refactor.
- Remove the secret-file scan from `prepareCommand`: it would reduce work, but it would weaken the goal's improved isolation by no longer adding discovered secrets to the forbidden manifest.
- Change `ApplyBulkAcls` to throw when a path ACL operation fails: this would change observable behavior from best-effort warning to sandbox preparation failure.
