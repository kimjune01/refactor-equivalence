## Build: PASS
## Tests: PASS

Command evidence:

```text
cat /Users/junekim/Documents/refactor-equivalence/samples/v2/gemini-cli-24763/inputs/allowed-files.txt
exit code: 1
tail:
cat: /Users/junekim/Documents/refactor-equivalence/samples/v2/gemini-cli-24763/inputs/allowed-files.txt: No such file or directory
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

> @google/gemini-cli@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js

> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:client && tsc -p tsconfig.build.json

> @google/gemini-cli-test-utils@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js

> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:dev

> @google/gemini-cli-sdk@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js

> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build:dev
> node esbuild.js

Successfully copied files.

> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build:client
> node esbuild.client.js

Successfully copied files.
Successfully copied files.
[watch] build started
Successfully copied files.
[watch] build finished
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

(node:53010) MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 model-changed listeners added to [CoreEventEmitter]. MaxListeners is 10. Use emitter.setMaxListeners() to increase limit
(Use `node --trace-warnings ...` to show where the warning was created)
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24763/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24763/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 604ms
   ✓ GeminiCliAgent Integration > resumes a session  537ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  05:13:22
   Duration  2.22s (transform 672ms, setup 0ms, collect 5.62s, tests 842ms, environment 0ms, prepare 268ms)

> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts

 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/cleanroom-v2/24763/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 14ms
 ✓ src/extension.test.ts (11 tests) 18ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 50ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  05:13:24
   Duration  1.60s (transform 737ms, setup 0ms, collect 2.80s, tests 81ms, environment 0ms, prepare 171ms)
```

## Finding F1 — CLI drops the environment redaction allowlist
**Severity**: blocker
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/24763/packages/cli/src/config/config.ts:939
**What**: `loadCliConfig` still forwards only `security.environmentVariableRedaction.blocked` and `.enabled` into core `Config`, but omits `.allowed`. The user-facing settings schema still exposes `security.environmentVariableRedaction.allowed`, and core `Config` still accepts and returns `allowedEnvironmentVariables`, so configured allowlisted variables are silently discarded from `config.sanitizationConfig`.

Current lines showing the missing forwarding:

```ts
   939	    blockedEnvironmentVariables:
   940	      settings.security?.environmentVariableRedaction?.blocked,
   941	    enableEnvironmentVariableRedaction:
   942	      settings.security?.environmentVariableRedaction?.enabled,
```

Current lines showing the setting still exists:

```ts
  1801	      environmentVariableRedaction: {
  1802	        type: 'object',
  1803	        label: 'Environment Variable Redaction',
  1804	        category: 'Security',
  1805	        requiresRestart: false,
  1806	        default: {},
  1807	        description: 'Settings for environment variable redaction.',
  1808	        showInDialog: false,
  1809	        properties: {
  1810	          allowed: {
  1811	            type: 'array',
  1812	            label: 'Allowed Environment Variables',
```

Current lines showing core still accepts and returns the allowlist:

```ts
   637	  allowedEnvironmentVariables?: string[];
   638	  blockedEnvironmentVariables?: string[];
   639	  enableEnvironmentVariableRedaction?: boolean;
```

```ts
  1043	    this.allowedEnvironmentVariables = params.allowedEnvironmentVariables ?? [];
  1044	    this.blockedEnvironmentVariables = params.blockedEnvironmentVariables ?? [];
```

```ts
  2296	  get sanitizationConfig(): EnvironmentSanitizationConfig {
  2297	    return {
  2298	      allowedEnvironmentVariables: this.allowedEnvironmentVariables,
  2299	      blockedEnvironmentVariables: this.blockedEnvironmentVariables,
```

**Fix**: Pass `allowedEnvironmentVariables: settings.security?.environmentVariableRedaction?.allowed` alongside the existing blocked/enabled fields in `loadCliConfig`, and add or restore a CLI config test asserting the allowlist reaches `config.sanitizationConfig`.

