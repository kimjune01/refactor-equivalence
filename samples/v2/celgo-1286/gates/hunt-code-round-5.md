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
ok  	github.com/google/cel-go/cel	0.440s
ok  	github.com/google/cel-go/checker	1.430s
?   	github.com/google/cel-go/checker/decls	[no test files]
ok  	github.com/google/cel-go/common	1.608s
ok  	github.com/google/cel-go/common/ast	1.193s
ok  	github.com/google/cel-go/common/containers	0.544s
?   	github.com/google/cel-go/common/debug	[no test files]
ok  	github.com/google/cel-go/common/decls	2.696s
ok  	github.com/google/cel-go/common/env	0.766s
?   	github.com/google/cel-go/common/functions	[no test files]
?   	github.com/google/cel-go/common/operators	[no test files]
?   	github.com/google/cel-go/common/overloads	[no test files]
ok  	github.com/google/cel-go/common/runes	0.950s
?   	github.com/google/cel-go/common/stdlib	[no test files]
ok  	github.com/google/cel-go/common/types	2.059s
ok  	github.com/google/cel-go/common/types/pb	2.488s
?   	github.com/google/cel-go/common/types/ref	[no test files]
?   	github.com/google/cel-go/common/types/traits	[no test files]
ok  	github.com/google/cel-go/examples	2.278s
ok  	github.com/google/cel-go/ext	1.964s
ok  	github.com/google/cel-go/interpreter	2.984s
?   	github.com/google/cel-go/interpreter/functions	[no test files]
ok  	github.com/google/cel-go/parser	3.166s
?   	github.com/google/cel-go/parser/gen	[no test files]
?   	github.com/google/cel-go/test	[no test files]
ok  	github.com/google/cel-go/test/bench	2.926s [no tests to run]
?   	github.com/google/cel-go/test/proto2pb	[no test files]
?   	github.com/google/cel-go/test/proto3pb	[no test files]
```

## Finding F1 — Exported `types.ProtoTypes` API was removed
**Severity**: blocker
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/1286/common/types/provider.go:113
**What**: The refactor renamed the exported `RegistryOption` constructor from `ProtoTypes` to `ProtoTypeDefs` without keeping a compatibility wrapper. That is an observable API break for users compiling against the C_test API shape, e.g. `types.NewProtoRegistry(types.ProtoTypes(msg))` no longer resolves. The current file only exposes the renamed symbol:

```go
// ProtoTypeDefs creates a RegistryOption which registers the individual proto messages with the registry.
func ProtoTypeDefs(types ...proto.Message) RegistryOption {
```

`rg -n "func ProtoTypes|ProtoTypes creates|ProtoTypeDefs" common/types/provider.go` returns only the `ProtoTypeDefs` definition and its call site, and `go doc github.com/google/cel-go/common/types ProtoTypes` reports `doc: no symbol ProtoTypes`.
**Fix**: Preserve the old exported API by restoring `ProtoTypes` or adding a backwards-compatible wrapper such as `func ProtoTypes(types ...proto.Message) RegistryOption { return ProtoTypeDefs(types...) }`.

## Finding F2 — `HasExtension` only checks the first extension
**Severity**: blocker
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/1286/common/ast/ast.go:442
**What**: The new runtime gate in `cel/program.go` depends on `SourceInfo.HasExtension("json_name", ...)`, but `HasExtension` returns from the first loop iteration regardless of whether that extension matches. Any AST whose source info has another extension before `json_name` will be treated as if it lacks the `json_name` runtime extension, so `Env.Program` can skip the required `cel.JSONFieldNames(true)` rejection. The current implementation shows the premature return:

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

**Fix**: Iterate through all extensions and continue on non-matching IDs; return true only when a matching extension satisfies the minimum version. Also avoid rejecting compatible higher-major versions just because their minor number is lower than the minimum minor.
