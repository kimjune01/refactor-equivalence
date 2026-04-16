# Implement the sharpened refactor claims

You are applying a pre-sharpened, pre-hunted refactor spec to the repo at your current working directory.

## Inputs

- **Sharpened spec** at `./SHARPENED_SPEC.md`
- **Diff being refactored** at `./FORGE_INPUT_DIFF.patch`
- **Allowed edit set** at `./FORGE_ALLOWED_FILES.txt`

## What to do

Apply every accepted claim in the sharpened spec, in order. For each claim, edit only the files named in it. Do not touch any file outside the allowed edit set. Do not touch any `*.test.ts` file.

You may NOT run tests — `node_modules` is not present in this directory. Trust the spec: every claim has already been verified against the test suite for text preservation, and rejected claims that would break tests are documented in the spec's Rejected section.

## Do not

- Add claims that are not in the spec
- Re-open claims the spec rejected (they were rejected for reasons documented in the spec)
- Produce commentary, summary, or documentation files
- Change the public API surface

## Output

Your output is the modified source tree at the current working directory. No markdown report, no explanation — just the edits.

When you are done, write a one-line summary to `./IMPLEMENT_SUMMARY.md`: `Applied claims: N/M` where N is the count you applied and M is the count in the spec.
