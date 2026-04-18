## Build: PASS
## Tests: PASS

## Finding F1 — noninteractive agent-session setting is ignored
**Severity**: blocker
**File**: packages/cli/src/nonInteractiveCli.ts:58
**What**: `runNonInteractive` no longer checks `config.getAgentSessionNoninteractiveEnabled()` before entering the legacy inline noninteractive implementation. The user-facing/config API still accepts and exposes `adk.agentSessionNoninteractiveEnabled`, but enabling it has no effect because this function always proceeds directly into the legacy path. Current code:

```text
    58	export async function runNonInteractive({
    59	  config,
    60	  settings,
    61	  input,
    62	  prompt_id,
    63	  resumedSessionData,
    64	}: RunNonInteractiveParams): Promise<void> {
    65	  return promptIdContext.run(prompt_id, async () => {
    66	    const consolePatcher = new ConsolePatcher({
```

The flag remains wired in `Config`, so this is not a removed feature:

```text
  1309	    this.agentSessionNoninteractiveEnabled =
  1310	      params.adk?.agentSessionNoninteractiveEnabled ?? false;
```

```text
  3361	  getAgentSessionNoninteractiveEnabled(): boolean {
  3362	    return this.agentSessionNoninteractiveEnabled;
  3363	  }
```

The setting is still exposed to users:

```text
  1946	          agentSessionNoninteractiveEnabled: {
  1947	            type: 'boolean',
  1948	            label: 'Agent Session Non-interactive Enabled',
  1949	            category: 'Experimental',
  1950	            requiresRestart: true,
  1951	            default: false,
  1952	            description: 'Enable non-interactive agent sessions.',
  1953	            showInDialog: false,
  1954	          },
```

The agent-session implementation file is also absent in the current tree:

```text
ls: packages/cli/src/nonInteractiveCliAgentSession.ts: No such file or directory
```

**Fix**: Restore the noninteractive agent-session dispatch when `config.getAgentSessionNoninteractiveEnabled()` is true, including the implementation module, or remove the setting and all documented/config API that claims this mode exists. Preserving C_test behavior requires the flag to select the agent-session implementation.

## Finding F2 — Always-allow policy updates lost approval-mode scoping
**Severity**: blocker
**File**: packages/core/src/scheduler/policy.ts:127
**What**: The policy updater now publishes "always allow" updates without a `modes` field. Current policy semantics say a rule with undefined/empty `modes` applies to all approval modes, so an approval that should be scoped to the current mode and more permissive modes becomes globally applicable. Current `updatePolicy` only computes `persistScope` and passes no mode scope to either policy update path:

```text
   127	  // Determine persist scope if we are persisting.
   128	  let persistScope: 'workspace' | 'user' | undefined;
   129	  if (outcome === ToolConfirmationOutcome.ProceedAlwaysAndSave) {
   130	    // If folder is trusted and workspace policies are enabled, we prefer workspace scope.
```

```text
   212	    await messageBus.publish({
   213	      type: MessageBusType.UPDATE_POLICY,
   214	      toolName: tool.name,
   215	      persist: outcome === ToolConfirmationOutcome.ProceedAlwaysAndSave,
   216	      persistScope,
   217	      ...options,
   218	    });
```

```text
   254	  await messageBus.publish({
   255	    type: MessageBusType.UPDATE_POLICY,
   256	    toolName,
   257	    mcpName: confirmationDetails.serverName,
   258	    persist,
   259	    persistScope,
   260	  });
```

The message shape also no longer allows callers to carry that scope:

```text
   144	export interface UpdatePolicy {
   145	  type: MessageBusType.UPDATE_POLICY;
   146	  toolName: string;
   147	  persist?: boolean;
   148	  persistScope?: 'workspace' | 'user';
   149	  argsPattern?: string;
   150	  commandPrefix?: string | string[];
   151	  mcpName?: string;
   152	  allowRedirection?: boolean;
   153	}
```

And the current policy engine treats missing `modes` as all modes:

```text
   150	  /**
   151	   * Approval modes this rule applies to.
   152	   * If undefined or empty, it applies to all modes.
   153	   */
   154	  modes?: ApprovalMode[];
```

```text
    92	  // Check if rule applies to current approval mode
    93	  if (rule.modes && rule.modes.length > 0) {
    94	    if (!rule.modes.includes(currentApprovalMode)) {
    95	      return false;
    96	    }
    97	  }
```

The update consumer likewise adds dynamic allow rules without `modes`:

