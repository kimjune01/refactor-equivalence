## Build: PASS
## Tests: PASS

## Finding F1 — Windows proactive npm/yarn/pnpm/bun permissions can make approved commands fail before execution
**Severity**: blocker
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/24460/packages/core/src/sandbox/utils/proactivePermissions.ts:95
**What**: `getProactiveToolSuggestions()` unconditionally adds primary cache directories such as `~/.npm`, `~/.yarn`, `~/.pnpm-store`, and `~/.bun` to write permissions, even when those paths do not exist yet. The current code is:

```ts
  if (normalizedCommand === 'npm' || normalizedCommand === 'npx') {
    readOnlyPaths.push(path.join(home, '.npmrc'));
    primaryCachePaths.push(path.join(home, '.npm'));
    optionalCachePaths.push(path.join(home, '.node-gyp'));
    optionalCachePaths.push(path.join(home, '.cache'));
  } else if (normalizedCommand === 'yarn') {
    readOnlyPaths.push(path.join(home, '.yarnrc'));
    readOnlyPaths.push(path.join(home, '.yarnrc.yml'));
    primaryCachePaths.push(path.join(home, '.yarn'));
    primaryCachePaths.push(path.join(home, '.config', 'yarn'));
```

On Windows, those suggested write paths are passed into `WindowsSandboxManager`, which rejects every non-existent additional write path before the shell command can run:

```ts
    for (const writePath of additionalWritePaths) {
      const resolved = await tryRealpath(writePath);
      try {
        await fs.promises.access(resolved, fs.constants.F_OK);
      } catch {
        throw new Error(
          `Sandbox request rejected: Additional write path does not exist: ${resolved}. ` +
            'On Windows, granular sandbox access can only be granted to existing paths to avoid broad parent directory permissions.',
        );
      }
```

This breaks the stated proactive-permissions workflow for a normal fresh Windows profile where, for example, `~/.npm` has not been created yet: approving the recommended expansion for `npm install` causes sandbox preparation itself to throw instead of allowing npm to create/use its cache.

**Fix**: Do not include non-existent proactive write paths on Windows unless the Windows sandbox can create/grant them safely. Either filter `primaryCachePaths` through the same existence check on Windows, pre-create tool cache directories before granting ACLs, or teach `WindowsSandboxManager` to grant the nearest safe existing parent without broadening access beyond the confirmed permission.

## Command Results

Required artifact paths note: the supplied external `inputs/allowed-files.txt` and `volley/sharpened-spec-final.md` paths were absent in this checkout; I used the cleanroom copies `FORGE_ALLOWED_FILES.txt`, `FORGE_INPUT_DIFF.patch`, and `GOAL.md`.

### `cat /Users/junekim/Documents/refactor-equivalence/samples/v2/gemini-cli-24460/inputs/allowed-files.txt`

Exit code: 1

Tail:

```text
/private/tmp/refactor-eq-workdir/cleanroom-v2/24460
cat: /Users/junekim/Documents/refactor-equivalence/samples/v2/gemini-cli-24460/inputs/allowed-files.txt: No such file or directory
```

### `cat FORGE_ALLOWED_FILES.txt`

Exit code: 0

Tail:

```text
packages/core/src/policy/policies/sandbox-default.toml
packages/core/src/policy/policy-engine.ts
packages/core/src/policy/sandboxPolicyManager.ts
packages/core/src/sandbox/linux/LinuxSandboxManager.ts
packages/core/src/sandbox/macos/MacOsSandboxManager.ts
packages/core/src/sandbox/macos/baseProfile.ts
packages/core/src/sandbox/utils/proactivePermissions.ts
packages/core/src/sandbox/utils/sandboxDenialUtils.ts
packages/core/src/sandbox/windows/WindowsSandboxManager.ts
packages/core/src/services/sandboxManager.ts
packages/core/src/services/sandboxManagerFactory.ts
packages/core/src/tools/shell.ts
packages/core/src/utils/shell-utils.ts
```

### `npm run build`

Exit code: 0

Tail 50 lines:

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


> @google/gemini-cli-test-utils@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:dev


> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:client && tsc -p tsconfig.build.json


> @google/gemini-cli-a2a-server@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build:client
> node esbuild.client.js


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build:dev
> node esbuild.js

Successfully copied files.
Successfully copied files.
Successfully copied files.
[watch] build started
Successfully copied files.
[watch] build finished
```

### `npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'`

Exit code: 0

Tail 50 lines:

```text
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24460/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24460/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
[Routing] Selected model: gemini-2.0-flash (Source: agent-router/override, Latency: 0ms)
	[Routing] Reasoning: Routing bypassed by forced model directive. Using: gemini-2.0-flash

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Experiments loaded {
  experimentIds: [],
  flags: []
}

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24460/packages/sdk/.geminiignore, continue without it.

(node:66700) MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 model-changed listeners added to [CoreEventEmitter]. MaxListeners is 10. Use emitter.setMaxListeners() to increase limit
(Use `node --trace-warnings ...` to show where the warning was created)
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24460/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24460/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 594ms
   ✓ GeminiCliAgent Integration > resumes a session  525ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  23:23:52
   Duration  2.24s (transform 694ms, setup 0ms, collect 5.82s, tests 828ms, environment 0ms, prepare 264ms)


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/cleanroom-v2/24460/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 14ms
 ✓ src/extension.test.ts (11 tests) 21ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 50ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  23:23:55
   Duration  1.70s (transform 684ms, setup 0ms, collect 2.94s, tests 85ms, environment 0ms, prepare 235ms)
```
