## Accepted Claims

### C2 — Remove shadowed startup providers
**File**: packages/cli/src/interactiveCli.tsx:106
**Change**: In `AppWrapper`, remove the outer `MouseProvider` and `ScrollProvider` wrappers and their now-unused imports, leaving `TerminalProvider`, `OverflowProvider`, and the rest of the tree unchanged.
**Goal link**: The goal adds an explicit mouse-mode toggle to manage scrollback behavior cleanly.
**Justification**: `AppContainer` now owns the dynamic `MouseProvider` and `ScrollProvider` around `<App />`, so the startup-level providers are shadowed for the rendered UI and add an extra context layer that does not serve the new toggle behavior.

### C3 — Drop the unused `isStatic` VirtualizedList prop
**File**: packages/cli/src/ui/components/shared/VirtualizedList.tsx:34
**Change**: Remove `isStatic` from `VirtualizedListProps`, remove it from props destructuring, and simplify the observer guards from `!isStatic && !fixedItemHeight` to `!fixedItemHeight`.
**Goal link**: The goal's static rendering behavior is driven by TerminalBuffer item classification and fixed-height list optimization.
**Justification**: No production call site passes `isStatic`, while `renderStatic`, `isStaticItem`, and `fixedItemHeight` carry the active behavior, so this deletes dead configuration surface without changing rendering.

### C4 — Remove duplicate inherited ScrollableList prop declarations
**File**: packages/cli/src/ui/components/shared/ScrollableList.tsx:31
**Change**: In `ScrollableListProps`, keep only `hasFocus` as the prop specific to `ScrollableList`; remove redeclarations of props still inherited from `VirtualizedListProps`, such as `width`, `scrollbar`, `stableScrollback`, `copyModeEnabled`, and `fixedItemHeight`; and remove `isStatic` because C3 removes it from the underlying `VirtualizedListProps` surface entirely.
**Goal link**: The goal adds TerminalBuffer options to the shared virtualized scrolling path.
**Justification**: Keeping active options defined once in `VirtualizedListProps` makes the propagation from `ScrollableList` to `VirtualizedList` clearer, while deleting `isStatic` consistently from both prop surfaces removes dead configuration introduced by the first-pass refactor.
**Hunt note**: Retained as narrowed for F2 because the claim no longer describes `isStatic` as inherited after C3; it explicitly removes `isStatic` from `ScrollableListProps` for the same dead-prop reason as C3.

### C5 — Replace draft readiness commentary with a concise invariant
**File**: packages/cli/src/ui/components/shared/VirtualizedList.tsx:470
**Change**: Replace the multi-line draft comment above `isReady` with a short statement that rendering is deferred until height is known, except in tests or when a numeric width gives Ink enough information, to avoid classifying items as static before the viewport is measured.
**Goal link**: The goal relies on static rendering for history items to reduce flicker.
**Justification**: The current comment preserves first-pass reasoning notes, including "Wait" and repeated "MUST" language, while a concise invariant documents the static-rendering guard without accidental noise.

## Rejected

- Make MainContent test the two rendering modes explicitly by removing `useAlternateBuffer` and deriving the scrollable-list branch directly from `config.getUseAlternateBuffer()` / `config.getUseTerminalBuffer()`: rejected because hunt finding F1 is a blocker. Existing `MainContent` tests mock `useAlternateBuffer()` to force rendering modes, while default test config leaves `useTerminalBuffer` at its true default, so the proposed direct config read would route mocked normal-buffer tests through the scrollable-list branch.
- Rename `useAlternateBuffer` / `isAlternateBufferEnabled` across the codebase to a combined rendering-mode name: this would be the right conceptual cleanup, but current call sites include files outside `allowed-files.txt`, so it is out of scope.
- Expand `MainContent`'s `isStaticItem` to include noninteractive history entries beyond the header: the nearby TODO explicitly marks this as future work and it could change focus, scrolling, or clickable behavior for messages.
- Remove the `renderProcess` setting or force `terminalBuffer` on unconditionally: those changes would contradict the goal's settings updates and change observable configuration behavior.
- Remove the ResizeObserver cleanup effects added across UI components: those effects address resource cleanup and deleting them could reintroduce leaks or stale observers.
- Revert `copyMode` from `f9` back to `ctrl+s`: the new mouse-mode toggle intentionally takes `ctrl+s`, so reverting the binding would change the shortcut behavior described by the goal.
