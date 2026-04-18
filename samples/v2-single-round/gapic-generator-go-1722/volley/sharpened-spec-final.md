## Accepted Claims

### C1 — Gate vocabulary construction behind the heuristic feature
**File**: internal/gengapic/generator.go:108
**Change**: Wrap the method scan and `buildHeuristicVocabulary(methods)` assignment in `if g.featureEnabled(DynamicResourceHeuristicsFeature) { ... }`, leaving `g.vocabulary` nil when the dynamic resource heuristic feature is disabled.
**Goal link**: The goal says fallback resource-name heuristics are gated behind `DynamicResourceHeuristicsFeature`.
**Justification**: This removes an unconditional API-wide scan from generator initialization when the feature cannot use the vocabulary, keeping the stored vocabulary tied to the feature path without changing generated output.

### C2 — Centralize resource-name telemetry emission
**File**: internal/gengapic/gengapic.go:501
**Change**: Extract only the duplicated `resTarget` formatting and emission body inside the existing gRPC and REST `OpenTelemetryAttributesFeature` branches of `insertRequestHeaders` into one private helper in `gengapic.go` that takes the method and `*heuristicTarget`, emits the runtime `gax.IsFeatureEnabled("TRACING") || gax.IsFeatureEnabled("LOGGING")` guard, builds the getter list, applies the default host prefix, escapes `%`, and records the `callctx` and `fmt` imports; keep the existing outer generator-time `if g.featureEnabled(OpenTelemetryAttributesFeature) { ... }` guard in both transport branches, and call this helper only inside that guard after `resourceNameField` returns a non-nil target.
**Goal link**: The goal adds one resource-name-template mechanism used by both transports.
**Justification**: A single emission path makes the new heuristic and annotated resource-name formatting rules easier to audit and removes first-pass duplication without altering the generated statements.
**Hunt note**: Retained as narrowed for F1 because the helper extraction is now explicitly limited to the duplicated body inside the existing `OpenTelemetryAttributesFeature` generator-time gate, preserving the current feature gating for resource-name telemetry code and imports.

### C3 — Correct the stale `resourceNameField` documentation
**File**: internal/gengapic/gengapic.go:906
**Change**: Rewrite the comment above `resourceNameField` to describe that it returns a `*heuristicTarget` containing a format string and request field names, that annotated `resource_reference` fields are preferred, and that dynamic HTTP-path inference is used only when no annotation exists and `DynamicResourceHeuristicsFeature` is enabled; remove the obsolete "returns an empty string" wording.
**Goal link**: The goal extends resource-name discovery from single annotated fields to dynamic URI-derived templates.
**Justification**: The current comment describes the old string-returning implementation, so updating it removes misleading documentation around the main goal-facing decision point without changing behavior.

### C4 — Replace tutorial-style comments in heuristic vocabulary construction
**File**: internal/gengapic/heuristics.go:78
**Change**: Condense the long step-by-step comments inside `buildHeuristicVocabulary` to short comments that state the durable invariants: learn only from CRUD-like method names, inspect all HTTP patterns, collect literals immediately before variables, strip literal custom verbs, and ignore version segments.
**Goal link**: The goal is to express fallback vocabulary learning for legacy services, not to preserve first-pass explanatory scaffolding.
**Justification**: Short invariant comments make the heuristic policy clearer and remove accidental tutorial prose while preserving the same scan and filtering logic.

## Rejected

- Change `identifyHeuristicTarget` to drop its unused `m *descriptorpb.MethodDescriptorProto` parameter or its never-used `error` return: this would require changing `internal/gengapic/heuristics_test.go`, and claims must not require edits to test files.
- Reuse `getHTTPPatterns` inside `parseImplicitRequestHeaders`: the helper recurses through nested `additional_bindings`, while `parseImplicitRequestHeaders` currently processes only the primary rule plus one binding level, so this could change observable routing-header generation.
- Convert heuristic vocabulary maps from `map[string]bool` to `map[string]struct{}`: the surrounding generator code commonly uses `map[string]bool`, and the existing heuristic tests compare exact `map[string]bool` values.
- Propose edits to generated `.want` files under `internal/gengapic/testdata`: those files are in the allowed edit set but are test fixtures, not source refactor targets for cleaner goal expression.
