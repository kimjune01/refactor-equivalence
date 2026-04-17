## Build: PASS
Command: `go build ./...`
Exit code: 0
Tail 50 lines:
```text
```

## Tests: PASS
Command: `go test ./... -count=1 -short`
Exit code: 0
Tail 50 lines:
```text
?   	github.com/googleapis/gapic-generator-go/cmd/protoc-gen-go_cli	[no test files]
?   	github.com/googleapis/gapic-generator-go/cmd/protoc-gen-go_gapic	[no test files]
?   	github.com/googleapis/gapic-generator-go/internal	[no test files]
ok  	github.com/googleapis/gapic-generator-go/internal/gencli	0.209s
ok  	github.com/googleapis/gapic-generator-go/internal/gengapic	0.366s
ok  	github.com/googleapis/gapic-generator-go/internal/grpc_service_config	0.642s
?   	github.com/googleapis/gapic-generator-go/internal/license	[no test files]
ok  	github.com/googleapis/gapic-generator-go/internal/pbinfo	0.472s
?   	github.com/googleapis/gapic-generator-go/internal/printer	[no test files]
ok  	github.com/googleapis/gapic-generator-go/internal/snippets	0.784s
?   	github.com/googleapis/gapic-generator-go/internal/snippets/metadata	[no test files]
?   	github.com/googleapis/gapic-generator-go/internal/testing/sample	[no test files]
?   	github.com/googleapis/gapic-generator-go/internal/txtdiff	[no test files]
```

## Finding F1 — Vocabulary construction is still unconditional
**Severity**: warning
**File**: internal/gengapic/generator.go:108
**What**: Accepted claim C1 was not applied. The generator still scans every method and builds the heuristic vocabulary unconditionally, even when `DynamicResourceHeuristicsFeature` is disabled. Current lines:
```go
   108		var methods []*descriptorpb.MethodDescriptorProto
   109		for _, f := range req.GetProtoFile() {
   110			for _, s := range f.GetService() {
   111				methods = append(methods, s.GetMethod()...)
   112			}
   113		}
   114		g.vocabulary = buildHeuristicVocabulary(methods)
```
**Fix**: Wrap the method scan and `g.vocabulary = buildHeuristicVocabulary(methods)` assignment in `if g.featureEnabled(DynamicResourceHeuristicsFeature) { ... }`, leaving `g.vocabulary` nil when the feature is disabled.

## Finding F2 — Resource-name telemetry emission remains duplicated
**Severity**: warning
**File**: internal/gengapic/gengapic.go:501
**What**: Accepted claim C2 was not applied. The gRPC and REST branches still contain separate copies of the resource-name telemetry emission body instead of calling a shared helper from inside the existing `OpenTelemetryAttributesFeature` guards. Current gRPC lines:
```go
   501				if g.featureEnabled(OpenTelemetryAttributesFeature) {
   502					resTarget := g.resourceNameField(m)
   503					if resTarget != nil {
   504						p("if gax.IsFeatureEnabled(\"TRACING\") || gax.IsFeatureEnabled(\"LOGGING\") {")
   505	
   506						// For Standard APIs (AIP-122 compliant), for both gRPC and HTTP transports,
   507						// the expression fieldGetter(resField) returns an accessor for the full
   508						// canonical resource name (e.g., "projects/p/secrets/s"). For non-compliant
   509						// APIs (missing the resource_reference annotation), an empty string is returned.
   510	
   511						// Prepend the service host if available
   512						var getters []string
   513						for _, f := range resTarget.FieldNames {
   514							getters = append(getters, fmt.Sprintf("req%s", fieldGetter(f)))
   515						}
```
Current REST lines:
```go
   539				if g.featureEnabled(OpenTelemetryAttributesFeature) {
   540					resTarget := g.resourceNameField(m)
   541					if resTarget != nil {
   542						p("if gax.IsFeatureEnabled(\"TRACING\") || gax.IsFeatureEnabled(\"LOGGING\") {")
   543						// For Standard APIs (AIP-122 compliant), for both gRPC and HTTP transports,
   544						// the expression fieldGetter(resField) returns an accessor for the full
   545						// canonical resource name (e.g., "projects/p/secrets/s"). For non-compliant
   546						// APIs (missing the resource_reference annotation), an empty string is returned.
   547	
   548						var getters []string
   549						for _, f := range resTarget.FieldNames {
   550							getters = append(getters, fmt.Sprintf("req%s", fieldGetter(f)))
   551						}
```
**Fix**: Extract the duplicated `resTarget` formatting/emission body into one private helper in `gengapic.go`, keep both outer generator-time `OpenTelemetryAttributesFeature` guards, and call the helper only after `resourceNameField` returns a non-nil target.

## Finding F3 — `resourceNameField` documentation is still stale
**Severity**: warning
**File**: internal/gengapic/gengapic.go:906
**What**: Accepted claim C3 was not applied. The comment still describes the old string-returning implementation and says the function returns an empty string, but the function now returns `*heuristicTarget` or nil and can infer dynamic HTTP-path targets. Current lines:
```go
   906	// resourceNameField returns the name of the field in the input message
   907	// that carries a google.api.resource_reference annotation.
   908	// If multiple fields match, it prioritizes the one that also appears in the HTTP path.
   909	// If no input type or associated attributes are found, it returns an empty string.
   910	func (g *generator) resourceNameField(m *descriptorpb.MethodDescriptorProto) *heuristicTarget {
```
**Fix**: Rewrite the comment to describe returning a `*heuristicTarget`, preferring annotated `resource_reference` fields, and falling back to dynamic HTTP-path inference only when no annotation exists and `DynamicResourceHeuristicsFeature` is enabled.

## Finding F4 — Heuristic vocabulary construction still has tutorial comments
**Severity**: warning
**File**: internal/gengapic/heuristics.go:48
**What**: Accepted claim C4 was not applied. `buildHeuristicVocabulary` still contains step-by-step tutorial comments rather than short invariant comments. Current lines:
```go
    48		// Step 1: Seed standard infrastructure resource collections.
    49		resourceCollections["projects"] = true
    50		resourceCollections["locations"] = true
    51		resourceCollections["folders"] = true
    52		resourceCollections["organizations"] = true
    53		resourceCollections["billingAccounts"] = true
    54	
    55		// Step 2: Define "CRUD-like" patterns for vocabulary learning.
    56		// Why do we filter for CRUD? Non-CRUD methods (e.g., `CancelOperation`, `CheckHealth`)
    57		// often have path literals that are random verbs or actions, not resource collections.
    58		// If we learned from those, we might pollute our vocabulary with non-resource nouns.
```
Additional current lines:
```go
    78		// Step 3: Walk methods and learn valid resource collection nouns.
    79		// By "learn" and "valid", we mean finding standard verbs (Get, List, Create),
    80		// reading their paths (e.g., `/v1/projects/{project}/topics/{topic}`), and
    81		// extracting the static literal nouns that sit immediately before a `{variable}`
    82		// (`projects` and `topics`). We add these to our `resourceCollections` map so we can
    83		// validate unannotated field patterns later, in IdentifyHeuristicTarget.
```
**Fix**: Condense the comments inside `buildHeuristicVocabulary` to durable invariants: learn only from CRUD-like method names, inspect all HTTP patterns, collect literals immediately before variables, strip literal custom verbs, and ignore version segments.
