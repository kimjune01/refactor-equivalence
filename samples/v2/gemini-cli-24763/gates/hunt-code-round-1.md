## Build: PASS
## Tests: PASS

Command evidence:

```text
cat /Users/junekim/Documents/refactor-equivalence/samples/v2/gemini-cli-24763/inputs/allowed-files.txt
exit code: 1
tail:
cat: /Users/junekim/Documents/refactor-equivalence/samples/v2/gemini-cli-24763/inputs/allowed-files.txt: No such file or directory

fallback used: /tmp/refactor-eq-workdir/cleanroom-v2/24763/FORGE_ALLOWED_FILES.txt
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

> @google/gemini-cli-a2a-server@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:client && tsc -p tsconfig.build.json


> @google/gemini-cli-sdk@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli-test-utils@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:dev


> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build:client
> node esbuild.client.js


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build:dev
> node esbuild.js

[watch] build started
[watch] build finished
Successfully copied files.
Successfully copied files.
Successfully copied files.
Successfully copied files.
```

```text
npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'
exit code: 0
tail -50:
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24763/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24763/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
[Routing] Selected model: gemini-2.0-flash (Source: agent-router/override, Latency: 0ms)
	[Routing] Reasoning: Routing bypassed by forced model directive. Using: gemini-2.0-flash

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Experiments loaded {
  experimentIds: [],
  flags: []
}

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24763/packages/sdk/.geminiignore, continue without it.

(node:85376) MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 model-changed listeners added to [CoreEventEmitter]. MaxListeners is 10. Use emitter.setMaxListeners() to increase limit
(Use `node --trace-warnings ...` to show where the warning was created)
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24763/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24763/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 593ms
   ✓ GeminiCliAgent Integration > resumes a session  531ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  03:07:11
   Duration  2.17s (transform 673ms, setup 0ms, collect 5.55s, tests 822ms, environment 0ms, prepare 191ms)


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/cleanroom-v2/24763/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 12ms
 ✓ src/extension.test.ts (11 tests) 18ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 49ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  03:07:14
   Duration  1.57s (transform 660ms, setup 0ms, collect 2.75s, tests 80ms, environment 0ms, prepare 150ms)
```

## Finding F1 — CLI drops the environment redaction allowlist
**Severity**: blocker
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/24763/packages/cli/src/config/config.ts:939
**What**: The CLI settings schema still exposes `security.environmentVariableRedaction.allowed`, and core `Config` still accepts and returns `allowedEnvironmentVariables`, but `loadCliConfig` no longer forwards the setting into the core config constructor. Users who configured an allowlist now get an empty allowlist, so variables they explicitly allowed can be redacted from shell/sandbox environments.

Current lines showing the missing forwarding:

```ts
   939	    blockedEnvironmentVariables:
   940	      settings.security?.environmentVariableRedaction?.blocked,
   941	    enableEnvironmentVariableRedaction:
   942	      settings.security?.environmentVariableRedaction?.enabled,
```

Current lines showing the setting and core API still exist:

```ts
  1810	          allowed: {
  1811	            type: 'array',
  1812	            label: 'Allowed Environment Variables',
```

```ts
   637	  allowedEnvironmentVariables?: string[];
   638	  blockedEnvironmentVariables?: string[];
```

```ts
  1043	    this.allowedEnvironmentVariables = params.allowedEnvironmentVariables ?? [];
  1044	    this.blockedEnvironmentVariables = params.blockedEnvironmentVariables ?? [];
```

**Fix**: Pass `allowedEnvironmentVariables: settings.security?.environmentVariableRedaction?.allowed` alongside the existing blocked/enabled fields in `loadCliConfig`, and add/restore a CLI config test that asserts the allowlist reaches `config.sanitizationConfig`.

## Finding F2 — Sandbox cleanup is still only event-driven after prepareCommand
**Severity**: warning
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/24763/packages/core/src/services/sandboxedFileSystemService.ts:52
**What**: The PR claims process execution paths were upgraded to `try...finally` so cleanup runs across synchronous throws and early abort paths. Current sandboxed filesystem code still prepares a command, then creates a `Promise` where `prepared.cleanup` is called only from `close`/`error` event handlers. If `spawn(...)` throws synchronously after `prepareCommand` has allocated sandbox resources, cleanup is skipped. The same pattern remains in `spawnAsync`.

Current lines from `SandboxedFileSystemService.readTextFile`:

```ts
    52	    const prepared = await this.sandboxManager.prepareCommand({
    60	    });
    62	    return new Promise((resolve, reject) => {
    65	      const child = spawn(prepared.program, prepared.args, {
    81	      child.on('close', (code) => {
    82	        prepared.cleanup?.();
```

Current lines from `spawnAsync`:

```ts
   841	  const prepared = await sandboxManager.prepareCommand({
   846	  });
   850	  return new Promise((resolve, reject) => {
   851	    const child = spawn(finalCommand, finalArgs, {
   866	    child.on('close', (code) => {
   867	      prepared.cleanup?.();
   875	    child.on('error', (err) => {
   876	      prepared.cleanup?.();
```

**Fix**: Wrap the post-`prepareCommand` execution setup in `try`/`finally` or an equivalent exactly-once cleanup guard that also runs when `spawn`/PTY setup throws before event listeners can fire. Apply the same guard consistently to the affected sandbox execution paths.
