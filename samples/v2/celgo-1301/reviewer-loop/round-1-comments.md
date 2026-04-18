## Comment 1 — Use ConfigToYAML wrapper
**Severity**: nice-to-have
**File**: repl/evaluator.go:853
**Request**: Change `yaml.Marshal(conf)` to `env.ConfigToYAML(conf)`.
**Why**: Since `env.ConfigFromYAML` is now used to parse YAML in the REPL, the symmetric wrapper `env.ConfigToYAML` should be used when serializing the environment back to YAML.
