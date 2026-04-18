## Finding F1 — Parser test config omits required dependency shape
**Severity**: warning
**Claim**: C3
**What**: The claim says to replace parser unit tests with a "small local `TestConfig`" that derives `Default`, `Clone`, and `Deserialize` and implements `MdtestConfig::has_dependencies`, but it does not say that the local config must deserialize `[project] dependencies`. Without that field shape, `has_dependencies` cannot preserve the parser-time rejection for multiple dependency sections.
**Evidence**: `crates/mdtest/src/parser.rs:861` deserializes each TOML config into the generic config type, `crates/mdtest/src/parser.rs:863` gates the duplicate-dependency error on `config.has_dependencies()`, and the test at `crates/mdtest/src/parser.rs:2108` asserts the exact duplicate-dependencies error for two `[project] dependencies` blocks.
**Fix**: Clarify C3 to require a test-only config with a `project: Option<TestProject>` field and `TestProject { dependencies: Option<Vec<String>> }` (with the same serde kebab-case behavior needed by the test), and implement `has_dependencies` from that field.

## Finding F2 — Dependency boundary cleanup is underspecified
**Severity**: warning
**Claim**: C1
**What**: C1's justification says moving the ty database out of `mdtest` removes ty-only dependencies from the shared crate, but the claim only describes source moves. It does not specify the required `Cargo.toml` follow-through: ty database dependencies must move out of normal `mdtest` dependencies, while ty-powered mdtest unit tests still need access to them as test-only dependencies.
**Evidence**: `crates/mdtest/Cargo.toml:25` through `crates/mdtest/Cargo.toml:28` currently list `ty_module_resolver`, `ty_python_semantic`, `ty_vendored`, and `ty_python_core` as normal dependencies. The mdtest test modules still use those APIs at `crates/mdtest/src/assertion.rs:491` through `crates/mdtest/src/assertion.rs:494` and `crates/mdtest/src/matcher.rs:431` through `crates/mdtest/src/matcher.rs:434`.
**Fix**: Narrow C1 to explicitly move ty-specific runtime dependencies from `mdtest` to `ty_test`, and keep any ty crates needed solely by mdtest unit tests under `mdtest` dev-dependencies. If normal dependencies are intentionally left unchanged, remove the "removes accidental ty-only dependencies" justification.

## Finding F3 — MdtestConfig trait location is ambiguous
**Severity**: warning
**Claim**: C2
**What**: C2 targets `crates/mdtest/src/config.rs` and says mdtest should be left with "only the generic `MdtestConfig` trait", but that trait is not in `config.rs`; it is currently part of the parser API. An implementer could move the trait into `config.rs` while moving ty's `MarkdownTestConfig` out, changing the public API path unnecessarily.
**Evidence**: `MdtestConfig` is declared at `crates/mdtest/src/parser.rs:25`, and the parser API uses it directly at `crates/mdtest/src/parser.rs:34`.
**Fix**: Clarify that C2 moves only ty's concrete config types out of `mdtest`; the generic trait should remain at `mdtest::parser::MdtestConfig` unless the spec explicitly accepts an API-path change.
