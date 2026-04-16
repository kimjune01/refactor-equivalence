# Hunt-spec: adversarial review of refactor claims

You are adversarially reviewing a sharpened refactor spec BEFORE any code is written. Find defects that would force the implementer to guess, or that would break tests.

## Inputs

- **Sharpened spec** at `/tmp/refactor-eq-workdir/forge/24483/volley-round1.md`
- **Diff being refactored** at `/tmp/refactor-eq-workdir/cleanroom/24483/FORGE_INPUT_DIFF.patch`
- **Source tree** rooted at `/tmp/refactor-eq-workdir/cleanroom/24483/`
- **Tests** in `/tmp/refactor-eq-workdir/cleanroom/24483/packages/core/src/**/*.test.ts` and `/tmp/refactor-eq-workdir/cleanroom/24483/packages/cli/src/**/*.test.ts{,x}`.

## What to look for

For EACH claim in the spec, verify:
1. **Behavior preservation.** Pay special attention to exact error/message/log strings asserted in tests.
2. **API-shape correctness.** Symbols, imports, exports exist at the stated paths.
3. **Scope adherence.** Only files in `FORGE_ALLOWED_FILES.txt` and never `*.test.{ts,tsx}`.
4. **Internal consistency.** Claims applied in order don't undo each other.
5. **Underspecified edges.** Where the implementer will have to guess.

Also: check that the REJECTED list (if present) isn't missing anything — i.e., is the spec claiming more than it should.

## Output

Write findings to `/tmp/refactor-eq-workdir/forge/24483/hunt-spec-findings.md`. If zero defects, write `No findings.` only.

Do not edit any source file.
