## Accepted Claims

### C1 — Move ty-specific database support out of the shared mdtest API
**File**: `crates/mdtest/src/db.rs`:24
**Change**: Replace the exported `pub struct Db` semantic database in `mdtest` with a mdtest-local test database named `TestDb` that is only used by `mdtest` unit tests, and move the current ty semantic database implementation and its public setup methods to `ty_test` callers in `crates/ty_test/src/lib.rs` and `crates/ty_test/src/external_dependencies.rs`.
**Goal link**: The goal says the new crate should hold shared mdtest machinery and use `TestDb` for mdtest's own matcher/parser tests instead of depending on the real ty database.
**Justification**: Keeping ty's semantic database out of `mdtest` makes the crate boundary express the extraction directly and removes accidental ty-only dependencies from the shared crate.

### C2 — Move ty markdown configuration out of mdtest
**File**: `crates/mdtest/src/config.rs`:22
**Change**: Move `MarkdownTestConfig`, `Environment`, `Analysis`, `Log`, `SystemKind`, and `Project` into `ty_test` as ty's concrete `MdtestConfig` implementation, leaving `mdtest` with only the generic `MdtestConfig` trait and a minimal test-only config for its internal parser tests.
**Goal link**: The goal says the parser is generic over `MdtestConfig` so Ruff can provide a separate config struct.
**Justification**: Removing ty-specific TOML schema from the shared crate reduces API surface and makes the generic parser/config split explicit instead of encoding ty as the default mdtest configuration.

### C3 — Stop using ty configuration in parser unit tests
**File**: `crates/mdtest/src/parser.rs`:976
**Change**: In the `#[cfg(test)]` module, replace `use crate::config::MarkdownTestConfig` and the `parse::<MarkdownTestConfig>` helper with a small local `TestConfig` that derives `Default`, `Clone`, and `Deserialize` and implements `MdtestConfig::has_dependencies`.
**Goal link**: The goal calls out mdtest-local test support independent of the ty test config type.
**Justification**: Parser tests should validate the generic parser contract, and using a local `TestConfig` removes a needless dependency on ty's concrete configuration without changing parser behavior.

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
