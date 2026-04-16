# Hunt-code: adversarial review of merged refactor

You are adversarially reviewing a merged refactor's code. Find real defects — behavior changes, broken invariants, type errors, API-shape issues. Style quibbles are out of scope.

## Inputs

- **Repo root**: `/tmp/refactor-eq-workdir/cleanroom/24483/`
- **Sharpened spec**: `/tmp/refactor-eq-workdir/forge/24483/sharpened-spec-final.md`
- **Original PR diff being refactored**: `/tmp/refactor-eq-workdir/cleanroom/24483/FORGE_INPUT_DIFF.patch`
- **Allowed edit set**: `/tmp/refactor-eq-workdir/cleanroom/24483/FORGE_ALLOWED_FILES.txt`
- **C_test baseline**: `/tmp/refactor-eq-workdir/cleanroom/24483` at the first git commit (check `git log`).
- **C_llm current state**: current working tree at `/tmp/refactor-eq-workdir/cleanroom/24483`.

## What to look for

1. **Behavior change.** String/control-flow/observable changes.
2. **Type error.** Unreachable cases under narrowed unions, incorrect type casts.
3. **API-shape error.** Wrong import path, missing/removed symbol.
4. **Unimplemented claim.** Accepted claims not applied.
5. **Out-of-scope edit.** Files outside allowed set or any `*.test.{ts,tsx}`.

You may run `tsc --noEmit` or `npm run typecheck` to check. You may `git diff HEAD~` to see what changed.

## Output

Write findings to `/tmp/refactor-eq-workdir/forge/24483/hunt-code-findings.md`. Format per finding:

```
## Finding N — <title>
**Severity**: blocker | warning | nit
**File**: <path>:<line>
**What**: <defect>
**Fix**: <what to change>
```

If zero defects: write `No findings.` and stop. Do not edit source.
