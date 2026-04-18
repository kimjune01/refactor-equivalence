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
ok  	github.com/googleapis/gapic-generator-go/internal/gencli	0.253s
ok  	github.com/googleapis/gapic-generator-go/internal/gengapic	0.420s
ok  	github.com/googleapis/gapic-generator-go/internal/grpc_service_config	0.661s
?   	github.com/googleapis/gapic-generator-go/internal/license	[no test files]
ok  	github.com/googleapis/gapic-generator-go/internal/pbinfo	0.535s
?   	github.com/googleapis/gapic-generator-go/internal/printer	[no test files]
ok  	github.com/googleapis/gapic-generator-go/internal/snippets	0.795s
?   	github.com/googleapis/gapic-generator-go/internal/snippets/metadata	[no test files]
?   	github.com/googleapis/gapic-generator-go/internal/testing/sample	[no test files]
?   	github.com/googleapis/gapic-generator-go/internal/txtdiff	[no test files]
```

## Finding F1 — Vocabulary construction is still unconditional
**Severity**: warning
**File**: internal/gengapic/generator.go:108
**What**: The accepted feature-gating claim is not applied. The method scan and `buildHeuristicVocabulary(methods)` assignment still run for every generator, even when `DynamicResourceHeuristicsFeature` is disabled. Current source:

```go
   108		var methods []*descriptorpb.MethodDescriptorProto
   109		for _, f := range req.GetProtoFile() {
   110			for _, s := range f.GetService() {
   111				methods = append(methods, s.GetMethod()...)
   112			}
   113		}
   114		g.vocabulary = buildHeuristicVocabulary(methods)
```

**Fix**: Wrap lines 108-114 in `if g.featureEnabled(DynamicResourceHeuristicsFeature) { ... }` so the vocabulary remains nil and no scan is performed unless the heuristic feature is enabled.

## Finding F2 — Resource-name telemetry emission was not centralized
**Severity**: warning
**File**: internal/gengapic/gengapic.go:512
**What**: The accepted cleanup claim to extract duplicated resource-name telemetry emission into one helper is not applied. The gRPC branch still builds getters, host, escaped format, output lines, and imports inline:

```go
   512						var getters []string
   513						for _, f := range resTarget.FieldNames {
   514							getters = append(getters, fmt.Sprintf("req%s", fieldGetter(f)))
   515						}
   516						gettersStr := strings.Join(getters, ", ")
```

The REST branch repeats the same body:

```go
   548						var getters []string
   549						for _, f := range resTarget.FieldNames {
   550							getters = append(getters, fmt.Sprintf("req%s", fieldGetter(f)))
   551						}
   552						gettersStr := strings.Join(getters, ", ")
```

and repeats the emission/import block:

```go
   560						escapedFormat := strings.ReplaceAll(resTarget.Format, "%", "%%")
   561						if host != "" {
   562							p(`  ctx = callctx.WithTelemetryContext(ctx, "resource_name", fmt.Sprintf("//%s/`+escapedFormat+`", `+gettersStr+`))`, host)
   563						} else {
   564							p(`  ctx = callctx.WithTelemetryContext(ctx, "resource_name", fmt.Sprintf("` + escapedFormat + `", ` + gettersStr + `))`)
   565						}
   566						p("}")
   567						g.imports[pbinfo.ImportSpec{Path: "github.com/googleapis/gax-go/v2/callctx"}] = true
   568						g.imports[pbinfo.ImportSpec{Path: "fmt"}] = true
```

**Fix**: Add a private helper in `gengapic.go` for the shared `resource_name` telemetry formatting/emission/import logic and call it from both transport branches after `resourceNameField` returns a non-nil target.

## Finding F3 — `resourceNameField` documentation is still stale
**Severity**: warning
**File**: internal/gengapic/gengapic.go:906
**What**: The accepted documentation claim is not applied. The comment still describes the old string-returning behavior and says the function returns an empty string, but the function now returns `*heuristicTarget` and can infer a target from HTTP paths when `DynamicResourceHeuristicsFeature` is enabled. Current source:

```go
   906	// resourceNameField returns the name of the field in the input message
   907	// that carries a google.api.resource_reference annotation.
   908	// If multiple fields match, it prioritizes the one that also appears in the HTTP path.
   909	// If no input type or associated attributes are found, it returns an empty string.
   910	func (g *generator) resourceNameField(m *descriptorpb.MethodDescriptorProto) *heuristicTarget {
```

**Fix**: Update the comment to describe the `*heuristicTarget` return value, annotation-first behavior, HTTP path tie-breaking, nil result, and the dynamic heuristic fallback guarded by `DynamicResourceHeuristicsFeature`.

## Finding F4 — Tutorial-style heuristic comments remain
**Severity**: warning
**File**: internal/gengapic/heuristics.go:55
**What**: The accepted comment cleanup claim is not applied. `buildHeuristicVocabulary` still contains tutorial-style step comments and long explanatory prose instead of concise invariants. Current source:

```go
    55		// Step 2: Define "CRUD-like" patterns for vocabulary learning.
    56		// Why do we filter for CRUD? Non-CRUD methods (e.g., `CancelOperation`, `CheckHealth`)
    57		// often have path literals that are random verbs or actions, not resource collections.
    58		// If we learned from those, we might pollute our vocabulary with non-resource nouns.
```

and:

```go
    78		// Step 3: Walk methods and learn valid resource collection nouns.
    79		// By "learn" and "valid", we mean finding standard verbs (Get, List, Create),
    80		// reading their paths (e.g., `/v1/projects/{project}/topics/{topic}`), and
    81		// extracting the static literal nouns that sit immediately before a `{variable}`
    82		// (`projects` and `topics`). We add these to our `resourceCollections` map so we can
    83		// validate unannotated field patterns later, in IdentifyHeuristicTarget.
```

**Fix**: Replace the step-by-step prose with durable invariant comments: learn only from CRUD-like method names, inspect every HTTP pattern, collect only literals immediately before variables, strip literal custom verbs, and ignore version segments.
