## Build: PASS
## Tests: PASS

## Finding F1 — JSONFieldNames(true) rejects checked proto-name field access
**Severity**: blocker
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/1286/checker/checker.go:725
**What**: The goal is to support JSON or proto-based field name accesses when `JSONFieldNames(true)` is enabled, but checked object selects still reject proto `snake_case` names. A public API repro compiling `msg.single_int32 == 1` against `TestAllTypes` with `cel.JSONFieldNames(true)` fails with `undefined field 'single_int32'`. The current checker emits an undefined-field error whenever JSON field names are enabled and the resolved field is not marked as JSON:

```go
	if ft, found := c.env.provider.FindStructFieldType(structType, fieldName); found {
		if c.env.jsonFieldNames && !ft.IsJSONField {
			c.errors.undefinedField(exprID, c.locationByID(exprID), fieldName)
		}
		return ft.Type, found
	}
```

The registry does allow proto-name fallback first, but marks that fallback as not JSON, which triggers the checker error:

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

This makes `cel.JSONFieldNames(true)` support JSON names or dynamic proto fallback, but not checked proto-name field access, which is a behavior/spec miss.
**Fix**: Remove the checker-side rejection of non-JSON fields when `JSONFieldNames(true)` is enabled, or otherwise distinguish actual invalid fields from valid proto-name fallback. Add a test for a checked expression such as `msg.single_int32 == 1` with `JSONFieldNames(true)`.

## Command Evidence

Required command:

```text
cat /Users/junekim/Documents/refactor-equivalence/samples/v2/celgo-1286/inputs/allowed-files.txt
exit code: 1
tail:
cat: /Users/junekim/Documents/refactor-equivalence/samples/v2/celgo-1286/inputs/allowed-files.txt: No such file or directory
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
ok  	github.com/google/cel-go/cel	0.385s
ok  	github.com/google/cel-go/checker	1.831s
?   	github.com/google/cel-go/checker/decls	[no test files]
ok  	github.com/google/cel-go/common	2.010s
ok  	github.com/google/cel-go/common/ast	1.172s
ok  	github.com/google/cel-go/common/containers	0.936s
?   	github.com/google/cel-go/common/debug	[no test files]
ok  	github.com/google/cel-go/common/decls	2.743s
ok  	github.com/google/cel-go/common/env	0.501s
?   	github.com/google/cel-go/common/functions	[no test files]
?   	github.com/google/cel-go/common/operators	[no test files]
?   	github.com/google/cel-go/common/overloads	[no test files]
ok  	github.com/google/cel-go/common/runes	1.568s
?   	github.com/google/cel-go/common/stdlib	[no test files]
ok  	github.com/google/cel-go/common/types	2.532s
ok  	github.com/google/cel-go/common/types/pb	3.181s
?   	github.com/google/cel-go/common/types/ref	[no test files]
?   	github.com/google/cel-go/common/types/traits	[no test files]
ok  	github.com/google/cel-go/examples	0.728s
ok  	github.com/google/cel-go/ext	3.101s
ok  	github.com/google/cel-go/interpreter	2.295s
?   	github.com/google/cel-go/interpreter/functions	[no test files]
ok  	github.com/google/cel-go/parser	1.424s
?   	github.com/google/cel-go/parser/gen	[no test files]
?   	github.com/google/cel-go/test	[no test files]
ok  	github.com/google/cel-go/test/bench	3.027s [no tests to run]
?   	github.com/google/cel-go/test/proto2pb	[no test files]
?   	github.com/google/cel-go/test/proto3pb	[no test files]
```
