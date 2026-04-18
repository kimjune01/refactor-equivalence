Applied claims: C1, C2, C3, C4.

Modified files:
- Cargo.lock
- crates/mdtest/Cargo.toml
- crates/mdtest/src/assertion.rs
- crates/mdtest/src/config.rs
- crates/mdtest/src/db.rs
- crates/mdtest/src/diagnostic.rs
- crates/mdtest/src/lib.rs
- crates/mdtest/src/matcher.rs
- crates/mdtest/src/parser.rs
- crates/ty_test/Cargo.toml
- crates/ty_test/src/external_dependencies.rs
- crates/ty_test/src/lib.rs

Summary:
- Replaced mdtest's exported ty semantic database with a test-only mdtest `TestDb`.
- Moved ty's concrete markdown configuration and semantic database support into `ty_test`.
- Updated mdtest parser tests to use a local `TestConfig` preserving `[project] dependencies`.
- Moved `TestFile` out of mdtest and into the ty runner.
- Moved ty runtime dependencies from mdtest to ty_test.
