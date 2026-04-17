## Build: PASS
## Tests: FAIL

## Finding F1 — macOS sandbox tests fail after path expansion reaches seatbelt profile
**Severity**: blocker
**File**: packages/core/src/sandbox/macos/MacOsSandboxManager.ts:142
**What**: The required workspace test command exits 1. Four `MacOsSandboxManager.prepareCommand` tests fail because `buildSeatbeltProfile` now receives expanded macOS realpath aliases in `allowedPaths` / `forbiddenPaths`; e.g. expected `['/tmp/allowed1', '/tmp/allowed2']`, but received `['/tmp/allowed1', '/private/tmp/allowed1', '/tmp/allowed2', '/private/tmp/allowed2']`. Current code forwards the centralized resolved path sets directly:

```ts
    const sandboxArgs = buildSeatbeltProfile({
      workspace: this.options.workspace,
      allowedPaths: [
        ...resolvedPaths.policyAllowed,
        ...(this.options.includeDirectories || []),
      ],
      forbiddenPaths: resolvedPaths.forbidden,
```

Failing tests:

```text
FAIL  src/sandbox/macos/MacOsSandboxManager.test.ts > MacOsSandboxManager > prepareCommand > allowedPaths > should parameterize allowed paths and normalize them
FAIL  src/sandbox/macos/MacOsSandboxManager.test.ts > MacOsSandboxManager > prepareCommand > forbiddenPaths > should parameterize forbidden paths and explicitly deny them
FAIL  src/sandbox/macos/MacOsSandboxManager.test.ts > MacOsSandboxManager > prepareCommand > forbiddenPaths > explicitly denies non-existent forbidden paths to prevent creation
FAIL  src/sandbox/macos/MacOsSandboxManager.test.ts > MacOsSandboxManager > prepareCommand > forbiddenPaths > should override allowed paths if a path is also in forbidden paths
```

**Fix**: Reconcile the macOS manager with the intended contract: either preserve the previous seatbelt profile inputs by passing only the textual policy paths here, or update the macOS tests and profile contract if `/private/tmp` alias expansion is now intentionally observable. As submitted, the registered test suite is red.

## Command Results

```text
cat /Users/junekim/Documents/refactor-equivalence/samples/v2/gemini-cli-24834/inputs/allowed-files.txt
exit code: 0
```

```text
npm run build
exit code: 0
tail -50:
> @google/gemini-cli-core@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js

Running chrome devtools MCP bundling...

> @google/gemini-cli-core@0.36.0-nightly.20260317.2f90b4653 bundle:browser-mcp
> node scripts/bundle-browser-mcp.mjs

Successfully copied files.
Copied documentation to dist/docs
Building other workspaces in parallel...

> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:dev


> @google/gemini-cli-sdk@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:client && tsc -p tsconfig.build.json


> @google/gemini-cli@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli-a2a-server@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli-test-utils@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build:dev
> node esbuild.js


> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build:client
> node esbuild.client.js

[watch] build started
[watch] build finished
Successfully copied files.
Successfully copied files.
Successfully copied files.
Successfully copied files.
```

```text
npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'
exit code: 1
tail -50:
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24834/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24834/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
[Routing] Selected model: gemini-2.0-flash (Source: agent-router/override, Latency: 0ms)
	[Routing] Reasoning: Routing bypassed by forced model directive. Using: gemini-2.0-flash

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Experiments loaded {
  experimentIds: [],
  flags: []
}

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24834/packages/sdk/.geminiignore, continue without it.

(node:51864) MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 model-changed listeners added to [CoreEventEmitter]. MaxListeners is 10. Use emitter.setMaxListeners() to increase limit
(Use `node --trace-warnings ...` to show where the warning was created)
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24834/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24834/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 676ms
   ✓ GeminiCliAgent Integration > resumes a session  517ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  01:24:38
   Duration  2.35s (transform 700ms, setup 0ms, collect 6.00s, tests 1.13s, environment 0ms, prepare 182ms)


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/cleanroom-v2/24834/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 12ms
 ✓ src/extension.test.ts (11 tests) 19ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 51ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  01:24:40
   Duration  1.65s (transform 687ms, setup 0ms, collect 2.92s, tests 83ms, environment 0ms, prepare 131ms)
```
