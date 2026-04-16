# Volley Round 1: Sharpened Refactoring Claims

Note: `REFACTOR_SPEC.md` summarizes a `complete_task` extraction, but `FORGE_INPUT_DIFF.patch` in this checkout changes UI confirmation layout, input state plumbing, sandbox path handling, and related snapshots. The claims below are based on the actual diff and are limited to files in `FORGE_ALLOWED_FILES.txt`, excluding `*.test.ts` and `*.test.tsx`.

## Accepted Claims

1. **`packages/cli/src/ui/components/messages/ToolConfirmationMessage.tsx`, `getOptions` block:** Replace the `useCallback` that rebuilds confirmation options with a `useMemo` value, and use that memoized `options` array both in the body-content memo and in `availableBodyContentHeight`.
   - **Behavior claim:** The rendered radio options, ordering, labels, values, and initial selection remain identical, and the full suite still passes.
   - **Why:** This removes a function wrapper and eliminates duplicate option construction during the same render.

2. **`packages/cli/src/ui/components/messages/ToolConfirmationMessage.tsx`, common confirmation option construction in `getOptions`:** Introduce small local push helpers for the repeated "Allow once", trusted-session, permanent-approval, and cancel options while preserving each type-specific label/value pair.
   - **Behavior claim:** Each confirmation type still receives the same set of `RadioSelectItem<ToolConfirmationOutcome>` entries under the same trust and permanent-approval conditions, and the full suite still passes.
   - **Why:** The diff introduced near-identical option-building branches for `sandbox_expansion`, `exec`, `info`, and `mcp`; local helpers reduce duplication without changing public API or component boundaries.

3. **`packages/cli/src/ui/components/messages/ToolConfirmationMessage.tsx`, body-content `useMemo`:** Compute `const bodyHeight = availableBodyContentHeight()` once inside the memo and reuse it for `AskUserDialog`, `ExitPlanModeDialog`, `DiffRenderer`, and the exec command body, with the exec branch applying its redirection-warning subtraction to a local copy.
   - **Behavior claim:** The same available height values are passed to child components and `MaxSizedBox`, including redirection-warning adjustments, and the full suite still passes.
   - **Why:** This removes repeated calls to a layout calculation whose inputs do not change within the memo body.

4. **`packages/cli/src/ui/components/messages/ToolConfirmationMessage.tsx`, exec redirection-warning block:** Lift the redirection tip text into a `REDIRECTION_WARNING_TIP_TEXT` constant or local constant computed once, and use it for both height calculation and rendering.
   - **Behavior claim:** The displayed redirection warning text and calculated wrapped-line height remain unchanged, and the full suite still passes.
   - **Why:** The block currently couples layout math to an inline string built separately from the rendered JSX, making the height accounting harder to audit.

5. **`packages/cli/src/ui/components/ToolConfirmationQueue.tsx`, component return block:** Remove the `const content = (...)` temporary and return the JSX directly.
   - **Behavior claim:** The component output is identical for all confirmation types, and the full suite still passes.
   - **Why:** The temporary is assigned once and immediately returned, so it adds indirection without reuse.

6. **`packages/cli/src/ui/components/shared/MaxSizedBox.tsx`, hidden-lines message rendering:** Replace the duplicated top and bottom hidden-lines `<Text>` ternaries with one local renderer that takes `"first"` or `"last"` and returns the same narrow and wide messages.
   - **Behavior claim:** The exact hidden-lines copy, narrow-width behavior, colors, and `wrap="truncate"` behavior remain unchanged, and the full suite still passes.
   - **Why:** The top and bottom branches differ only by the word `first` versus `last`, so a single renderer makes future changes less error-prone.

7. **`packages/cli/src/ui/utils/CodeColorizer.tsx`, `colorizeCode` success path:** Avoid mutating the destructured `availableHeight` parameter and `lines` array by introducing `initialLines`, `effectiveAvailableHeight`, `visibleLines`, and `hiddenLinesCount`.
   - **Behavior claim:** The same subset of lines is highlighted, the same line numbers are displayed, and the full suite still passes.
   - **Why:** Replacing parameter and array reassignment with named derived values makes the truncation path easier to reason about.

