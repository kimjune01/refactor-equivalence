## Accepted Claims

### C1 — Restore Score experimental warning
**File**: firestore/pipeline_function.go:1005
**Change**: Add the same two-line Firestore Pipelines experimental warning used on `DocumentMatches` and `GeoDistance` to the `Score` function doc comment immediately before `func Score() Expression`.
**Goal link**: The goal explicitly lists `Score` among the features that must retain or restore the full experimental warning.
**Justification**: Restoring the warning makes the documentation match the stated Public Preview boundary while keeping the change doc-only and behavior-preserving.

## Rejected

- Re-add the general Firestore Pipelines experimental warning to all pipeline APIs that lost it: contradicts the goal, which says most pipeline-related APIs are moving out of preview and should no longer carry the general warning.
- Change `vertexai/internal/version.go` back from `0.18.0` to `0.19.0`: unrelated to the Firestore pipeline documentation goal and potentially observable through generated client headers, so it is not a behavior-preserving refactor claim.
- Add an experimental warning to `RawOptions` in `firestore/pipeline.go`: although `RawOptions` implements `SearchOption`, `UpdateOption`, and `DeleteOption`, it also applies to many non-preview pipeline stages, so marking it experimental would overstate the goal's targeted preview boundary.
- Add doc comments or experimental warnings to private `funcSearchOption`, `funcUpdateOption`, and their constructors in `firestore/pipeline.go`: these are unexported implementation details, and the exported option factories already carry the retained warnings requested by the goal.
- Remove the experimental warning from `(*baseExpression).GeoDistance` in `firestore/pipeline_expression.go`: the goal specifically calls out the `GeoDistance` method in both the interface and implementation as still requiring the warning.
