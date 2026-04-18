## Accepted Claims

### C1 — Use read-only AST traversal for diagnostics
**File**: tools/redundantptr/redundantptr.go:73
**Change**: In `analyzeFunction`, replace the `astutil.Apply` traversal with `ast.Inspect`, inspect `*ast.CallExpr` nodes directly, and remove the now-unused `golang.org/x/tools/go/ast/astutil` import.
**Goal link**: The goal is to detect redundant `github.Ptr(x)` calls, not rewrite the tree in memory.
**Justification**: Using `ast.Inspect` expresses the linter as a read-only diagnostic pass and removes an unnecessary rewrite-capable traversal without changing the reported diagnostics or suggested fixes.

### C2 — Narrow deprecated-wrapper skip helper to function declarations
**File**: tools/redundantptr/redundantptr.go:223
**Change**: Change `shouldIgnoreDeprecatedPtrWrapper` to accept `*ast.FuncDecl` instead of `ast.Node`, and call it only from the `*ast.FuncDecl` path before analyzing that function body.
**Goal link**: The skip exists only to avoid reporting inside deprecated top-level pointer wrapper declarations while still detecting redundant pointer calls in ordinary functions and function literals.
**Justification**: Removing the generic `ast.Node` parameter and internal type assertion makes the one special-case boundary explicit while preserving the current behavior for `FuncDecl` and `FuncLit` analysis.

## Rejected

- Remove unqualified `Ptr(x)` detection from `redundantPtrCall`: the goal text names `github.Ptr(x)`, but the current testdata expects unqualified `Ptr(i)` and `Ptr(opts.Mode)` warnings, so this would change observable linter behavior under the existing suite.
- Add type information so the linter proves that `github.Ptr` resolves to `github.com/google/go-github/v84/github.Ptr`: this would require changing the load mode away from the surrounding custom linters' syntax-only pattern and would expand implementation scope rather than simplify the first-pass artifact.
- Track locals in lexical order instead of pre-collecting all locals in `collectLocals`: this may improve precision for shadowing edge cases, but it would change which diagnostics are emitted and is not a behavior-preserving refactor.
- Replace remaining literal `github.Ptr("...")` calls in examples, docs, or tests by introducing local temporaries: those calls are not directly replaceable with `&x`, often rely on non-addressable literals, and many candidate files are outside the allowed edit set or are test files.
- Reformat `tools/redundantptr/testdata/src/has-warnings/main.go` to use a single-line import: this is cosmetic testdata churn and conflicts with the instruction to avoid claims against test files.
