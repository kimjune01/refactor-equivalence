# Hunt-spec — adversarial review of refactor claims (iterative)

You are adversarially reviewing a sharpened refactor spec BEFORE any code is written. Find defects that would force the implementer to guess, that would break tests, or that misrepresent the goal.

## Inputs

- **Goal** at `{TRIAL_DIR}/goal/GOAL.md` — what the PR aims to accomplish.
- **Sharpened spec** at `{TRIAL_DIR}/volley/round-{N}-claims.md` (latest round to critique).
- **Artifact** at `{TRIAL_DIR}/inputs/diff-base-to-test.patch`.
- **Allowed edit set** at `{TRIAL_DIR}/inputs/allowed-files.txt`.
- **Cleanroom source tree** at `{CLEANROOM}/`.
- **Tests** visible inside `{CLEANROOM}/` — assume they represent the behavioral contract.

## What to look for

For EACH claim in the spec, check:

1. **Behavior preservation.** Pay attention to exact error/message/log strings asserted in tests. A claim that renames a user-visible string is a blocker if the string is asserted.
2. **API-shape correctness.** Symbols, imports, exports exist at the stated paths in C_test. A claim referencing a non-existent symbol is a blocker.
3. **Scope adherence.** Claims only touch `allowed-files.txt` and never `*.test.{ts,tsx,py,go,rs}`.
4. **Goal alignment.** The claim serves the stated goal. A claim that improves a dimension unrelated to the goal (or orthogonal tidying) is a warning, not a blocker, unless it conflicts with the goal.
5. **Internal consistency.** Claims applied in order don't undo each other.
6. **Underspecified edges.** Where the implementer will have to guess.
7. **Missing rejections.** Something the spec proposes that SHOULD have been rejected.

## Severity labels

Use exactly these:

- **blocker** — test-breaking, behavior-changing, or referring to nonexistent code. Forces the reconcile step to REJECT the claim (not narrow).
- **warning** — underspecified, ambiguous, or orthogonal-to-goal. Reconcile may narrow, clarify, or reject.
- **note** — optional stylistic feedback. Reconcile may ignore.

## Output

Write findings to `{TRIAL_DIR}/volley/hunt-spec-round-{N}.md`. If zero defects across all severity levels, write:

```
No findings.
```

Otherwise:

```
## Finding F1 — <title>
**Severity**: blocker | warning | note
**Claim**: C<num> (or global)
**What**: <defect>
**Evidence**: <file:line or test name or code snippet>
**Fix**: <remove claim / narrow it thus / clarify this edge>
```

Do not edit any source file. Do not propose new refactor claims.
