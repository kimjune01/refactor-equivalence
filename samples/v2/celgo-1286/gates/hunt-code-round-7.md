## Build: PASS
## Tests: PASS

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

## Command Evidence

Required allowed-file command:

```text
cat /Users/junekim/Documents/refactor-equivalence/samples/v2/celgo-1286/inputs/allowed-files.txt
exit code: 1
tail:
cat: /Users/junekim/Documents/refactor-equivalence/samples/v2/celgo-1286/inputs/allowed-files.txt: No such file or directory
```

Local allowed-file artifact used for review context:

```text
cat FORGE_ALLOWED_FILES.txt
exit code: 0
tail:
cel/env.go
cel/options.go
cel/program.go
common/ast/ast.go
common/types/provider.go
```

Build command:

```text
go build ./...
exit code: 0
tail:
<no output>
```

Test command:

```text
go test ./... -count=1 -short
exit code: 0
tail:
ok  	github.com/google/cel-go/cel	1.691s
ok  	github.com/google/cel-go/checker	1.191s
?   	github.com/google/cel-go/checker/decls	[no test files]
ok  	github.com/google/cel-go/common	0.241s
ok  	github.com/google/cel-go/common/ast	2.080s
ok  	github.com/google/cel-go/common/containers	0.751s
?   	github.com/google/cel-go/common/debug	[no test files]
ok  	github.com/google/cel-go/common/decls	1.023s
ok  	github.com/google/cel-go/common/env	0.893s
?   	github.com/google/cel-go/common/functions	[no test files]
?   	github.com/google/cel-go/common/operators	[no test files]
?   	github.com/google/cel-go/common/overloads	[no test files]
ok  	github.com/google/cel-go/common/runes	0.346s
?   	github.com/google/cel-go/common/stdlib	[no test files]
ok  	github.com/google/cel-go/common/types	1.774s
ok  	github.com/google/cel-go/common/types/pb	1.444s
?   	github.com/google/cel-go/common/types/ref	[no test files]
?   	github.com/google/cel-go/common/types/traits	[no test files]
ok  	github.com/google/cel-go/examples	1.916s
ok  	github.com/google/cel-go/ext	0.615s
ok  	github.com/google/cel-go/interpreter	1.364s
?   	github.com/google/cel-go/interpreter/functions	[no test files]
ok  	github.com/google/cel-go/parser	2.239s
?   	github.com/google/cel-go/parser/gen	[no test files]
?   	github.com/google/cel-go/test	[no test files]
ok  	github.com/google/cel-go/test/bench	2.124s [no tests to run]
?   	github.com/google/cel-go/test/proto2pb	[no test files]
?   	github.com/google/cel-go/test/proto3pb	[no test files]
```
