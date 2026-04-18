## Accepted Claims

### C1 — Correct JSON option serialization
**File**: repl/evaluator.go:1025
**Change**: Change `(*jsonOpt).String()` to return `%option --enable_json_field_names` instead of `%option --enable_escaped_fields`.
**Goal link**: This clarifies the new REPL flag for JSON field-name support.
**Justification**: The JSON option currently serializes as the escaped-field option, so `%status` and YAML comments describe the wrong REPL command and obscure the intended JSON-name behavior.

### C2 — Format extension object fields without `fmt.Fprintf`
**File**: common/types/object.go:190
**Change**: In `(*protoObj).format`, replace the two `fmt.Fprintf` calls for field labels with direct `strings.Builder` writes, using one local descriptor name for both the displayed label and the `o.Get(String(...))` lookup.
**Goal link**: This clarifies the extension-field formatting path added for proto2 extension support.
**Justification**: Direct builder writes express the two cases, normal field name versus backtick-escaped full extension name, without formatting machinery or a mutable `types.String` value that obscures which protobuf name is used for lookup.

## Rejected

- Remove `c.HistoryFile = filepath.Join(os.Getenv("HOME"), ".cel-repl.history")` from `repl/main/main.go`: this change is unrelated to the stated proto2-extension and JSON-name goal, but removing it would alter observable CLI history behavior rather than preserve behavior.
- Change `TypeDescription.FieldByName` to prefer proto field names before JSON names when `JSONFieldNames(true)` is enabled: this would change the collision semantics covered by JSON-name cases such as `single_string` shadowing and would work against the goal of honoring JSON field names.
- Move extension lookup before JSON-name lookup in `TypeDescription.FieldByName`: this risks reintroducing the bug described by the goal where JSON field names and extensions interact incorrectly.
- Replace `cel-spec-test-types` descriptor loading with the repo-local `test/proto2pb` and `test/proto3pb` descriptors: this would change the public package/type names loaded by the REPL package shortcut and would no longer match the cel-spec conformance types named in the goal.
- Add `test/proto2pb/test_extensions.proto` to the REPL package descriptor set: the file is outside the allowed edit set and would mix repo-local test protos into the cel-spec package shortcut rather than using the cel-spec proto2 extension descriptors already added.
- Add or adjust REPL and protobuf tests for JSON field-name flags or extension formatting: test files are explicitly out of scope for this volley, even though those tests would be useful verification for the implementation.
