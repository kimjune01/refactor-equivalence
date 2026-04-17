## Accepted Claims

### C1 — Remove duplicate keyword trimming
**File**: `crates/ty_test/src/pragma_comments.rs`:277
**Change**: In `UnparsedAssertion::from_comment`, delete the second consecutive `let keyword = keyword.trim();` binding and keep the single trim performed immediately after `split_once(':')`.
**Goal link**: This clarifies the new shared parsing path for `# snapshot`, `# error:`, and `# revealed:` pragmas.
**Justification**: The duplicate trim is accidental structure from the extraction into `pragma_comments.rs`; removing it preserves parsing behavior while making the selective inline snapshot comment parser simpler.

### C2 — Drop unused matcher lifetime parameter
**File**: `crates/ty_test/src/matcher.rs`:326
**Change**: Change `Matcher::match_line<'a, 'b>(...) -> ... where 'b: 'a` to use only the diagnostic lifetime that is actually needed, removing the unused `'b` parameter and its `where` clause.
**Goal link**: This clarifies the matcher change that now returns diagnostics selected by `# snapshot` comments.
**Justification**: The extra lifetime no longer corresponds to any argument after switching from raw assertion slices to `LinePragmaComments`, so removing it reduces type-level noise without changing matching behavior.

### C3 — Remove inert snapshot update override hook
**File**: `crates/ty_test/src/lib.rs`:808
**Change**: In `is_update_inline_snapshots_enabled`, remove the `#[cfg(test)]` branch that calls `snapshot_update_mode_override`, and delete the `snapshot_update_mode_override` function that always returns `None`.
**Goal link**: This clarifies that inline snapshot updating is controlled solely by `MDTEST_UPDATE_SNAPSHOTS`, as described in the PR goal.
**Justification**: The override hook has no implementation and cannot affect the existing suite, so deleting it removes an unused indirection around the update-mode decision.

### C4 — Replace inline snapshot parser unwrap with a normal parse error
**File**: `crates/ty_test/src/parser.rs`:950
**Change**: In `Parser::process_inline_snapshot`, replace `file.code_blocks.last_mut().unwrap()` with a `let Some(code_block) = file.code_blocks.last_mut() else { bail!(...) };` branch that reports that an inline diagnostics block must follow a checkable Python file block.
**Goal link**: This keeps the new `diagnostics` block parsing path expressed as mdtest validation instead of relying on an internal panic.
**Justification**: Valid mdtests still reach the same code block, while the parser remains consistent with surrounding `bail!`-based error handling and avoids an unnecessary panic in the inline snapshot feature path.

### C5 — Refresh stale `match_line` documentation
**File**: `crates/ty_test/src/matcher.rs`:321
**Change**: Update the doc comment above `Matcher::match_line` so it describes matching a line's diagnostics against `LinePragmaComments` and returning matched diagnostics for inline snapshots, rather than describing only a slice of `UnparsedAssertion`s and unmatched values.
**Goal link**: This clarifies the goal's selective diagnostic snapshotting behavior at the point where assertions are matched and snapshot diagnostics are collected.
**Justification**: The current comment describes the pre-refactor assertion-only API, so correcting it removes misleading documentation without changing behavior.

## Rejected

- Swap the arguments in `OutputFormat::write_error` when calling `render_diff`: this likely fixes the displayed expected/actual diff direction, but it changes observable failure output and is therefore not a behavior-preserving refactor claim.
- Delete `IndexSlice::last` and `IndexSlice::last_mut` from `crates/ruff_index/src/slice.rs`: `IndexVec::last_mut` is used by the new inline diagnostics parser, and removing the helper would require replacing a public crate API addition rather than simplifying the mdtest implementation in place.
- Move the `MDTEST_UPDATE_SNAPSHOTS` constant into `ty_static::EnvVars`: the artifact intentionally removed mdtest-only environment variables from `ty_static`, and moving this one there would cross back into the shared static crate without reducing inline snapshot complexity.
- Convert `matcher::match_file` and `Matcher::match_line` to return borrowed diagnostics instead of cloned `Diagnostic` values: this could reduce allocations, but it would change several function signatures and lifetime relationships across `matcher.rs` and `lib.rs`, making it a broader API refactor than needed for the goal.
