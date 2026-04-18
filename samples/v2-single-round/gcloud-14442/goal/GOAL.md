# PR #14442 — chore(firestore): update experimental warnings for pipeline features

## PR body

This PR updates the documentation for Firestore Pipeline features in the Go SDK regarding their experimental status.
I have removed the general "Experimental" warning from most pipeline-related APIs that are moving out of preview. However, I have retained or restored the full experimental warning for specific features that are still in Public Preview and subject to breaking changes.
**Features retaining/restoring experimental warning:**
- `Search`, `Update`, and `Delete` pipeline stages in `pipeline.go`.
- `SearchOption`, `UpdateOption`, and `DeleteOption` interfaces and their implementations in `pipeline.go`.
- `DocumentMatches` and `GeoDistance` functions in `pipeline_function.go`.
- `GeoDistance` method in `pipeline_expression.go` (both interface and implementation).
- `Score`
