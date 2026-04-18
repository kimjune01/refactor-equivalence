## Applied Claims

### C1 — Centralize inbox source validation
**File**: `packages/core/src/commands/memory.ts`
- Added `resolveInboxSkillSource()` private helper that encapsulates `isValidInboxSkillDirName` check, inbox directory lookup, `sourcePath` construction, and `fs.access` existence check.
- Replaced the duplicated validation blocks in `moveInboxSkill()` and `dismissInboxSkill()` with calls to `resolveInboxSkillSource()`, preserving existing failure messages.

### C2 — Reuse the feedback block in SkillInboxDialog
**File**: `packages/cli/src/ui/components/SkillInboxDialog.tsx`
- Added local `FeedbackMessage` component that renders the feedback `<Box><Text>` block with the same colors, symbols, and spacing.
- Replaced both the list-phase and action-phase feedback JSX blocks with `<FeedbackMessage feedback={feedback} />`.

### C3 — Reuse the dialog frame markup
**File**: `packages/cli/src/ui/components/SkillInboxDialog.tsx`
- Added local `DialogFrame` component that wraps children in the bordered `Box` with shared props (`flexDirection`, `borderStyle`, `borderColor`, `paddingX`, `paddingY`, optional `width`).
- Replaced the loading, empty, and main dialog `Box` wrappers with `<DialogFrame>`.

### C4 — Remove the redundant custom dialog return type
**File**: `packages/cli/src/ui/commands/memoryCommand.ts`
- Removed the `OpenCustomDialogActionReturn` import.
- Simplified the `/memory inbox` action return type from `OpenCustomDialogActionReturn | SlashCommandActionReturn | void` to `SlashCommandActionReturn | void`, since `SlashCommandActionReturn` already includes `OpenCustomDialogActionReturn`.