8. **`packages/cli/src/ui/utils/CodeColorizer.tsx`, `colorizeCode` return wrapping:** Factor the repeated "return raw lines, `MaxSizedBox`, or column `Box`" selection into a local helper used by both the highlighted and fallback paths.
   - **Behavior claim:** `returnLines`, alternate-buffer, `MaxSizedBox`, `maxWidth`, and `overflowDirection` behavior remain unchanged, and the full suite still passes.
   - **Why:** The success and catch branches repeat the same wrapping decision, which obscures that only line rendering differs.

9. **`packages/core/src/services/sandboxedFileSystemService.ts`, `readTextFile`/`writeTextFile` spawn setup:** Extract the repeated `spawn(prepared.program, prepared.args, { cwd: this.cwd, env: prepared.env })` block into a private method on `SandboxedFileSystemService`.
   - **Behavior claim:** The prepared command, cwd, env, stdout/stderr handling, stdin handling, and error messages remain unchanged, and the full suite still passes.
   - **Why:** Both read and write paths now perform identical prepared-command spawning, and a private helper reduces duplication without changing the service interface.

10. **`packages/cli/src/ui/contexts/InputContext.tsx`, `useInputState`:** Add an explicit return type of `InputState` to the hook.
    - **Behavior claim:** Runtime behavior and exported API names remain unchanged, and the full suite still passes.
    - **Why:** The hook is newly introduced as shared state plumbing; an explicit return type keeps consumers insulated from accidental inference drift.

## Rejected Claims

1. **Refactor `complete_task` extraction in `packages/core/src/agents/local-executor.ts` or `packages/core/src/tools/complete-task.ts`.**
   - **Reason:** Those files are not listed in `FORGE_ALLOWED_FILES.txt`, even though the high-level spec mentions them.

2. **Edit `evals/update_topic.eval.ts` to remove or reorganize deleted eval coverage.**
   - **Reason:** It is an eval/test file and the task explicitly forbids touching `*.test.ts`/`*.test.tsx`; additionally, the patch deletion itself is behavioral test-suite scope rather than a safe refactor claim.

3. **Edit snapshot files under `packages/cli/src/ui/**/__snapshots__`.**
   - **Reason:** Snapshot updates are generated verification artifacts, not independent refactoring claims, and many are tied to tests.

4. **Refactor `.github/workflows/eval-pr.yml` step ordering.**
   - **Reason:** Workflow execution order and conditions are CI behavior, not a behavior-preserving code simplification with the same test oracle.

5. **Reintroduce or simplify `packages/cli/src/acp/commands/about.ts`.**
   - **Reason:** The diff deletes this command and unregisters it; changing that would alter public ACP command behavior.

6. **Change `SandboxedFileSystemService.sanitizeAndValidatePath` to compare against a resolved workspace path instead of `this.cwd`.**
   - **Reason:** This may be a correctness bug worth investigating, but it changes access-control semantics and is not a bounded behavior-preserving refactor claim.

7. **Remove `InputContext` and put input fields back into `UIStateContext`.**
   - **Reason:** That would reverse the diff’s architectural direction and touch many consumers, exceeding the requested complexity-reduction scope.

8. **Remove `useMemo` around `VirtualizedList` rendered items.**
   - **Reason:** The memo may be performance-motivated and its dependencies are tied to virtualized rendering behavior; without targeted profiling it is not a high-confidence simplification.

9. **Extract a shared `ResizeObserver` hook for `MaxSizedBox`, `VirtualizedList`, and `ToolConfirmationMessage`.**
   - **Reason:** It would add a new abstraction spanning unrelated components; the spec asks not to introduce patterns not already present.

10. **Change `ToolConfirmationQueue` height constants (`4`, `6`, and minimum `4`) into exported constants.**
    - **Reason:** Naming them may improve readability, but exporting or broadening constants would add API surface for a local calculation.
