Applied 4/4 accepted claims.

Modified files:
- crates/ty_test/src/pragma_comments.rs
- crates/ty_test/src/matcher.rs
- crates/ty_test/src/lib.rs

Claims applied:
- C1: Removed the duplicate `keyword.trim()` binding in `UnparsedAssertion::from_comment`.
- C2: Removed the unused matcher lifetime parameter and `where` clause from `Matcher::match_line`.
- C3: Removed the inert snapshot update override hook from `is_update_inline_snapshots_enabled`.
- C5: Refreshed the `Matcher::match_line` documentation to describe `LinePragmaComments` and inline snapshot diagnostics.
