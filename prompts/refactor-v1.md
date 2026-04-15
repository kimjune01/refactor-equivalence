# Refactoring prompt v1

Given to the LLM after checkout at `C_test` (tests first pass). The agent receives the diff from `C_base` to `C_test` and the list of files it may edit.

---

The tests pass. The feature works. But this code isn't merge-ready yet.

Refactor the changes in this diff to reduce complexity without changing behavior. The test suite must still pass after your changes.

Focus on:
- Eliminating duplication introduced by this diff (not pre-existing duplication)
- Reducing indirection — inline helpers that are called once, flatten unnecessary wrappers
- Matching the surrounding code's patterns — if the rest of the codebase uses X, don't introduce Y
- Removing dead code, unused imports, and unnecessary type assertions
- Simplifying control flow — flatten nested conditionals, replace flag variables with early returns
- Improving names where the current names are misleading or inconsistent with codebase conventions

Do NOT:
- Edit files outside the allowed file set
- Edit tests
- Add abstractions, interfaces, or patterns not already present in the codebase
- Change the public API surface

The goal is the simplest correct implementation that a reviewer would approve on first read. Fewer concepts and branches is better than fewer lines — don't golf. Familiar patterns are better than clever ones. If you're unsure whether a change simplifies, don't make it.
