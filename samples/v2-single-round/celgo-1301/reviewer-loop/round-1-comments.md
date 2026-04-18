## Comment 1 — Use `ConfigToYAML` wrapper for serialization
**Severity**: nice-to-have
**File**: repl/evaluator.go:853
**Request**: Change `yaml.Marshal(conf)` to `env.ConfigToYAML(conf)`.
**Why**: For consistency, since `env.ConfigFromYAML` is now correctly used for deserialization in this file, its counterpart `env.ConfigToYAML` should be used for serialization.

## Comment 2 — Apply `ConfigFromYAML` in the compiler tool
**Severity**: nice-to-have
**File**: tools/compiler/compiler.go:249
**Request**: Change `yaml.Unmarshal(data, envConfig)` to use `envConfig, err = env.ConfigFromYAML(data)` instead.
**Why**: The PR goal mentions adding support for parsing YAML environment configs with shorthand types, so the compiler tool should also be updated to use the new parser to properly handle these environments.
