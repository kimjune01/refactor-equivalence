# PR #24616 — Factor out the `mdtest` crate

## PR body

Summary
--

This is a first step toward adding mdtests for Ruff. I actually wrote the code
in the opposite order, first copy-pasting `ty_test` to a `ruff_test` crate, and then
factoring out the shared code, but I figured it would be easier to review in
this order. I also opened a stacked PR with the `ruff_test` changes (#24617)
to show that the API works well for that too.

The main change here is moving several of the modules from `ty_test` to a new
`mdtest` crate:
- `assertion`
- `diagnostic`
- `matcher`
- `parser`

Beyond moving these files to the new crate, I made `Matcher` functions take a
`&dyn Db` to support passing a different concrete type from `ruff_test`, and I
also made the parser generic over an `MdtestConfig` trait to allow Ruff to use a
separate config struct. I also introduced new `TestConfig` and `TestDb` types to allow
testing the `matcher` and `parser` within the `mdtest` crate without depending
on either the real ty `Db` or `ty_test` config type.

The lib.rs file from `ty_test` was essentially split in half, with the shared
code moved to the `mdtest` crate and the ty-specific parts kept in `ty_test`.

Test Plan
--

All existing mdtests and the unit tests from `ty_test` should still pass, and
the stacked branch with the `ruff_test` crate tests the split API


## Linked issues
(none)
