## Comment 1 — Restore explanatory comments for heuristics
**Severity**: nice-to-have
**File**: internal/gengapic/heuristics.go:45
**Request**: Please restore the detailed explanatory comments (e.g., explaining why we filter for CRUD, the trace example for regex matches, and why we discard verbs) that were removed from `buildHeuristicVocabulary`.
**Why**: The heuristic logic is non-obvious and relies on specific structural assumptions about HTTP paths; stripping the comments removes the "why" and makes the code harder to maintain for future developers.

## Comment 2 — Preserve context for telemetry extraction
**Severity**: nice-to-have
**File**: internal/gengapic/gengapic.go:532
**Request**: Move the explanatory comments regarding AIP-122 compliance and `fieldGetter` behavior (which were deleted from `insertRequestHeaders`) into the new `emitResourceNameTelemetry` helper.
**Why**: These comments provide important context about what the generated telemetry code is doing and how it handles both compliant and non-compliant APIs.

## Comment 3 — Add docstring to helper function
**Severity**: optional
**File**: internal/gengapic/gengapic.go:532
**Request**: Add a brief docstring to the new `emitResourceNameTelemetry` method.
**Why**: It is standard practice to document extracted helper methods to clarify their purpose and inputs.