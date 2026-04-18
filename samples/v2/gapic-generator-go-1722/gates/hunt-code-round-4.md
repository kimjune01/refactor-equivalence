## Allowed Edit Set: FAIL
Command: `cat /Users/junekim/Documents/refactor-equivalence/samples/v2/gapic-generator-go-1722/inputs/allowed-files.txt`
Exit code: 1
Tail 50 lines:

```text
cat: /Users/junekim/Documents/refactor-equivalence/samples/v2/gapic-generator-go-1722/inputs/allowed-files.txt: No such file or directory
```

Note: The cleanroom contains the same allowed edit list as `FORGE_ALLOWED_FILES.txt`, and the matching sample artifact exists under `v2-single-round/.../inputs/allowed-files.txt`; both list only files changed by the original artifact.

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
ok  	github.com/googleapis/gapic-generator-go/internal/gencli	0.198s
ok  	github.com/googleapis/gapic-generator-go/internal/gengapic	0.371s
ok  	github.com/googleapis/gapic-generator-go/internal/grpc_service_config	0.612s
?   	github.com/googleapis/gapic-generator-go/internal/license	[no test files]
ok  	github.com/googleapis/gapic-generator-go/internal/pbinfo	0.484s
?   	github.com/googleapis/gapic-generator-go/internal/printer	[no test files]
ok  	github.com/googleapis/gapic-generator-go/internal/snippets	0.743s
?   	github.com/googleapis/gapic-generator-go/internal/snippets/metadata	[no test files]
?   	github.com/googleapis/gapic-generator-go/internal/testing/sample	[no test files]
?   	github.com/googleapis/gapic-generator-go/internal/txtdiff	[no test files]
```

## Finding F1 — Vocabulary construction is still unconditional
**Severity**: warning
**File**: internal/gengapic/generator.go:108
**What**: Accepted claim C1 says the method scan and `buildHeuristicVocabulary(methods)` assignment should be wrapped in `if g.featureEnabled(DynamicResourceHeuristicsFeature) { ... }`, leaving `g.vocabulary` nil when the dynamic resource heuristic feature is disabled. The current source still scans every proto file and builds the vocabulary unconditionally:

```go
   108		var methods []*descriptorpb.MethodDescriptorProto
   109		for _, f := range req.GetProtoFile() {
   110			for _, s := range f.GetService() {
   111				methods = append(methods, s.GetMethod()...)
   112			}
   113		}
   114		g.vocabulary = buildHeuristicVocabulary(methods)
```

**Fix**: Wrap lines 108-114 in a `DynamicResourceHeuristicsFeature` feature check so the scan and assignment only happen when that feature is enabled.

## Finding F2 — Resource-name telemetry emission was not centralized
**Severity**: warning
**File**: internal/gengapic/gengapic.go:512
**What**: Accepted claim C2 says the duplicated `resTarget` formatting and emission body inside the existing gRPC and REST `OpenTelemetryAttributesFeature` branches should be extracted into one private helper. The current source still contains the duplicated body inline in both branches. In the gRPC branch:

```go
   512						var getters []string
   513						for _, f := range resTarget.FieldNames {
   514							getters = append(getters, fmt.Sprintf("req%s", fieldGetter(f)))
   515						}
   516						gettersStr := strings.Join(getters, ", ")
```

and in the REST branch:

```go
   548						var getters []string
   549						for _, f := range resTarget.FieldNames {
   550							getters = append(getters, fmt.Sprintf("req%s", fieldGetter(f)))
   551						}
   552						gettersStr := strings.Join(getters, ", ")
```

The duplicated emission/import block also remains in the REST branch:

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

**Fix**: Extract the shared formatting/emission/import logic into one private helper in `gengapic.go`, and call it from both transport branches only after `resourceNameField` returns a non-nil target inside the existing `OpenTelemetryAttributesFeature` guard.

## Finding F3 — `resourceNameField` documentation is still stale
**Severity**: warning
**File**: internal/gengapic/gengapic.go:906
**What**: Accepted claim C3 says the comment should describe the current `*heuristicTarget` return value, annotated-field preference, and dynamic HTTP-path inference when `DynamicResourceHeuristicsFeature` is enabled. The current comment still describes the old string-returning implementation and says it returns an empty string:

```go
   906	// resourceNameField returns the name of the field in the input message
   907	// that carries a google.api.resource_reference annotation.
   908	// If multiple fields match, it prioritizes the one that also appears in the HTTP path.
   909	// If no input type or associated attributes are found, it returns an empty string.
   910	func (g *generator) resourceNameField(m *descriptorpb.MethodDescriptorProto) *heuristicTarget {
```

**Fix**: Replace the comment with documentation for the `*heuristicTarget` result, annotation-first behavior, and dynamic heuristic fallback guarded by `DynamicResourceHeuristicsFeature`.

## Finding F4 — Tutorial-style heuristic comments remain
**Severity**: warning
**File**: internal/gengapic/heuristics.go:55
**What**: Accepted claim C4 says the long step-by-step comments in `buildHeuristicVocabulary` should be condensed to durable invariants. The current source still has tutorial-style step comments and explanatory prose:

```go
    55		// Step 2: Define "CRUD-like" patterns for vocabulary learning.
    56		// Why do we filter for CRUD? Non-CRUD methods (e.g., `CancelOperation`, `CheckHealth`)
    57		// often have path literals that are random verbs or actions, not resource collections.
    58		// If we learned from those, we might pollute our vocabulary with non-resource nouns.
```

and later:

```go
    78		// Step 3: Walk methods and learn valid resource collection nouns.
    79		// By "learn" and "valid", we mean finding standard verbs (Get, List, Create),
    80		// reading their paths (e.g., `/v1/projects/{project}/topics/{topic}`), and
    81		// extracting the static literal nouns that sit immediately before a `{variable}`
    82		// (`projects` and `topics`). We add these to our `resourceCollections` map so we can
    83		// validate unannotated field patterns later, in IdentifyHeuristicTarget.
```

**Fix**: Replace these with concise invariant comments covering the intended policy: learn only from CRUD-like method names, inspect all HTTP patterns, collect literals immediately before variables, strip literal custom verbs, and ignore version segments.
