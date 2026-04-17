# Implementation Summary

## Files modified

- `tools/redundantptr/redundantptr.go`

## Claims applied

### C1 — Use read-only AST traversal for diagnostics
- Replaced `astutil.Apply` with `ast.Inspect` in `analyzeFunction` (line 68).
- Removed the `golang.org/x/tools/go/ast/astutil` import (line 17).
- The traversal callback now receives `ast.Node` directly instead of going through `*astutil.Cursor`.

### C2 — Narrow deprecated-wrapper skip helper to function declarations
- Changed `shouldIgnoreDeprecatedPtrWrapper` signature from `ast.Node` to `*ast.FuncDecl` (line 218), removing the internal type assertion.
- Moved the call from inside `analyzeFunction` to the `*ast.FuncDecl` branch in `run()` (line 52), so it is only invoked for top-level function declarations.
