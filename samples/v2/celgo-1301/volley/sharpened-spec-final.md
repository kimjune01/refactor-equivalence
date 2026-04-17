## Accepted Claims

### C1 — Use the environment YAML loader in REPL config parsing
**File**: `/tmp/refactor-eq-workdir/cleanroom-v2/1301/repl/evaluator.go`:920
**Change**: In `parseYAMLConfig`, replace the local `var c env.Config` plus `yaml.Unmarshal(yamlSrc, &c)` block with a call to `env.ConfigFromYAML(yamlSrc)`, and pass the returned `*env.Config` to `cel.FromConfig`.
**Goal link**: The goal adds YAML environment config support for shorthand type specifiers; routing REPL YAML loading through the new environment-level loader makes that intent explicit at the REPL boundary.
**Justification**: This removes duplicate YAML decoding logic from the REPL and centralizes shorthand TypeDesc parsing in `common/env` without changing the resulting config.

### C3 — Reuse TypeDesc shape for mapping-node YAML decoding
**File**: `/tmp/refactor-eq-workdir/cleanroom-v2/1301/common/env/io.go`:24
**Change**: Replace the hand-copied `internalTypeDesc` struct with a local defined type based on `TypeDesc` that has no `UnmarshalYAML` method, and in `(*TypeDesc).UnmarshalYAML` decode mapping nodes into that type before assigning back to `*td`.
**Goal link**: The goal adds shorthand parsing while preserving the existing structured YAML type form; using the existing TypeDesc field shape makes the structured fallback clearer.
**Justification**: This removes duplicated field definitions and YAML tags while preserving the recursion break needed by custom unmarshalling.

## Rejected

- Remove the duplicate env import alias in `repl/evaluator.go`: rejected due to blocker finding F1 in `hunt-spec-round-1.md`; replacing `envlib.NewVariable` and `envlib.SerializeTypeDesc` with `env.NewVariable` and `env.SerializeTypeDesc` collides with existing local `env *cel.Env` parameters, so the literal claim would not compile.
- Fix `checkWellKnown` so `google.protobuf.DoubleValue` and `google.protobuf.FloatValue` return `double_wrapper`: this appears to correct a bug in `/tmp/refactor-eq-workdir/cleanroom-v2/1301/repl/typefmt.go`:104, but it changes observable REPL type parsing behavior rather than being a behavior-preserving refactor.
- Remove `fmt.Println(tc.confIn.Variables[0].Name, tc.confIn.Variables[0].TypeName)` from `common/env/io_test.go`: this is stray test output, but test files are explicitly out of scope for accepted claims.
- Regenerate or clean up the ANTLR generated files under `repl/parser`: those files are in the allowed edit set, but changing generated parser artifacts is not a bounded source refactor and would require generator-version assumptions outside the goal.
- Reintroduce or reshape the `StringsMaxPrecision` formatting option changes in `ext/strings.go`, `ext/formatting.go`, or `ext/formatting_v2.go`: those edits are part of the supplied artifact but do not relate to shorthand environment YAML or REPL TypeDesc tracking, so they are outside the goal-anchored refactor scope.
- Widen `ParseTypeDesc` whitespace handling beyond literal spaces in `common/env/io.go`: accepting tabs or other whitespace could be desirable parser behavior, but it would expand accepted input and is therefore not behavior-preserving.
