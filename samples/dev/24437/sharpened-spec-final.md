# Sharpened refactor spec — PR 24437 (final, post-Volley)

Target: `/tmp/refactor-eq-workdir/cleanroom/24437` at C_test (ffd11f5f).
Volley: round 1 codex draft → round 2 opus review → converged.

## Input artifacts (at repo root)

- `REFACTOR_SPEC.md` — free-form spec
- `FORGE_INPUT_DIFF.patch` — the diff the LLM is refactoring
- `FORGE_ALLOWED_FILES.txt` — mechanical edit whitelist

## Verification command (run after every claim)

```bash
cd /tmp/refactor-eq-workdir/cleanroom/24437 \
  && npm run build --workspace @google/gemini-cli-core \
  && cd packages/core \
  && npx vitest run --exclude '**/sandboxManager.integration.test.ts'
```

Expected: 338 files / 6574 tests pass / 28 skipped.

## Accepted claims (apply in order)

### Claim 1 — Route `COMPLETE_TASK_TOOL_NAME` import through `tool-names.js`

**File**: `packages/core/src/agents/local-executor.ts:77`

Change the import source from `../tools/definitions/base-declarations.js` to `../tools/tool-names.js`. The latter re-exports the same symbol and is the convention used by every `*_TOOL_NAME` consumer *outside* `packages/core/src/tools/` (15+ call sites across agents, scheduler, prompts, telemetry, config). The scope of this claim is `local-executor.ts` only; files inside `packages/core/src/tools/` that sit as siblings to `tool-names.ts` (e.g., `complete-task.ts`) are free to import from `./definitions/base-declarations.js` directly and are not rewritten by this claim.

Why: match the surrounding code's patterns — the spec's focus explicitly calls this out.

### Claim 2 — Extract `formatSubmittedOutput` module helper in `complete-task.ts`

**File**: `packages/core/src/tools/complete-task.ts`

`CompleteTaskInvocation.execute` duplicates a five-line string-or-JSON serialization block in both the `outputConfig` and default-result branches:

```ts
submittedOutput =
  typeof outputValue === 'string'
    ? outputValue
    : JSON.stringify(outputValue, null, 2);
```

Add a module-scope helper above the class:

```ts
function formatSubmittedOutput(output: unknown): string {
  return typeof output === 'string' ? output : JSON.stringify(output, null, 2);
}
```

Use it in both branches. The helper is called twice, so the "inline single-use helpers" guidance does not apply.

Why: removes duplicated serialization logic from the two output paths without changing any result string.

### Claim 3 — `RESULT_PARAM` module constant in `complete-task.ts`

**File**: `packages/core/src/tools/complete-task.ts`

Add `const RESULT_PARAM = 'result';` at module scope. Replace exactly these four programmatic occurrences that use `'result'` as the fallback parameter name:

1. `buildParameterSchema` — the schema object property key: change `properties: { result: {...} }` to `properties: { [RESULT_PARAM]: {...} }`.
2. `buildParameterSchema` — `required: ['result']` → `required: [RESULT_PARAM]`.
3. `validateToolParamValues` — `params['result']` → `params[RESULT_PARAM]`.
4. `CompleteTaskInvocation.execute` — `this.params['result']` → `this.params[RESULT_PARAM]`.

Explicitly do NOT change:
- User-facing error text (e.g. `'Missing required "result" argument…'`) — the word "result" there is narrative, not a programmatic identifier.
- The `description` string for the result property in the schema.
- The return display strings `'Result submitted and task completed.'`.

Why: the parameter name is repeated across schema, validation, and execution; a local constant removes that duplication without changing the public API.

### Claim 4 — Drop the unused catch binding in `local-executor.ts`

**File**: `packages/core/src/agents/local-executor.ts` (JSON parse block around line ~1051)

```ts
} catch (_) {        // before
} catch {            // after
```

The binding is never read. Modern TypeScript supports optional catch binding.

Why: remove unnecessary local state introduced by the new parsing branch.

### Claim 5 — Use `COMPLETE_TASK_TOOL_NAME` constant in the missing-result error in `complete-task.ts`

**File**: `packages/core/src/tools/complete-task.ts` (around line 102)

Before:
```ts
return 'Missing required "result" argument. You must provide your findings when calling complete_task.';
```

After:
```ts
return `Missing required "result" argument. You must provide your findings when calling ${COMPLETE_TASK_TOOL_NAME}.`;
```

Since `COMPLETE_TASK_TOOL_NAME === 'complete_task'`, the rendered string is byte-identical and the test assertion at `complete-task.test.ts:60` still passes.

Why: the tool name is already imported as a constant elsewhere in this file; using it here removes a duplicated literal source of truth.

## Rejected

- **Remove `params[outputName] === undefined` and empty-result checks in `CompleteTaskTool.validateToolParamValues`.** Codex Round 1 Claim 2. Would break `local-executor.test.ts:1314/1321/1344` and `complete-task.test.ts:60` which assert exact error messages (`"Missing required argument 'finalResult' for completion."` and `'Missing required "result" argument. You must provide your findings when calling complete_task.'`). The custom checks are what produce those strings.
- **Extract the `functionCall.args` JSON-parse block in `local-executor.ts` into a helper.** The block is used once. The spec explicitly says "inline helpers that are called once."
- **Restructure `buildParameterSchema` to merge both branches.** The IIFE-in-ternary or equivalent alternatives are cleverer, not clearer. The current if/else is idiomatic TypeScript.
- **Tighten `buildParameterSchema`'s return type from `unknown` to a concrete schema type.** Type polish, not complexity reduction. Out of refactor-v1 scope.
- **Change `let args` to `const`.** The binding is reassigned in later branches.
- **Replace `||` with `??`.** Behaviorally equivalent here and would diverge from the surrounding file's conventions.
- **Re-introduce inline `complete_task` handling.** Would undo the main intent of the diff.
- **Reorder `registerTool(CompleteTaskTool)` relative to `sortTools()`.** Could change tool declaration ordering, not behavior-preserving.
- **Remove the `complete_task` allow rule from `read-only.toml`.** Policy decisions are observable behavior.
- **Remove or add to `CompleteTaskInvocation`'s export status.** Public API change risk, out of scope.
- **Touch any `*.test.ts` file.** Explicitly disallowed.

## Convergence note

Round 1 (codex): 6 claims. 1 rejected in round 2 as test-regressing (Claim 2). 5 accepted.

Round 2 (opus): no new claims. Spec is stable.

Proceed to Hunt-spec.
