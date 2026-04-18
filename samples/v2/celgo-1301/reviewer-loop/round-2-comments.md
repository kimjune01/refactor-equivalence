## Comment 1 — Remove local replace directive
**Severity**: approve-blocker
**File**: repl/go.mod:25
**Request**: Remove the `replace cel.dev/expr => ../../cel-spec` directive (and revert the associated changes in `repl/go.sum`).
**Why**: Local replace directives pointing to paths outside the repository break the build for other contributors and CI pipelines.
