## Build: PASS
## Tests: PASS

## Finding F1 — JSONFieldNames(true) still rejects checked proto-name field access
**Severity**: blocker
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/1286/checker/checker.go:725
**What**: The goal is to support JSON or proto-based field name accesses when `JSONFieldNames(true)` is enabled, but checked proto-name field access is still rejected. The current checker records `undefined field` whenever JSON field names are enabled and the resolved field is not marked as a JSON field:

```go
	if ft, found := c.env.provider.FindStructFieldType(structType, fieldName); found {
		if c.env.jsonFieldNames && !ft.IsJSONField {
			c.errors.undefinedField(exprID, c.locationByID(exprID), fieldName)
		}
		return ft.Type, found
	}
```

The registry still resolves proto field names through `FieldByName`, but marks only JSON-name matches as JSON fields:

```go
	field, found := msgType.FieldByName(fieldName)
	if !found {
		return nil, false
	}
	return &FieldType{
		Type:        fieldDescToCELType(field),
		IsSet:       field.IsSet,
		GetFrom:     field.GetFrom,
		IsJSONField: p.pbdb.JSONFieldNames() && fieldName == field.JSONName(),
	}, true
```

And `FieldByName` checks the proto-name map before the JSON-name map:

```go
	fd, found := td.fieldMap[name]
	if found {
		return fd, true
	}
```

So a checked expression such as `msg.single_int32 == 1` against a registered proto message with `cel.JSONFieldNames(true)` is found as the proto field, then reported as undefined because `single_int32 != singleInt32`.
**Fix**: Remove the checker-side rejection of provider-resolved non-JSON fields, or otherwise distinguish valid proto-name fallback from genuinely unresolved fields. Keep the existing `undefinedField` path only when `FindStructFieldType` does not resolve the field.

## Finding F2 — Accepted claim C2 was not applied
**Severity**: warning
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/1286/common/types/provider.go:108
**What**: C2 requires simplifying the `JSONFieldNames(enabled bool) RegistryOption` closure to return `r, r.WithJSONFieldNames(enabled)` directly. The current code still uses a temporary `err` variable:

```go
func JSONFieldNames(enabled bool) RegistryOption {
	return func(r *Registry) (*Registry, error) {
		err := r.WithJSONFieldNames(enabled)
		return r, err
	}
}
```

**Fix**: Change the closure body to `return r, r.WithJSONFieldNames(enabled)`.

## Finding F3 — Accepted claim C3 was not applied
**Severity**: warning
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/1286/cel/env.go:857
**What**: C3 requires using idiomatic inline error handling for registry reconfiguration. The current code still uses a separate assignment and follow-up check:

```go
		err := reg.WithJSONFieldNames(true)
		if err != nil {
			return nil, err
		}
```

**Fix**: Replace it with `if err := reg.WithJSONFieldNames(true); err != nil { return nil, err }`.

## Finding F4 — Accepted claim C4 was not applied
**Severity**: warning
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/1286/cel/program.go:227
**What**: C4 requires replacing or deleting the stale provider-configuration comment after `json_name` validation. The current code still has the stale comment:

```go
		// Configure the type provider, considering whether the AST indicates whether it supports JSON field names
```

**Fix**: Delete this comment or replace it with a comment describing attribute-factory selection.

## Finding F5 — Accepted claim C5 was not applied
**Severity**: warning
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/1286/cel/options.go:437
**What**: C5 requires aligning the `JSONFieldNames` EnvOption documentation with the implementation. The current comment still says the option creates a copy of the registry and infers JSON/proto support from AST extension metadata:

```go
// JSONFieldNames supports accessing protocol buffer fields by json-name.
//
// Enabling JSON field name support will create a copy of the types.Registry with fields indexed
// by JSON name, and whether JSON name or Proto-style names are supported will be inferred from
// the AST extensions metadata.
```

**Fix**: Rewrite the comment to state that the option enables protobuf field access by JSON names for environments backed by `*types.Registry`.

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
ok  	github.com/google/cel-go/cel	0.808s
ok  	github.com/google/cel-go/checker	0.955s
?   	github.com/google/cel-go/checker/decls	[no test files]
ok  	github.com/google/cel-go/common	0.271s
ok  	github.com/google/cel-go/common/ast	1.179s
ok  	github.com/google/cel-go/common/containers	2.032s
?   	github.com/google/cel-go/common/debug	[no test files]
ok  	github.com/google/cel-go/common/decls	0.483s
ok  	github.com/google/cel-go/common/env	3.089s
?   	github.com/google/cel-go/common/functions	[no test files]
?   	github.com/google/cel-go/common/operators	[no test files]
?   	github.com/google/cel-go/common/overloads	[no test files]
ok  	github.com/google/cel-go/common/runes	2.426s
?   	github.com/google/cel-go/common/stdlib	[no test files]
ok  	github.com/google/cel-go/common/types	1.609s
ok  	github.com/google/cel-go/common/types/pb	1.381s
?   	github.com/google/cel-go/common/types/ref	[no test files]
?   	github.com/google/cel-go/common/types/traits	[no test files]
ok  	github.com/google/cel-go/examples	1.823s
ok  	github.com/google/cel-go/ext	3.006s
ok  	github.com/google/cel-go/interpreter	2.313s
?   	github.com/google/cel-go/interpreter/functions	[no test files]
ok  	github.com/google/cel-go/parser	3.363s
?   	github.com/google/cel-go/parser/gen	[no test files]
?   	github.com/google/cel-go/test	[no test files]
ok  	github.com/google/cel-go/test/bench	3.303s [no tests to run]
?   	github.com/google/cel-go/test/proto2pb	[no test files]
?   	github.com/google/cel-go/test/proto3pb	[no test files]
```
