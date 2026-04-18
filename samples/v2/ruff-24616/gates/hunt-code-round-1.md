## Build failure — round 1
```
   Compiling ty_wasm v0.0.0 (/private/tmp/refactor-eq-workdir/bb-merged-24616/crates/ty_wasm)
   Compiling ty_test v0.0.0 (/private/tmp/refactor-eq-workdir/bb-merged-24616/crates/ty_test)
error[E0599]: no associated item named `MDTEST_TEST_FILTER` found for struct `EnvVars` in the current scope
--
    |                                         ^^^^^^^^^^^^^^^^^^ associated item not found in `EnvVars`

error[E0599]: no associated item named `MDTEST_TEST_FILTER` found for struct `EnvVars` in the current scope
--
    |                          ^^^^^^^^^^^^^^^^^^ associated item not found in `EnvVars`

error[E0599]: no associated item named `MDTEST_TEST_FILTER` found for struct `EnvVars` in the current scope
--

For more information about this error, try `rustc --explain E0599`.
error: could not compile `ty_test` (lib) due to 3 previous errors
```
Fix these compilation errors. The compiler tells you exactly what's wrong.
