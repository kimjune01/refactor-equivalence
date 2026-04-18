## Accepted Claims

1. ### C1 — Correct JSON option serialization
   **File**: repl/evaluator.go:1025
   **Change**: Change `(*jsonOpt).String()` to return `%option --enable_json_field_names` instead of `%option --enable_escaped_fields`.
   **Goal link**: This clarifies the new REPL flag for JSON field-name support.
   **Justification**: The JSON option currently serializes as the escaped-field option, so `%status` and YAML comments describe the wrong REPL command and obscure the intended JSON-name behavior.

2. ### C2 — Optional field-formatting cleanup only
   **File**: common/types/object.go:190
   **Change**: In `(*protoObj).format`, replace the two `fmt.Fprintf` calls for field labels with direct `strings.Builder` writes, without changing the selected display label, the backtick escaping for full extension names, iteration order, or the `o.Get(String(...))` lookup key.
   **Goal link**: This is only a local readability cleanup in the proto object formatting path; it is not required for proto2-extension or JSON-name behavior.
   **Justification**: Direct builder writes can express the existing two display cases, normal field name versus backtick-escaped full extension name, without formatting machinery, provided the existing label selection and lookup semantics are preserved.
   **Hunt note**: Retained as narrowed in response to F1 because it is explicitly optional style cleanup and does not authorize behavioral changes to extension formatting or lookup.

## Rejected

- Remove `c.HistoryFile = filepath.Join(os.Getenv("HOME"), ".cel-repl.history")` from `repl/main/main.go`: this change is unrelated to the stated proto2-extension and JSON-name goal, but removing it would alter observable CLI history behavior rather than preserve behavior.
- Change `TypeDescription.FieldByName` to prefer proto field names before JSON names when `JSONFieldNames(true)` is enabled: this would change the collision semantics covered by JSON-name cases such as `single_string` shadowing and would work against the goal of honoring JSON field names. Required preserved behavior, clarified from hunt finding F2: with JSON field names enabled, lookup must check JSON names first, proto field names second, and extensions third.
- Move extension lookup before JSON-name lookup in `TypeDescription.FieldByName`: this risks reintroducing the bug described by the goal where JSON field names and extensions interact incorrectly. Required preserved behavior, clarified from hunt finding F2: extension lookup must remain after JSON-name and proto-name lookup.
- Replace `cel-spec-test-types` descriptor loading with the repo-local `test/proto2pb` and `test/proto3pb` descriptors: this would change the public package/type names loaded by the REPL package shortcut and would no longer match the cel-spec conformance types named in the goal.
- Add `test/proto2pb/test_extensions.proto` to the REPL package descriptor set: the file is outside the allowed edit set and would mix repo-local test protos into the cel-spec package shortcut rather than using the cel-spec proto2 extension descriptors already added.
- Add or adjust REPL and protobuf tests for JSON field-name flags or extension formatting: test files are explicitly out of scope for this volley, even though those tests would be useful verification for the implementation.
