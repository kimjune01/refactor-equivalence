## Build: PASS
## Tests: FAIL

## Finding F1 — Registered workspace tests fail
**Severity**: blocker
**File**: packages/cli/src/ui/AppContainer.test.tsx:3964
**What**: `npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'` exits 1. The CLI workspace has 8 failed test files and 17 failed tests, including the model steering integration test, standard-mode refresh/clear behavior, folder trust overflow hints, dense tool diff rendering, shell/tool truncation, and tool overflow direction checks. Representative failures from the log:

```text
FAIL  src/integration-tests/modelSteering.test.tsx > Model Steering Integration > should steer the model using a hint during a tool turn
FAIL  src/ui/AppContainer.test.tsx > AppContainer State Management > Submission Handling > resets expansion state on submission when not in alternate buffer
FAIL  src/ui/components/FolderTrustDialog.test.tsx > FolderTrustDialog > should truncate discovery results when they exceed maxDiscoveryHeight
FAIL  src/ui/components/messages/DenseToolMessage.test.tsx > DenseToolMessage > renders correctly for file diff results with stats
FAIL  src/ui/components/messages/ShellToolMessage.test.tsx > <ShellToolMessage /> > Height Constraints > fully expands in standard mode when availableTerminalHeight is undefined
FAIL  src/ui/components/messages/ToolResultDisplayOverflow.test.tsx > ToolResultDisplay Overflow > shows the head of the content when overflowDirection is bottom (string)
Test Files  8 failed | 427 passed (435)
Tests  17 failed | 6427 passed | 4 skipped (6448)
TEST_EXIT:1
```

Required command records:

```text
Build exit code: 0
Test exit code: 1
```

Tail 50 lines of `npm run build`:

```text
> @google/gemini-cli-core@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js

Running chrome devtools MCP bundling...

> @google/gemini-cli-core@0.36.0-nightly.20260317.2f90b4653 bundle:browser-mcp
> node scripts/bundle-browser-mcp.mjs

Successfully copied files.
Copied documentation to dist/docs
Building other workspaces in parallel...

> @google/gemini-cli-sdk@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:client && tsc -p tsconfig.build.json


> @google/gemini-cli@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:dev


> @google/gemini-cli-test-utils@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli-a2a-server@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build:dev
> node esbuild.js


> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build:client
> node esbuild.client.js

Successfully copied files.
Successfully copied files.
[watch] build started
Successfully copied files.
Successfully copied files.
[watch] build finished
BUILD_EXIT:0
```

Tail 50 lines of `npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'`:

```text
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24512/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
[Routing] Selected model: gemini-2.0-flash (Source: agent-router/override, Latency: 0ms)
	[Routing] Reasoning: Routing bypassed by forced model directive. Using: gemini-2.0-flash

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Experiments loaded {
  experimentIds: [],
  flags: []
}

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24512/packages/sdk/.geminiignore, continue without it.

(node:86136) MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 model-changed listeners added to [CoreEventEmitter]. MaxListeners is 10. Use emitter.setMaxListeners() to increase limit
(Use `node --trace-warnings ...` to show where the warning was created)
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24512/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24512/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 586ms
   ✓ GeminiCliAgent Integration > resumes a session  528ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  01:46:16
   Duration  2.10s (transform 631ms, setup 0ms, collect 5.37s, tests 818ms, environment 0ms, prepare 176ms)


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/cleanroom-v2/24512/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 12ms
 ✓ src/extension.test.ts (11 tests) 17ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 47ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  01:46:19
   Duration  1.50s (transform 646ms, setup 0ms, collect 2.63s, tests 75ms, environment 0ms, prepare 126ms)

TEST_EXIT:1
```

**Fix**: Restore the expected standard-mode overflow/truncation and refresh behavior, then rerun the full registered workspace test command until it exits 0.

## Finding F2 — Startup MouseProvider/ScrollProvider cleanup was not applied
**Severity**: warning
**File**: packages/cli/src/interactiveCli.tsx:34
**What**: Accepted claim C2 says `AppWrapper` must remove the outer `MouseProvider` and `ScrollProvider` wrappers and their imports because `AppContainer` owns the dynamic providers. The current file still imports and renders both providers:

```text
34	import { MouseProvider } from './ui/contexts/MouseContext.js';
44	import { ScrollProvider } from './ui/contexts/ScrollProvider.js';
106	            <MouseProvider mouseEventsEnabled={mouseEventsEnabled}>
107	              <TerminalProvider>
108	                <ScrollProvider>
...
122	                </ScrollProvider>
123	              </TerminalProvider>
124	            </MouseProvider>
```

**Fix**: Remove the startup-level `MouseProvider` and `ScrollProvider` wrappers and unused imports, leaving the rest of the provider tree intact.

## Finding F3 — Dead `isStatic` VirtualizedList prop remains
**Severity**: warning
**File**: packages/cli/src/ui/components/shared/VirtualizedList.tsx:34
**What**: Accepted claim C3 says to remove `isStatic` from `VirtualizedListProps`, stop destructuring it, and simplify observer guards to `!fixedItemHeight`. The current file still exposes and uses `isStatic`:

```text
34	  isStatic?: boolean;
127	    isStatic,
449	        if (!isStatic && !fixedItemHeight && !observedNodes.current.has(node)) {
456	        if (!isStatic && !fixedItemHeight) {
```

**Fix**: Remove `isStatic` from the prop surface/destructuring and simplify the guards to depend only on `fixedItemHeight`.

## Finding F4 — ScrollableList still redeclares inherited props
**Severity**: warning
**File**: packages/cli/src/ui/components/shared/ScrollableList.tsx:31
**What**: Accepted claim C4 says `ScrollableListProps` should keep only `hasFocus` as the prop specific to `ScrollableList`, and remove redeclarations of inherited `VirtualizedListProps` including `width`, `scrollbar`, `stableScrollback`, `copyModeEnabled`, `isStatic`, and `fixedItemHeight`. The current interface still redeclares them:

```text
31	interface ScrollableListProps<T> extends VirtualizedListProps<T> {
32	  hasFocus: boolean;
33	  width?: string | number;
34	  scrollbar?: boolean;
35	  stableScrollback?: boolean;
36	  copyModeEnabled?: boolean;
37	  isStatic?: boolean;
38	  fixedItemHeight?: boolean;
39	}
```

**Fix**: Remove the duplicate inherited declarations and remove `isStatic` in line with C3.

## Finding F5 — Draft readiness comment remains unchanged
**Severity**: warning
**File**: packages/cli/src/ui/components/shared/VirtualizedList.tsx:470
**What**: Accepted claim C5 says to replace the draft multi-line readiness comment with a concise invariant. The current comment still contains the draft "Wait" and repeated "MUST" language:

```text
470	  // Always evaluate shouldBeStatic, width, etc. if we have a known width from the prop.
471	  // If containerHeight or containerWidth is 0 we defer rendering unless a static render or defined width overrides.
472	  // Wait, if it's not static and no width we need to wait for measure.
473	  // BUT the initial render MUST render *something* with a width if width prop is provided to avoid layout shifts.
474	  // We MUST wait for containerHeight > 0 before rendering, especially if renderStatic is true.
475	  // If containerHeight is 0, we will misclassify items as isOutsideViewport and permanently print them to StaticRender!
```

**Fix**: Replace the draft commentary with the concise invariant described in C5.
