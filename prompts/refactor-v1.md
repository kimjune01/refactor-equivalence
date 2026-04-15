# Refactoring prompt v1

Given to the LLM after checkout at `C_test` (tests first pass).

---

The tests pass. The feature works. But this code isn't merge-ready yet.

Refactor the changes in this PR to reduce complexity without changing behavior. The test suite must still pass after your changes.

Focus on:
- Eliminating duplication introduced by this PR (not pre-existing duplication)
- Reducing indirection — inline helpers that are called once, flatten unnecessary wrappers
- Matching the surrounding code's patterns — if the rest of the codebase uses X, don't introduce Y
- Removing dead code, unused imports, and unnecessary type assertions added by this PR
- Simplifying control flow — flatten nested conditionals, replace flag variables with early returns

Do NOT:
- Refactor code outside the PR's diff
- Add abstractions, interfaces, or patterns not already present in the codebase
- Rename things for "clarity" — the existing codebase's naming conventions are the target
- Add comments, documentation, or error handling beyond what the PR requires
- Change the public API surface

The goal is the simplest correct implementation that a reviewer would approve on first read. Less code is better. Familiar patterns are better. If you're unsure whether a change simplifies, don't make it.
