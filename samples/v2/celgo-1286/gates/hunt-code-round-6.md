## Build: PASS
`go build ./...` exit code: 0

Tail 50 lines:
```text
<no output>
```

## Tests: PASS
`go test ./... -count=1 -short` exit code: 0

Tail 50 lines:
```text
ok  	github.com/google/cel-go/cel	0.426s
ok  	github.com/google/cel-go/checker	0.521s
?   	github.com/google/cel-go/checker/decls	[no test files]
ok  	github.com/google/cel-go/common	0.185s
ok  	github.com/google/cel-go/common/ast	0.794s
ok  	github.com/google/cel-go/common/containers	1.486s
?   	github.com/google/cel-go/common/debug	[no test files]
ok  	github.com/google/cel-go/common/decls	1.914s
ok  	github.com/google/cel-go/common/env	1.031s
?   	github.com/google/cel-go/common/functions	[no test files]
?   	github.com/google/cel-go/common/operators	[no test files]
?   	github.com/google/cel-go/common/overloads	[no test files]
ok  	github.com/google/cel-go/common/runes	0.894s
?   	github.com/google/cel-go/common/stdlib	[no test files]
ok  	github.com/google/cel-go/common/types	1.333s
ok  	github.com/google/cel-go/common/types/pb	0.637s
?   	github.com/google/cel-go/common/types/ref	[no test files]
?   	github.com/google/cel-go/common/types/traits	[no test files]
ok  	github.com/google/cel-go/examples	1.636s
ok  	github.com/google/cel-go/ext	1.290s
ok  	github.com/google/cel-go/interpreter	1.831s
?   	github.com/google/cel-go/interpreter/functions	[no test files]
ok  	github.com/google/cel-go/parser	2.026s
?   	github.com/google/cel-go/parser/gen	[no test files]
?   	github.com/google/cel-go/test	[no test files]
ok  	github.com/google/cel-go/test/bench	2.020s [no tests to run]
?   	github.com/google/cel-go/test/proto2pb	[no test files]
?   	github.com/google/cel-go/test/proto3pb	[no test files]
```

## Finding F1 — Exported `types.ProtoTypes` API was removed
**Severity**: blocker
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/1286/common/types/provider.go:113
**What**: The refactor renamed the exported `RegistryOption` constructor from `ProtoTypes` to `ProtoTypeDefs` without keeping a compatibility wrapper. That is an observable API-shape break for users compiling against the C_test API, for example `types.NewProtoRegistry(types.ProtoTypes(msg))`. `go doc github.com/google/cel-go/common/types ProtoTypes` now reports `doc: no symbol ProtoTypes`. The current file only exposes the renamed symbol:

```go
// ProtoTypeDefs creates a RegistryOption which registers the individual proto messages with the registry.
func ProtoTypeDefs(types ...proto.Message) RegistryOption {
```

**Fix**: Preserve the old exported API by restoring `ProtoTypes` or adding a backwards-compatible wrapper such as `func ProtoTypes(types ...proto.Message) RegistryOption { return ProtoTypeDefs(types...) }`.

## Finding F2 — `HasExtension` only checks the first extension
**Severity**: blocker
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/1286/common/ast/ast.go:442
**What**: The new runtime gate in `cel/program.go` depends on `SourceInfo.HasExtension("json_name", ...)`, but `HasExtension` returns from the first loop iteration even when that extension does not match. Any AST whose source info has another extension before `json_name` will be treated as if it lacks the `json_name` runtime extension, so `Env.Program` can skip the required `cel.JSONFieldNames(true)` rejection. The current implementation shows the premature return:

```go
func (s *SourceInfo) HasExtension(id string, minVersion ExtensionVersion) bool {
	for _, ext := range s.Extensions() {
		return ext.ID == id && ext.Version.Major >= minVersion.Major && ext.Version.Minor >= minVersion.Minor
	}
	return false
}
```

The runtime gate that relies on this helper is:

```go
if a.SourceInfo().HasExtension("json_name", ast.NewExtensionVersion(1, 1)) {
	if !e.HasFeature(featureJSONFieldNames) {
		return nil, errors.New("the AST extension 'json_name' requires the option cel.JSONFieldNames(true)")
	}
}
```

**Fix**: Iterate through all extensions and continue on non-matching IDs; return true only when a matching extension satisfies the minimum version. The version comparison should also treat a higher major version as satisfying the minimum without requiring its minor version to be greater than or equal to the requested minor.
