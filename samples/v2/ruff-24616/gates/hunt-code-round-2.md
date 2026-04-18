## Test failure — round 2
```
test parser::tests::separate_path_whitespace_1 ... ok
test parser::tests::source_map_reports_invalid_relative_line ... ok
test parser::tests::source_map_to_absolute_line_number ... ok
test parser::tests::snapshot_diagnostic_directive_detection_ignores_whitespace ... ok
test parser::tests::unterminated_code_block_1 ... ok
test parser::tests::unterminated_code_block_2 ... ok
test parser::tests::section_directive_must_appear_before_config ... FAILED
test parser::tests::single_file_test ... ok
test parser::tests::header_start_at_beginning_of_line ... ok
test parser::tests::no_new_line_at_eof ... ok
test parser::tests::multiple_file_tests ... ok
test parser::tests::multiple_tests ... ok

failures:

---- parser::tests::section_directive_must_appear_before_config stdout ----

thread 'parser::tests::section_directive_must_appear_before_config' (19674189) panicked at crates/mdtest/src/parser.rs:2060:9:
assertion `left == right` failed
  left: "Error while parsing Markdown TOML config"
 right: "Section config to enable snapshotting diagnostics must come before everything else (including TOML configuration blocks)."
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace


failures:
    parser::tests::section_directive_must_appear_before_config

test result: FAILED. 101 passed; 1 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.04s

error: test failed, to rerun pass `-p mdtest --lib`
```
Fix the failing test. The test output shows what's expected vs actual.
