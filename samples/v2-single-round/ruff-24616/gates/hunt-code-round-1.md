## Build: FAIL
## Tests: FAIL

Command results:

- `cat /Users/junekim/Documents/refactor-equivalence/samples/v2/ruff-24616/inputs/allowed-files.txt`: exit 0
- `cargo build`: exit 101
- `cargo test --workspace`: exit 101

Tail 50 lines from `cargo build`:

```text
    Blocking waiting for file lock on package cache
    Blocking waiting for file lock on package cache
   Compiling rand v0.10.0
   Compiling ty_vendored v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_vendored)
   Compiling tempfile v3.27.0
   Compiling ty v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty)
   Compiling ruff v0.15.10 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff)
   Compiling ty_wasm v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_wasm)
   Compiling cachedir v0.3.1
   Compiling insta v1.47.2
   Compiling uuid v1.23.0
   Compiling newtype-uuid v1.3.2
   Compiling ruff_notebook v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_notebook)
   Compiling quick-junit v0.6.0
   Compiling ruff_db v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_db)
   Compiling ty_module_resolver v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_module_resolver)
   Compiling ty_site_packages v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_site_packages)
   Compiling ruff_python_formatter v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_python_formatter)
   Compiling ty_combine v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_combine)
   Compiling ruff_linter v0.15.10 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_linter)
   Compiling ty_python_core v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_python_core)
   Compiling ty_python_semantic v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_python_semantic)
   Compiling ruff_graph v0.1.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_graph)
   Compiling ruff_workspace v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_workspace)
   Compiling ruff_markdown v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_markdown)
   Compiling ruff_server v0.2.2 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_server)
   Compiling ty_project v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_project)
   Compiling mdtest v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/mdtest)
   Compiling ty_test v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_test)
error[E0599]: no associated item named `MDTEST_TEST_FILTER` found for struct `EnvVars` in the current scope
  --> crates/ty_test/src/lib.rs:51:41
   |
51 |     let filter = std::env::var(EnvVars::MDTEST_TEST_FILTER).ok();
   |                                         ^^^^^^^^^^^^^^^^^^ associated item not found in `EnvVars`

error[E0599]: no associated item named `MDTEST_TEST_FILTER` found for struct `EnvVars` in the current scope
   --> crates/ty_test/src/lib.rs:142:26
    |
142 |                 EnvVars::MDTEST_TEST_FILTER,
    |                          ^^^^^^^^^^^^^^^^^^ associated item not found in `EnvVars`

error[E0599]: no associated item named `MDTEST_TEST_FILTER` found for struct `EnvVars` in the current scope
   --> crates/ty_test/src/lib.rs:148:26
    |
148 |                 EnvVars::MDTEST_TEST_FILTER,
    |                          ^^^^^^^^^^^^^^^^^^ associated item not found in `EnvVars`

For more information about this error, try `rustc --explain E0599`.
error: could not compile `ty_test` (lib) due to 3 previous errors
warning: build failed, waiting for other jobs to finish...
```

Tail 50 lines from `cargo test --workspace`:

```text
   Compiling ruff_db v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_db)
   Compiling tempfile v3.27.0
   Compiling quickcheck v1.1.0
   Compiling ruff_notebook v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_notebook)
   Compiling insta v1.47.2
   Compiling cachedir v0.3.1
   Compiling assert_fs v1.1.3
   Compiling insta-cmd v0.6.0
   Compiling ty_module_resolver v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_module_resolver)
   Compiling ty_site_packages v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_site_packages)
   Compiling ruff_python_formatter v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_python_formatter)
   Compiling ty_vendored v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_vendored)
   Compiling ty_combine v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_combine)
   Compiling ruff_linter v0.15.10 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_linter)
   Compiling ty_python_core v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_python_core)
   Compiling ruff_python_importer v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_python_importer)
   Compiling ruff_python_parser v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_python_parser)
   Compiling ruff_python_ast_integration_tests v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_python_ast_integration_tests)
   Compiling ruff_python_semantic v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_python_semantic)
   Compiling ruff_python_trivia_integration_tests v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_python_trivia_integration_tests)
   Compiling ty_python_semantic v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_python_semantic)
   Compiling ruff_graph v0.1.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_graph)
   Compiling ruff_workspace v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_workspace)
   Compiling ruff_markdown v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_markdown)
   Compiling ruff_server v0.2.2 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff_server)
   Compiling ty_project v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_project)
   Compiling mdtest v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/mdtest)
   Compiling ty_test v0.0.0 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ty_test)
error[E0599]: no associated item named `MDTEST_TEST_FILTER` found for struct `EnvVars` in the current scope
  --> crates/ty_test/src/lib.rs:51:41
   |
51 |     let filter = std::env::var(EnvVars::MDTEST_TEST_FILTER).ok();
   |                                         ^^^^^^^^^^^^^^^^^^ associated item not found in `EnvVars`

error[E0599]: no associated item named `MDTEST_TEST_FILTER` found for struct `EnvVars` in the current scope
   --> crates/ty_test/src/lib.rs:142:26
    |
142 |                 EnvVars::MDTEST_TEST_FILTER,
    |                          ^^^^^^^^^^^^^^^^^^ associated item not found in `EnvVars`

error[E0599]: no associated item named `MDTEST_TEST_FILTER` found for struct `EnvVars` in the current scope
   --> crates/ty_test/src/lib.rs:148:26
    |
148 |                 EnvVars::MDTEST_TEST_FILTER,
    |                          ^^^^^^^^^^^^^^^^^^ associated item not found in `EnvVars`

   Compiling ruff v0.15.10 (/private/tmp/refactor-eq-workdir/cleanroom-v2/24616/crates/ruff)
For more information about this error, try `rustc --explain E0599`.
error: could not compile `ty_test` (lib) due to 3 previous errors
warning: build failed, waiting for other jobs to finish...
```

## Finding F1 — `ty_test` no longer compiles after moving mdtest env vars
**Severity**: blocker
**File**: `crates/ty_test/src/lib.rs`:51
**What**: `ty_test` still reads and prints `EnvVars::MDTEST_TEST_FILTER`, but the compiled `ty_static::EnvVars` API visible to this crate has no such associated item, so both the full build and workspace tests fail before any test can run. Current triggering lines:

```rust
let filter = std::env::var(EnvVars::MDTEST_TEST_FILTER).ok();
```

```rust
                EnvVars::MDTEST_TEST_FILTER,
```

```rust
                EnvVars::MDTEST_TEST_FILTER,
```

**Fix**: Make the environment-variable constant available at the API used by `ty_test`, or stop depending on `ty_static::EnvVars` for mdtest-only variables and use the mdtest/ty-test-owned constant consistently at these call sites. Then rerun `cargo build` and `cargo test --workspace`.
