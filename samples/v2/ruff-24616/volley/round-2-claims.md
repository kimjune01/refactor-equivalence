## Accepted Claims

### C1 — Move ty-specific database support out of the shared mdtest API
**File**: `crates/mdtest/src/db.rs`:24
**Change**: Replace the exported `pub struct Db` semantic database in `mdtest` with a mdtest-local test database named `TestDb` that is only used by `mdtest` unit tests, and move the current ty semantic database implementation and its public setup methods to `ty_test` callers in `crates/ty_test/src/lib.rs` and `crates/ty_test/src/external_dependencies.rs`. Move ty-specific runtime dependencies (`ty_module_resolver`, `ty_python_semantic`, `ty_vendored`, and `ty_python_core`) out of `mdtest`'s normal dependencies and into `ty_test`; keep any ty crates needed solely by `mdtest` unit tests as `mdtest` dev-dependencies.
**Goal link**: The goal says the new crate should hold shared mdtest machinery and use `TestDb` for mdtest's own matcher/parser tests instead of depending on the real ty database.
**Justification**: Keeping ty's semantic database and runtime-only ty crate dependencies out of `mdtest` makes the crate boundary express the extraction directly and removes accidental ty-only normal dependencies from the shared crate.
**Hunt note**: Retained as narrowed for F2 because the claim now requires the Cargo dependency boundary cleanup while preserving test-only ty access through dev-dependencies.

### C2 — Move ty markdown configuration out of mdtest
**File**: `crates/mdtest/src/config.rs`:22
**Change**: Move `MarkdownTestConfig`, `Environment`, `Analysis`, `Log`, `SystemKind`, and `Project` into `ty_test` as ty's concrete `MdtestConfig` implementation, leaving `mdtest` with the generic `MdtestConfig` trait at its existing parser API path (`mdtest::parser::MdtestConfig`) and a minimal test-only config for its internal parser tests.
**Goal link**: The goal says the parser is generic over `MdtestConfig` so Ruff can provide a separate config struct.
**Justification**: Removing ty-specific TOML schema from the shared crate reduces API surface and makes the generic parser/config split explicit instead of encoding ty as the default mdtest configuration.
**Hunt note**: Retained as narrowed for F3 because the concrete ty config types move out, while the generic trait remains at the existing `mdtest::parser::MdtestConfig` API path.

### C3 — Stop using ty configuration in parser unit tests
**File**: `crates/mdtest/src/parser.rs`:976
**Change**: In the `#[cfg(test)]` module, replace `use crate::config::MarkdownTestConfig` and the `parse::<MarkdownTestConfig>` helper with a small local `TestConfig` that derives `Default`, `Clone`, and `Deserialize` and implements `MdtestConfig::has_dependencies`. The test-only config must preserve the dependency-section shape needed by parser tests: include `project: Option<TestProject>`, include `TestProject { dependencies: Option<Vec<String>> }`, and use the same serde naming behavior required to deserialize the existing `[project] dependencies` TOML in duplicate-dependency tests.
**Goal link**: The goal calls out mdtest-local test support independent of the ty test config type.
**Justification**: Parser tests should validate the generic parser contract, and using a local `TestConfig` removes a needless dependency on ty's concrete configuration without changing parser behavior.
**Hunt note**: Retained as narrowed for F1 because the local test config now explicitly preserves the `[project] dependencies` shape used by `has_dependencies` and duplicate-dependency parser errors.

### C4 — Make TestFile private to the ty runner
**File**: `crates/mdtest/src/lib.rs`:98
**Change**: Move the public `TestFile` struct into `crates/ty_test/src/lib.rs` next to `run_test`, and update the `mdtest::{Failures, FileFailures, TestFile, ...}` import to stop re-exporting or importing `TestFile` from `mdtest`.
**Goal link**: The goal describes `mdtest` as the home for shared assertion, diagnostic, matcher, and parser code, while `TestFile` is only runner state used by ty's mdtest execution.
**Justification**: Keeping this runner-only wrapper private to `ty_test` trims the shared crate API and avoids exposing a type that does not serve Ruff's future separate mdtest runner.

## Rejected

- Remove the unrelated `.github/pr-assignee-pools.toml`, typing conformance, Ruff lint, ty static, and schema changes from the artifact: these are outside the mdtest extraction goal, but most of those files are not source refactor targets for this task and the request is to propose behavior-preserving refactor claims rather than rewrite the draft patch contents.
- Rename `mdtest::db::Db` to `TestDb` in place without moving the ty semantic implementation: this would improve naming but keep the accidental ty dependency inside the shared crate, so it would not actually satisfy the goal's boundary clarification.
- Make `mdtest::matcher::Matcher` public to let downstream crates reuse lower-level matching methods: this would expand the new public API and is not required by the stated extraction, which only needs `match_file` as the shared behavior.
- Remove `MdtestConfig::has_dependencies` and let ty enforce the single-dependency-section rule after parsing: this would move an existing parser-time validation into a runner-specific layer and could change error timing and messages for invalid markdown tests.
- Change `OutputFormat::write_error` and `write_inconsistency` to return formatted strings instead of printing GitHub annotations directly: this crosses observable output behavior for CI annotations and is not necessary to express the mdtest crate split.
