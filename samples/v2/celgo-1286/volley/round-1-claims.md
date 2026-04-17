## Accepted Claims

### C1 — Centralize context proto field-name selection
**File**: cel/options.go:783
**Change**: Add a small unexported helper near `fieldToVariable`, for example `protoFieldName(field protoreflect.FieldDescriptor, jsonFieldNames bool) string`, and use it in both `fieldToVariable` and `ContextProtoVars` instead of repeating the `field.TextName()` / `field.JSONName()` conditional.
**Goal link**: This clarifies the goal aspect that context proto declarations and context proto activations must choose the same JSON-vs-proto field-name mode.
**Justification**: Keeping the name-selection rule in one local helper removes duplicated conditional logic while preserving the existing proto-name default and JSON-name behavior under `JSONFieldNames(true)`.

### C2 — Make registry JSONFieldNames option a direct delegation
**File**: common/types/provider.go:106
**Change**: Simplify the `JSONFieldNames(enabled bool) RegistryOption` closure to return `r, r.WithJSONFieldNames(enabled)` directly, without the temporary `err` variable.
**Goal link**: This clarifies that the public registry option is only a thin adapter over the registry's JSON-field-name mode.
**Justification**: Removing the local temporary reduces incidental boilerplate around the new JSON field-name registry configuration and keeps behavior identical.

### C3 — Use idiomatic inline error handling for registry reconfiguration
**File**: cel/env.go:857
**Change**: Replace the separate `err := reg.WithJSONFieldNames(true)` assignment and following `if err != nil` with `if err := reg.WithJSONFieldNames(true); err != nil { return nil, err }`.
**Goal link**: This clarifies that environment configuration has a single bounded side effect when `JSONFieldNames(true)` is enabled: reconfigure the proto registry for JSON names.
**Justification**: The inline form matches surrounding Go idioms for one-shot error checks and removes unnecessary state without changing provider compatibility or error behavior.

### C4 — Correct stale Program comment after json_name validation
**File**: cel/program.go:227
**Change**: Replace the comment `Configure the type provider, considering whether the AST indicates whether it supports JSON field names` with a comment that describes the following block as attribute-factory selection, or delete it if no extra explanation is needed.
**Goal link**: This clarifies the goal aspect that `Program` validates the AST `json_name` extension against the environment feature, while the provider was already configured on the `Env`.
**Justification**: The existing comment describes a provider reconfiguration that does not occur in this block, so removing or correcting it eliminates misleading accidental structure without affecting behavior.

### C5 — Align JSONFieldNames EnvOption documentation with implementation
**File**: cel/options.go:437
**Change**: Rewrite the `JSONFieldNames` doc comment to state that the option enables protobuf field access by JSON names for environments backed by `*types.Registry`, rather than saying it creates a copy of the registry or infers support from AST extension metadata.
**Goal link**: This clarifies the user-facing feature added by the goal: JSON-name access is controlled explicitly by `cel.JSONFieldNames(true)`.
**Justification**: The current comment overstates implementation details and mixes checking/planning metadata with registry setup, so tightening it reduces confusion while leaving the API and behavior unchanged.

## Rejected

- Fix `common/ast.SourceInfo.HasExtension` to scan every extension and compare versions semantically: this is a real behavior fix for multi-extension or major-version cases, not a behavior-preserving refactor, and it would need direct test coverage.
- Move feature serialization in `Env.ToConfig` or feature deserialization in `configToEnvOptions` back to their original later positions: this would break the goal path where `DeclareContextProto` must see `JSONFieldNames(true)` before generating context field declarations.
- Change `JSONFieldNames(true)` to accept arbitrary custom providers or wrapper types instead of requiring `*types.Registry`: this crosses a compatibility boundary and would change the observable error covered by `TestJSONFieldNamesInvalidProvider`.
- Change `ContextProtoVars` to accept `cel.JSONFieldNames(true)` rather than `types.JSONFieldNames(true)`: this would be a public API shape change, not a bounded cleanup, and would mix environment options with registry options.
- Restore or alias the old `types.ProtoTypes` name alongside `ProtoTypeDefs`: that is an API compatibility addition outside the narrow JSON-field-name expression cleanup and is not directly justified by the goal text.
- Remove the `json_name` AST extension validation from `newProgram`: this would permit planning a JSON-name-checked AST in an environment without `JSONFieldNames(true)`, changing the observable safety behavior added for the goal.
