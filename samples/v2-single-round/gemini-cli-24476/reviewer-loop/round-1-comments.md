## Comment 1 — PowerShell function swallows double-dash argument
**Severity**: approve-blocker
**File**: .github/workflows/ci.yml:431
**Request**: Remove the `Invoke-NpmOrExit` wrapper and inline the `npm` calls with their exit checks, or rewrite the helper to ensure the `--` argument is preserved and passed to `npm`.
**Why**: PowerShell's parameter binder consumes the `--` token (which signals the end of parameters), meaning it will not be included in `$args` when splatted to `npm`, which breaks the explicit argument forwarding (`--coverage.enabled=false`) to the underlying test runner.
