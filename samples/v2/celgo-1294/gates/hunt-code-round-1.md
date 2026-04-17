## Build: PASS
## Tests: FAIL

Build command: `go build ./...`
Build exit code: 0
Build tail 50 lines:

```text
<no output>
```

Test command: `go test ./... -count=1 -short`
Test exit code: 1
Test tail 50 lines:

```text
ok  	github.com/google/cel-go/cel	0.684s
ok  	github.com/google/cel-go/checker	2.665s
?   	github.com/google/cel-go/checker/decls	[no test files]
ok  	github.com/google/cel-go/common	1.039s
ok  	github.com/google/cel-go/common/ast	2.141s
ok  	github.com/google/cel-go/common/containers	2.925s
?   	github.com/google/cel-go/common/debug	[no test files]
ok  	github.com/google/cel-go/common/decls	1.888s
ok  	github.com/google/cel-go/common/env	1.678s
?   	github.com/google/cel-go/common/functions	[no test files]
?   	github.com/google/cel-go/common/operators	[no test files]
?   	github.com/google/cel-go/common/overloads	[no test files]
ok  	github.com/google/cel-go/common/runes	0.351s
?   	github.com/google/cel-go/common/stdlib	[no test files]
ok  	github.com/google/cel-go/common/types	1.266s
--- FAIL: TestFileDescriptionGetTypes (0.00s)
    file_test.go:105: got '[google.expr.proto3.test.TestAllTypes.MapStringStringEntry google.expr.proto3.test.TestAllTypes.MapInt64NestedTypeEntry google.expr.proto3.test.NestedTestAllTypes google.expr.proto3.test.TestJsonNames google.expr.proto3.test.TestAllTypes google.expr.proto3.test.TestAllTypes.NestedMessage]', wanted '[google.expr.proto3.test.TestAllTypes google.expr.proto3.test.TestAllTypes.NestedMessage google.expr.proto3.test.TestAllTypes.MapStringStringEntry google.expr.proto3.test.TestAllTypes.MapInt64NestedTypeEntry google.expr.proto3.test.NestedTestAllTypes]'
    file_test.go:116: Unexpected type name google.expr.proto3.test.TestJsonNames
FAIL
FAIL	github.com/google/cel-go/common/types/pb	1.464s
?   	github.com/google/cel-go/common/types/ref	[no test files]
?   	github.com/google/cel-go/common/types/traits	[no test files]
ok  	github.com/google/cel-go/examples	0.825s
ok  	github.com/google/cel-go/ext	3.294s
ok  	github.com/google/cel-go/interpreter	2.474s
?   	github.com/google/cel-go/interpreter/functions	[no test files]
ok  	github.com/google/cel-go/parser	3.491s
?   	github.com/google/cel-go/parser/gen	[no test files]
?   	github.com/google/cel-go/test	[no test files]
ok  	github.com/google/cel-go/test/bench	3.332s [no tests to run]
?   	github.com/google/cel-go/test/proto2pb	[no test files]
?   	github.com/google/cel-go/test/proto3pb	[no test files]
FAIL
```

## Finding F1 — Registered Go tests fail after adding proto3 JSON-name message
**Severity**: blocker
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/1294/common/types/pb/file_test.go:105
**What**: The required `go test ./... -count=1 -short` command exits 1. `TestFileDescriptionGetTypes` registers `proto3pb.TestAllTypes` and expects only five type names, but the current proto3 descriptor now also contains `TestJsonNames`, so the test reports an unexpected type name. Current evidence:

```go
expected := []string{
	"google.expr.proto3.test.TestAllTypes",
	"google.expr.proto3.test.TestAllTypes.NestedMessage",
	"google.expr.proto3.test.TestAllTypes.MapStringStringEntry",
	"google.expr.proto3.test.TestAllTypes.MapInt64NestedTypeEntry",
	"google.expr.proto3.test.NestedTestAllTypes"}
if len(fd.GetTypeNames()) != len(expected) {
	t.Errorf("got '%v', wanted '%v'", fd.GetTypeNames(), expected)
}
```

The new descriptor entry is present in the current proto file:

```proto
// This proto tests json_name options
message TestJsonNames {
  int32 int32_snake_case_json_name = 1
      [json_name = "int32_snake_case_json_name"];
```

**Fix**: Keep the registered test suite green. Either update the type-name expectation in the test suite through an allowed follow-up, or avoid adding `TestJsonNames` to the same descriptor registered by this existing test.

## Finding F2 — JSON REPL option still serializes as escaped-fields option
**Severity**: warning
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/1294/repl/evaluator.go:1025
**What**: Accepted claim C1 was not applied. The sharpened spec requires `(*jsonOpt).String()` to return `%option --enable_json_field_names`, but the current implementation still returns the escaped-field option. This is an observable behavior defect for `%status` / serialized REPL options because enabling JSON field names is reported as a different command. Current evidence:

```go
func (o *jsonOpt) String() string {
	return "%option --enable_escaped_fields"
}
```

**Fix**: Change the return string to `%option --enable_json_field_names`.

## Finding F3 — Optional formatter cleanup claim was not applied
**Severity**: warning
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/1294/common/types/object.go:193
**What**: Accepted claim C2 asks to replace the field-label `fmt.Fprintf` calls with direct `strings.Builder` writes while preserving behavior. The current code still uses both `fmt.Fprintf` calls. Current evidence:

```go
if field.IsExtension() {
	name = String(field.FullName())
	fmt.Fprintf(sb, "`%s`: ", name)
} else {
	fmt.Fprintf(sb, "%s: ", name)
}
```

**Fix**: Use direct builder writes for the label text without changing extension label selection, escaping, order, or lookup key.
