# Refactoring spec v1

Input to the forge pipeline. Sharpened by Volley, implemented by blind-blind-merge, verified by bug-hunt, cleaned by Volley.

The agent receives: the diff from `C_base` to `C_test`, the list of files it may edit, and the full repo at `C_test`.

---

## Goal

Refactor the changes in this diff to reduce complexity without changing behavior. The test suite must still pass after refactoring.

## Focus

- Eliminate duplication introduced by this diff (not pre-existing duplication)
- Reduce indirection — inline helpers that are called once, flatten unnecessary wrappers
- Match the surrounding code's patterns — if the rest of the codebase uses X, don't introduce Y
- Remove dead code, unused imports, and unnecessary type assertions
- Simplify control flow — flatten nested conditionals, replace flag variables with early returns
- Improve names where the current names are misleading or inconsistent with codebase conventions

## Constraints

- Edit only files in the allowed file set
- Do not edit tests
- Do not add abstractions, interfaces, or patterns not already present in the codebase
- Do not change the public API surface

## Quality bar

The simplest correct implementation that a reviewer would approve on first read. Fewer concepts and branches is better than fewer lines — don't golf. Familiar patterns are better than clever ones. If unsure whether a change simplifies, don't make it.

## Forge pipeline notes

- **Volley** sharpens this spec into specific, testable refactoring claims (e.g., "inline `formatHelper` since it's called once" or "flatten the nested conditional in `processItem`"). Two rounds to convergence.
- **Blind-blind-merge** produces two independent implementations. The structurally simpler one per component wins.
- **Bug-hunt** verifies the merged result against this spec. If a finding traces to the spec, fix the spec and re-merge.
- **Final Volley** cleans naming and dead code. Two rounds to convergence. Output is `C_llm`.
