# Volley — goal-anchored refactor spec

You are sharpening a refactor spec into specific, testable claims against a concrete goal. Do not edit code. Produce a markdown document.

## Inputs

- **Goal** at `{TRIAL_DIR}/goal/GOAL.md` — concatenation of: linked issue(s) title + body (if any), PR title, PR body. This is what the PR is *trying* to accomplish.
- **Artifact** at `{TRIAL_DIR}/inputs/diff-base-to-test.patch` — the first-pass implementation that made tests pass. A working draft, not the final shape.
- **Allowed edit set** at `{TRIAL_DIR}/inputs/allowed-files.txt` — source files changed from C_base to C_test (post-exclusion). You may only propose edits to files in this set.
- **Cleanroom source tree** rooted at `{CLEANROOM}/` — the repo at C_test. You may grep it for patterns, imports, and idioms.

Read all inputs. You may grep the wider codebase.

## Task

Produce a sharpened list of **prescriptive, bounded refactor claims** that, if applied, would move the artifact closer to a cleaner expression of the goal — without changing behavior.

"Closer to the goal" means:
- The implementation expresses the intent of the goal more directly (less accidental structure, fewer indirections that don't serve the goal).
- The code is more idiomatic to the surrounding codebase at C_test.
- Accidental complexity added during the first-pass (helper duplication, stray dead code, over-abstracted for one call site, unnecessary state) is removed.

Each claim must be:
- **Specific**: names a file, a function/block, and the change.
- **Bounded**: one independent change, applicable without forward reference to later claims.
- **Testable against the existing suite**: behavior preserved; the full test suite at C_test continues to pass.
- **Justified against the goal**: one sentence on *which goal aspect* this clarifies and *why* it reduces complexity.
- **Within scope**: only touches files in `allowed-files.txt`; never any `*.test.ts`, `*.test.tsx`, or other test files.

**Empty Accepted Claims is permitted.** If the artifact is already a clean expression of the goal and no prescriptive changes are warranted, say so explicitly. Do not invent claims.

List rejected candidate claims with reasons (e.g., "would cross a public API boundary", "out of allowed edit set", "would change observable behavior in test X").

## Output

Write to `{TRIAL_DIR}/volley/round-{N}-claims.md`, where N is passed in the task environment.

Format:

```
## Accepted Claims

### C1 — <title>
**File**: <path>:<line>
**Change**: <prescriptive description>
**Goal link**: <which aspect of the goal this clarifies>
**Justification**: <one sentence>

### C2 — ...

## Rejected

- <claim candidate>: <reason>
```

No code edits. No commentary outside the document.
