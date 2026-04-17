# Hunt-code — adversarial review of merged refactor (iterative, full build + tests)

You are adversarially reviewing a merged refactor's code. Find real defects — behavior changes, broken invariants, build failures, test failures, type errors, API-shape issues, spec non-compliance. Style quibbles are out of scope.

## Inputs

- **Repo root**: `{CLEANROOM}/` (current working directory; contains `node_modules`, can build + test)
- **Goal**: `{TRIAL_DIR}/goal/GOAL.md`
- **Sharpened spec**: `{TRIAL_DIR}/volley/sharpened-spec-final.md`
- **Original PR artifact**: `{TRIAL_DIR}/inputs/diff-base-to-test.patch`
- **Allowed edit set**: `{TRIAL_DIR}/inputs/allowed-files.txt`
- **C_test baseline**: git HEAD~ in the cleanroom (post-blind-blind merge is current HEAD; C_test is parent).

## What to look for

1. **Build failure.** `npm run build` (or repo-equivalent) must succeed. A build failure is a **blocker**.
2. **Test failure.** The registered test command must pass. Any failing test is a **blocker**.
3. **Behavior change.** Observable changes in strings, control flow, return values, side-effects — relative to C_test. Blocker if present.
4. **Type error.** Unreachable cases under narrowed unions, incorrect casts, API-shape mismatch. Blocker if present.
5. **Unimplemented claim.** Accepted claims not applied. Warning (reconcile-time blocker would already have caught spec-level defects).
6. **Out-of-scope edit.** Files outside allowed set or any test file. Blocker.
7. **Goal drift.** Edits that change the PR's intent relative to C_test. Warning.

## Commands you MUST run

Before writing findings:

```bash
# The working directory has NO .git — do NOT use git commands.
# Instead, compare against the cleanroom baseline by reading files directly.
# The allowed-edit-set file lists which files the implementer was permitted to change.
cat {TRIAL_DIR}/inputs/allowed-files.txt             # files the implementer may have changed
{BUILD_CMD}                                         # full build, not just typecheck
{TEST_CMD}                                          # full registered test command
```

Record exit codes and tail 50 lines of each in your findings. If either fails, that becomes finding F1 (blocker) automatically.

**Evidence requirement**: For any "claim not applied" or "behavior change" finding, you MUST quote the exact current lines from the file showing the unchanged/problematic code. Do not cite a `git diff` — there is no git history in this directory. If you cannot quote the evidence, do not report the finding.

## Output

Write findings to `{TRIAL_DIR}/gates/hunt-code-round-{N}.md`. If zero defects, write:

```
## Build: PASS
## Tests: PASS
No findings.
```

Otherwise:

```
## Build: PASS | FAIL
## Tests: PASS | FAIL

## Finding F1 — <title>
**Severity**: blocker | warning | note
**File**: <path>:<line>
**What**: <defect>
**Fix**: <what to change>
```

Do not edit source.
