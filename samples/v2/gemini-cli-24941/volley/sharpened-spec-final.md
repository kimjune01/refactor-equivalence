## Accepted Claims

### C1 — Correct the component helper description
**File**: evals/component-test-helper.ts:101
**Change**: Update the JSDoc above `componentEvalTest` to describe it as a helper for component-level evaluations, not behavioral evaluations.
**Goal link**: The goal explicitly adds component-level eval support; the current comment names the wrong eval category.
**Justification**: Correct terminology makes the helper's purpose match the new eval taxonomy without changing runtime behavior.

### C2 — Return the initialized component config
**File**: evals/component-test-helper.ts:67
**Change**: Change `ComponentRig.initialize()` to return the initialized `Config`, and in `componentEvalTest` use `const config = await rig.initialize()` for `setup` and `assert` instead of `rig.config!`.
**Goal link**: Component-level evals are meant to exercise backend components through an initialized `Config`; returning that object expresses the helper contract directly.
**Justification**: This removes the unnecessary undefined state/non-null assertions while preserving the existing initialization and cleanup flow.

### C3 — Make the component Config import type-only
**File**: evals/component-test-helper.ts:20
**Change**: Move `Config` from the value import list to a `type Config` import from `@google/gemini-cli-core`.
**Goal link**: The component helper should expose a narrow component-eval surface rather than implying a runtime dependency on the `Config` symbol.
**Justification**: The file only uses `Config` as a TypeScript type, so a type-only import is more idiomatic under the repo's `verbatimModuleSyntax` configuration and has no runtime effect.

### C4 — Make the app helper BaseEvalCase import type-only
**File**: evals/app-test-helper.ts:15
**Change**: Import `BaseEvalCase` as `type BaseEvalCase` from `./test-helper.js` instead of as a value.
**Goal link**: The shared base eval case is type-level structure for the generalized eval helpers.
**Justification**: The import is only used in the `AppEvalCase` interface, so making it type-only removes an accidental runtime import without changing behavior.

## Rejected

- Add a `suite` or `category` argument to `runEval`, `evalTest`, `appEvalTest`, and `componentEvalTest`: this would change the eval helper API and require coordinated updates across eval call sites rather than a bounded behavior-preserving refactor.
- Replace `RUN_EVALS` with named suite selection in `package.json` scripts or `evals/vitest.config.ts`: this is closer to feature work for on-demand suite execution and would change CI/local selection behavior.
- Edit existing `*.eval.ts` files to tag behavioral, hero, or component suites: per Finding F1, `*.eval.ts` files are not categorically outside the allowed file set; this specific tagging change is rejected because it would introduce suite/category metadata and alter eval selection semantics beyond a bounded behavior-preserving cleanup.
- Remove `await prepareLogDir(evalCase.name)` from `componentEvalTest`: although the return value is unused, deleting it would remove an observable filesystem side effect for component eval runs.
- Split `prepareWorkspace` into separate file-writing and git-initialization helpers for component evals: that would alter workspace setup assumptions for evals that rely on a git repository, so it is not a safe behavior-preserving cleanup.