## Finding F2 — Accepted sandbox cleanup claims are still event-handler-only
**Severity**: warning
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/24763/packages/core/src/services/sandboxedFileSystemService.ts:52
**What**: The accepted cleanup goal requires robust `try...finally` cleanup after sandbox preparation for read/write file paths, grep probing, discovered tool invocation/discovery, `spawnAsync`, `execStreaming`, and shell execution paths. Current code still prepares sandbox commands and calls cleanup only from child-process event handlers in several of those paths. If `spawn(...)`, stdin setup, stream listener setup, `readline.createInterface(...)`, `cpSpawn(...)`, or PTY spawn throws synchronously after `prepareCommand`, the sandbox cleanup callback is skipped. That leaves the accepted cleanup claim only partially applied.

Current lines from `SandboxedFileSystemService.readTextFile`:

```ts
    52	    const prepared = await this.sandboxManager.prepareCommand({
    60	    });
    62	    return new Promise((resolve, reject) => {
    65	      const child = spawn(prepared.program, prepared.args, {
    81	      child.on('close', (code) => {
    82	        prepared.cleanup?.();
```

Current lines from `GrepTool.isCommandAvailable`:

```ts
   333	          const prepared = await sandboxManager.prepareCommand({
   342	          cleanup = prepared.cleanup;
   351	      return await new Promise((resolve) => {
   352	        const child = spawn(finalCommand, finalArgs, {
   357	        child.on('close', (code) => {
   358	          cleanup?.();
```

Current lines from `DiscoveredToolInvocation.execute`:

```ts
    72	      const prepared = await sandboxManager.prepareCommand({
    81	      cleanupFunc = prepared.cleanup;
    84	    const child = spawn(finalCommand, finalArgs, {
    87	    child.stdin.write(JSON.stringify(this.params));
   105	      const onError = (err: Error) => {
   106	        cleanupFunc?.();
   110	      const onClose = (
   114	        cleanupFunc?.();
```

Current lines from `ToolRegistry.discoverAndRegisterToolsFromCommand`:

```ts
   385	        const prepared = await sandboxManager.prepareCommand({
   394	        cleanupFunc = prepared.cleanup;
   397	      const proc = spawn(finalCommand, finalArgs, {
   433	      await new Promise<void>((resolve, reject) => {
   434	        proc.on('error', (err) => {
   435	          cleanupFunc?.();
   438	        proc.on('close', (code) => {
   439	          cleanupFunc?.();
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

Current lines from `execStreaming`:

```ts
   900	  const prepared = await sandboxManager.prepareCommand({
   905	  });
   909	  const child = spawn(finalCommand, finalArgs, {
   916	  const rl = readline.createInterface({
   949	  try {
   955	  } finally {
   971	    await new Promise<void>((resolve, reject) => {
   979	      function checkExit(code: number | null) {
   980	        prepared.cleanup?.();
```

Current lines from `ShellExecutionService.childProcessFallback`:

```ts
   516	      const {
   521	        cleanup: cmdCleanup,
   522	      } = await this.prepareExecution(
   529	      const child = cpSpawn(finalExecutable, finalArgs, {
   687	      const handleExit = (
   691	        cleanup();
   692	        cmdCleanup?.();
```

Current lines from `ShellExecutionService.executeWithPty`:

```ts
   848	      const {
   853	        cleanup: cmdCleanup,
   854	      } = await this.prepareExecution(
   861	      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
   862	      const ptyProcess = ptyInfo.module.spawn(finalExecutable, finalArgs, {
  1148	          const finalize = () => {
  1149	            render(true);
  1150	            cmdCleanup?.();
```

**Fix**: Store the prepared cleanup in a scope reachable by an outer `finally`, guard it so it runs once, and ensure cleanup is called on every exit path after successful preparation, including synchronous exceptions before event handlers are installed.
