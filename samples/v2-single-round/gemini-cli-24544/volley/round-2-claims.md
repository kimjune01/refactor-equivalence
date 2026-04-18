## Accepted Claims

### C1 — Centralize inbox source validation
**File**: packages/core/src/commands/memory.ts:195
**Change**: Extract the duplicated `isValidInboxSkillDirName` check, inbox directory lookup, `sourcePath` construction, and `fs.access(sourcePath)` existence check used by `moveInboxSkill` and `dismissInboxSkill` into a private helper in the same file, and have both functions use that helper while preserving the existing failure messages.
**Goal link**: This clarifies the accept/dismiss actions for extracted inbox skills by making "find the inbox skill or return the same error" one shared precondition instead of two hand-written blocks.
**Justification**: The goal adds two operations over the same inbox item, and sharing their identical validation removes accidental duplication without changing move, dismiss, or error behavior covered by the existing memory command tests.

### C2 — Reuse the feedback block in SkillInboxDialog
**File**: packages/cli/src/ui/components/SkillInboxDialog.tsx:313
**Change**: Add a small local helper component or render function for the repeated feedback `<Box><Text>` block, then replace both the list-phase and action-phase copies with that helper using the same `feedback` data, colors, symbols, and spacing.
**Goal link**: This clarifies the interactive review flow by treating operation feedback as one UI concern shared by both dialog phases.
**Justification**: The first-pass dialog duplicates the same JSX twice, and factoring it locally reduces noise around the actual list/action state machine while preserving the rendered output expected by the dialog tests.

### C3 — Reuse the dialog frame markup
**File**: packages/cli/src/ui/components/SkillInboxDialog.tsx:232
**Change**: Extract the repeated bordered `Box` wrapper props (`flexDirection`, `borderStyle`, `borderColor`, `paddingX`, `paddingY`, and optional `width`) into a local `DialogFrame` helper component and use it for the loading, empty, and main dialog returns.
**Goal link**: This keeps the `/memory inbox` dialog focused on loading, empty, list, and action states rather than repeated Ink frame styling.
**Justification**: The three return branches use the same frame shape, so a local wrapper removes presentational duplication without changing interaction behavior or command semantics.

### C4 — Remove the redundant custom dialog return type
**File**: packages/cli/src/ui/commands/memoryCommand.ts:17
**Change**: Drop the `OpenCustomDialogActionReturn` import and simplify the `/memory inbox` action annotation to `SlashCommandActionReturn | void`, since `SlashCommandActionReturn` already includes custom dialog returns.
**Goal link**: This clarifies the command entry point for the inbox feature by relying on the existing slash-command return union instead of restating one member of it.
**Justification**: The explicit union adds type-level indirection for a single command action and can be removed without affecting runtime behavior or the existing `/memory inbox` command tests.

## Rejected

- Move inbox core helpers from `packages/core/src/commands/memory.ts` into a new dedicated source file: rejected because the allowed edit set does not include a new file path, and the task restricts proposed edits to files already listed in `allowed-files.txt`.
- Remove the `experimental.memoryManager` guard from `/memory inbox`: rejected because it would change observable command behavior and contradict tests that expect the disabled-manager informational message.
- Enable project installation even when `config.isTrustedFolder()` is false: rejected because it would change the dialog's trust-gated behavior and weaken the destination constraint exercised by `SkillInboxDialog.test.tsx`.
- Replace copy-then-remove in `moveInboxSkill` with `fs.rename`: rejected because it can change behavior across filesystems and does not preserve the current "copy to destination, then remove from inbox" semantics described in the goal.
- Revert the unrelated context manager and dependency changes from the patch wholesale: rejected because those changes cross broader public API and dependency boundaries, are not a bounded behavior-preserving inbox refactor claim, and are not justified solely by the `/memory inbox` goal.
