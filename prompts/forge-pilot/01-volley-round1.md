# Volley round 1: sharpen refactor spec

You are sharpening a refactor spec into specific, testable claims. Do not edit code. Produce a markdown document.

## Inputs

- **Spec** at `/tmp/refactor-eq-workdir/cleanroom/24483/REFACTOR_SPEC.md`
- **Diff to refactor** at `/tmp/refactor-eq-workdir/cleanroom/24483/FORGE_INPUT_DIFF.patch`
- **Allowed edit set** at `/tmp/refactor-eq-workdir/cleanroom/24483/FORGE_ALLOWED_FILES.txt`
- **Source tree** rooted at `/tmp/refactor-eq-workdir/cleanroom/24483/`

Read all of them. You may grep the wider codebase for patterns.

## Task

Produce a sharpened list of refactoring claims. Each claim must be:
- **Specific**: names a file, a function or block, and the change.
- **Testable**: behavior unchanged, so the full test suite still passes.
- **Bounded**: each claim is one independent change.
- **Justified**: one sentence on why it reduces complexity.
- **Within the allowed edit set**: never touches files outside `FORGE_ALLOWED_FILES.txt` and never touches any `*.test.ts` or `*.test.tsx` file.

List rejected claims with reasons. Order by confidence.

## Output

Write to `/tmp/refactor-eq-workdir/forge/24483/volley-round1.md`. No code edits.
