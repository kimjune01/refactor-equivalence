## Finding F1 — C1 bypasses MainContent's mocked rendering-mode contract
**Severity**: blocker
**Claim**: C1
**What**: Removing the `useAlternateBuffer` import and deriving the branch only from `config.getUseAlternateBuffer()` / `config.getUseTerminalBuffer()` will break existing `MainContent` tests. Those tests deliberately mock `useAlternateBuffer()` to force normal vs scrollable rendering without always overriding `Config`. The default test config does not pass `useTerminalBuffer`, and `Config` defaults it to `true`, so C1 would send cases that currently mock normal-buffer mode through the scrollable-list branch.
**Evidence**: `packages/cli/src/ui/components/MainContent.test.tsx:349` sets `useAlternateBuffer` to `false` in `beforeEach`, and `packages/cli/src/ui/components/MainContent.test.tsx:364` expects normal-buffer output. `packages/cli/src/test-utils/render.tsx:673` builds a default `makeFakeConfig` without `useTerminalBuffer`, while `packages/core/src/config/config.ts:1214` defaults `useTerminalBuffer` to `true`. The current production branch is controlled by `useAlternateBuffer()` at `packages/cli/src/ui/components/MainContent.tsx:38` and `packages/cli/src/ui/components/MainContent.tsx:296`.
**Fix**: Remove C1, or narrow it to keep a test-controllable rendering-mode abstraction instead of replacing the branch with direct config reads.

## Finding F2 — C4 says `isStatic` is inherited after C3 removes it
**Severity**: warning
**Claim**: C4
**What**: C4 describes removing duplicate `ScrollableListProps` declarations for props "already inherited from `VirtualizedListProps` such as ... `isStatic`", but C3 immediately before it removes `isStatic` from `VirtualizedListProps`. Applied in order, `isStatic` is no longer an inherited prop, so C4's rationale is internally inconsistent and can make the implementer guess whether `isStatic` should be kept, removed only because of C3, or restored in `VirtualizedListProps`.
**Evidence**: C3 says to "Remove `isStatic` from `VirtualizedListProps`"; C4 says `isStatic` is already inherited from `VirtualizedListProps`. In the cleanroom source, `isStatic` appears in both `packages/cli/src/ui/components/shared/VirtualizedList.tsx:34` and `packages/cli/src/ui/components/shared/ScrollableList.tsx:37`.
**Fix**: Clarify C4 to say that after C3, `ScrollableListProps` should keep only `hasFocus` and should remove `isStatic` because the underlying `VirtualizedListProps` no longer exposes it, not because it is inherited.
