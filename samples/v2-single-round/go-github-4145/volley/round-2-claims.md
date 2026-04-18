## Accepted Claims

### C1 — Use plain AST inspection for read-only traversal
**File**: tools/redundantptr/redundantptr.go:17
**Change**: In `analyzeFunction`, replace the `astutil.Apply(body, pre, nil)` traversal with `ast.Inspect(body, func(n ast.Node) bool { ... })`, inspect `*ast.CallExpr` directly from `n`, and remove the now-unused `golang.org/x/tools/go/ast/astutil` import.
**Goal link**: The goal is to add a linter for replacing redundant `github.Ptr(x)` calls; this traversal only detects call expressions and never rewrites the AST.
**Justification**: Using `ast.Inspect` matches the surrounding custom linter idiom and removes an unnecessary rewrite-capable dependency without changing which diagnostics or suggested fixes are emitted.

## Rejected

- Remove the `*ast.Ident` branch in `redundantPtrCall` so only selector calls named `github.Ptr` are reported: this would better match the PR wording but would change current analyzer behavior and make existing `tools/redundantptr` testdata expectations fail unless test files were edited, which is outside the allowed claim scope.
- Change `collectLocals` to avoid collecting declarations inside nested function literals while analyzing an outer function: this would alter which calls can be reported in closure-heavy code and is a behavioral change rather than a bounded behavior-preserving refactor.
- Replace remaining literal calls such as `github.Ptr("blob")`, `github.Ptr("100644")`, `github.Ptr(false)`, or `github.Ptr(true)` in `example/commitpr/main.go`: those arguments are not addressable locals, so converting them would require introducing new variables and would go beyond the linter goal of replacing calls that can be directly expressed as `&x`.
- Collapse duplicated linter descriptions between `.golangci.yml`, `.custom-gcl.yml`, and `BuildAnalyzers`: these files serve different tool configuration surfaces and there is no existing shared source of truth in the repository, so centralizing them would add process coupling outside the PR's goal.