```text
   582	            policyEngine.addRule({
   583	              toolName,
   584	              decision: PolicyDecision.ALLOW,
   585	              priority,
   586	              argsPattern: new RegExp(pattern),
   587	              mcpName: message.mcpName,
   588	              source: 'Dynamic (Confirmed)',
   589	              allowRedirection: message.allowRedirection,
   590	            });
```

**Fix**: Restore the `modes` field on `UpdatePolicy`, compute the scoped mode list from the current approval mode for `ProceedAlways*` outcomes, and persist/publish that field for standard and MCP policy updates.

## Finding F3 — JSON error formatting bypasses the canonical error type helper
**Severity**: blocker
**File**: packages/core/src/output/json-formatter.ts:44
**What**: `JsonFormatter.formatError()` now uses `error.constructor.name` directly. That changes observable JSON output for errors whose public `error.name` differs from the constructor name, including bundled/renamed classes. The repo still has the canonical `getErrorType()` helper that preserves `error.name` and strips bundler prefixes, but this formatter no longer uses it. Current formatter code:

```text
    39	  formatError(
    40	    error: Error,
    41	    code?: string | number,
    42	    sessionId?: string,
    43	  ): string {
    44	    const jsonError: JsonError = {
    45	      type: error.constructor.name,
    46	      message: stripAnsi(error.message),
    47	      ...(code && { code }),
    48	    };
```

The canonical helper still implements the intended public error type behavior:

```text
    57	export function getErrorType(error: unknown): string {
    58	  if (!(error instanceof Error)) return 'unknown';
    59	
    60	  // Use the constructor name if the standard error name is missing or generic.
    61	  const name =
    62	    error.name && error.name !== 'Error'
    63	      ? error.name
    64	      : (error.constructor?.name ?? 'Error');
    65	
    66	  // Strip leading underscore from error names. Bundlers like esbuild sometimes
    67	  // rename classes to avoid scope collisions.
    68	  return name.replace(/^_+/, '');
    69	}
```

The CLI JSON error path still uses the helper, so this formatter is now inconsistent with the rest of the error pipeline:

```text
    84	      const jsonError = {
    85	        message: errorMessage,
    86	        type: getErrorType(error),
```

**Fix**: Import and use `getErrorType(error)` in `JsonFormatter.formatError()` so JSON output continues to report the stable public error type instead of constructor implementation names.

## Command Records

Allowed edit set command:

```text
cat /Users/junekim/Documents/refactor-equivalence/samples/v2/gemini-cli-24476/inputs/allowed-files.txt
exit code: 1
cat: /Users/junekim/Documents/refactor-equivalence/samples/v2/gemini-cli-24476/inputs/allowed-files.txt: No such file or directory
```

Local cleanroom allowed edit set used for review:

```text
.github/workflows/ci.yml
packages/cli/src/nonInteractiveCli.ts
packages/cli/src/nonInteractiveCliAgentSession.ts
packages/cli/src/ui/components/AskUserDialog.tsx
packages/cli/src/ui/components/HistoryItemDisplay.tsx
packages/cli/src/ui/components/LoadingIndicator.tsx
packages/cli/src/ui/components/ModelDialog.tsx
packages/cli/src/ui/components/ModelQuotaDisplay.tsx
packages/cli/src/ui/components/ProgressBar.tsx
packages/cli/src/ui/components/StatsDisplay.tsx
packages/cli/src/ui/hooks/useGeminiStream.ts
packages/cli/src/ui/hooks/useLoadingIndicator.ts
packages/cli/src/utils/errors.ts
packages/core/src/agent/event-translator.ts
packages/core/src/agent/legacy-agent-session.ts
packages/core/src/agent/mock.ts
packages/core/src/agent/types.ts
packages/core/src/confirmation-bus/types.ts
packages/core/src/output/json-formatter.ts
packages/core/src/policy/config.ts
packages/core/src/policy/types.ts
packages/core/src/scheduler/policy.ts
packages/core/src/tools/definitions/model-family-sets/default-legacy.ts
packages/core/src/tools/definitions/model-family-sets/gemini-3.ts
packages/core/src/utils/bfsFileSearch.ts
packages/core/src/utils/checkpointUtils.ts
packages/core/src/utils/retry.ts
```

Out-of-scope edit check against `FORGE_INPUT_DIFF.patch` and `FORGE_ALLOWED_FILES.txt`: 27 changed files, 0 outside allowed set, 0 test files.

Build command:

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

> @google/gemini-cli-sdk@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js

> @google/gemini-cli-a2a-server@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js

> @google/gemini-cli@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js

> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:dev

> @google/gemini-cli-test-utils@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js

> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:client && tsc -p tsconfig.build.json

Successfully copied files.

> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build:dev
> node esbuild.js

> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build:client
> node esbuild.client.js

Successfully copied files.
Successfully copied files.
[watch] build started
Successfully copied files.
[watch] build finished
```

Test command:

```text
npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'
exit code: 0
tail -50:

stdout | src/tool.integration.test.ts > GeminiCliAgent Tool Integration > handles sendErrorsToModel: true correctly
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/sdk/.geminiignore, continue without it.

stderr | src/tool.integration.test.ts > GeminiCliAgent Tool Integration > handles sendErrorsToModel: true correctly
Could not find promptId in context for classifier-router. This is unexpected. Using a fallback ID: classifier-router-fallback-1776499547303-0da9c84ca8437

stderr | src/tool.integration.test.ts > GeminiCliAgent Tool Integration > handles sendErrorsToModel: true correctly
Error generating content via API. Full report available at: /var/folders/26/zl1yc5xj5m36n5_dcqhtp1t00000gn/T/gemini-client-error-generateJson-api-2026-04-18T08-05-47-304Z.json Error: Unexpected response type, next response was for generateContentStream but expected generateContent
    at FakeContentGenerator.getNextResponse (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/core/src/core/fakeContentGenerator.ts:73:13)
    at FakeContentGenerator.generateContent (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/core/src/core/fakeContentGenerator.ts:89:12)
    at /private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/core/src/core/loggingContentGenerator.ts:378:47
    at /private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/core/src/telemetry/trace.ts:162:28
    at NoopContextManager.with (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/node_modules/@opentelemetry/api/src/context/NoopContextManager.ts:31:15)
    at ContextAPI.with (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/node_modules/@opentelemetry/api/src/api/context.ts:77:42)
    at NoopTracer.startActiveSpan (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/node_modules/@opentelemetry/api/src/trace/NoopTracer.ts:98:27)
    at ProxyTracer.startActiveSpan (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/node_modules/@opentelemetry/api/src/trace/ProxyTracer.ts:51:20)
    at runInDevTraceSpan (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/core/src/telemetry/trace.ts:105:17)
    at LoggingContentGenerator.generateContent (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/core/src/core/loggingContentGenerator.ts:349:29)

stderr | src/tool.integration.test.ts > GeminiCliAgent Tool Integration > handles sendErrorsToModel: true correctly
[Routing] NumericalClassifierStrategy failed: Error: Failed to generate content: Unexpected response type, next response was for generateContentStream but expected generateContent
    at BaseLlmClient._generateWithRetry (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/core/src/core/baseLlmClient.ts:391:13)
    at BaseLlmClient.generateJson (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/core/src/core/baseLlmClient.ts:155:20)
    at NumericalClassifierStrategy.route (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/core/src/routing/strategies/numericalClassifierStrategy.ts:135:28)
    at CompositeStrategy.route (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/core/src/routing/strategies/compositeStrategy.ts:62:26)
    at ModelRouterService.route (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/core/src/routing/modelRouterService.ts:89:18)
    at GeminiClient.processTurn (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/core/src/core/client.ts:721:24)
    at GeminiClient.sendMessageStream (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/core/src/core/client.ts:939:14)
    at GeminiCliSession.sendStream (/private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/sdk/src/session.ts:210:24)
    at /private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/sdk/src/tool.integration.test.ts:137:22
    at file:///private/tmp/refactor-eq-workdir/cleanroom-v2/24476/node_modules/@vitest/runner/dist/chunk-hooks.js:752:20

stdout | src/tool.integration.test.ts > GeminiCliAgent Tool Integration > handles sendErrorsToModel: true correctly
[Routing] Selected model: gemini-3.1-pro-preview (Source: agent-router/default, Latency: 1ms)
	[Routing] Reasoning: Routing to default model: gemini-3.1-pro-preview

 ✓ src/tool.integration.test.ts (3 tests) 168ms
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
Experiments loaded {
  experimentIds: [],
  flags: []
}

 ✓ src/agent.integration.test.ts (5 tests) 591ms
   ✓ GeminiCliAgent Integration > resumes a session  528ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  01:05:45
   Duration  2.25s (transform 735ms, setup 0ms, collect 5.80s, tests 824ms, environment 0ms, prepare 269ms)

> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts

 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 12ms
 ✓ src/extension.test.ts (11 tests) 21ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 54ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  01:05:47
   Duration  1.66s (transform 689ms, setup 0ms, collect 2.86s, tests 86ms, environment 0ms, prepare 115ms)
```
