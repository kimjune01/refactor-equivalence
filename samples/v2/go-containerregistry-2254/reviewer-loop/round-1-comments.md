## Comment 1 — Revert manual changes to vendored file
**Severity**: approve-blocker
**File**: vendor/github.com/moby/moby/client/request.go:322
**Request**: Revert the manual edits made to this file.
**Why**: Direct modifications to files in the `vendor/` directory violate Go modules conventions as they will be lost the next time `go mod vendor` is executed, and this specific change introduces a bug by unconditionally overwriting request-specific User-Agent headers.
