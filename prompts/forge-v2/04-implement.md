# Implement the sharpened refactor claims

You are applying a pre-sharpened, pre-hunted refactor spec to the repo at your current working directory.

## Inputs

- **Goal** at `./GOAL.md`
- **Sharpened spec** at `./SHARPENED_SPEC.md`
- **Artifact** at `./FORGE_INPUT_DIFF.patch`
- **Allowed edit set** at `./FORGE_ALLOWED_FILES.txt`

## What to do

Apply every accepted claim in the sharpened spec, in order. For each claim, edit only the files named in it. Do not touch any file outside the allowed edit set. Do not touch any test file (`*.test.ts`, `*.test.tsx`, `*_test.go`, `test_*.py`, `*_test.py`, or equivalent).

You may NOT run tests — `node_modules` is not present in this directory. Trust the spec: every accepted claim has been adversarially reviewed, blockers have been rejected, and warnings have been narrowed.

## Implementation evidence (4e)

You must either:

1. **Apply ≥1 accepted claim with an actual source edit** AND write a summary to `./IMPLEMENT_SUMMARY.md` listing which files you modified and which claims you applied, OR
2. **Explicitly declare no-op** by writing `./IMPLEMENT_SUMMARY.md` with the single line `NO-OP: <reason>`.

"Applied M/M, no changes made" is internally inconsistent and will be flagged as a trivial no-op failure.

## Do not

- Add claims that are not in the spec.
- Re-open claims the spec rejected (they were rejected adversarially).
- Produce commentary, summary, or documentation files beyond `IMPLEMENT_SUMMARY.md`.
- Change the public API surface.

## Output

Your output is the modified source tree at the current working directory, plus `./IMPLEMENT_SUMMARY.md`. No additional markdown reports.
