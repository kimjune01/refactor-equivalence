## Comment 1 — Restore missing test files for redundantptr
**Severity**: approve-blocker
**File**: tools/redundantptr/redundantptr.go:1
**Request**: Please also restore the `testdata` directory for this linter (specifically `testdata/src/has-warnings/github.go` and `testdata/src/no-warnings/github.go`).
**Why**: The original PR accidentally deleted the `redundantptr` linter along with its tests; while you correctly restored its `go.mod` and `.go` source, the `testdata` directory was missed, which is necessary for the linter's tests to function.
