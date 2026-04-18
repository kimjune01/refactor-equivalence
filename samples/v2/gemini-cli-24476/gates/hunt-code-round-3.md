## Build: PASS
## Tests: PASS

## Finding F1 — noninteractive agent-session flag is ignored
**Severity**: blocker
**File**: packages/cli/src/nonInteractiveCli.ts:58
**What**: `runNonInteractive` now always enters the legacy inline implementation and never checks `config.getAgentSessionNoninteractiveEnabled()`. The setting still exists and is still read into `Config`, so enabling `adk.agentSessionNoninteractiveEnabled` has no observable effect in noninteractive CLI runs. Current code:

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

The flag is still wired in `Config`:

```text
  1309	    this.agentSessionNoninteractiveEnabled =
  1310	      params.adk?.agentSessionNoninteractiveEnabled ?? false;
```

```text
  3361	  getAgentSessionNoninteractiveEnabled(): boolean {
  3362	    return this.agentSessionNoninteractiveEnabled;
  3363	  }
```

The agent-session implementation file is also absent:

```text
MISSING packages/cli/src/nonInteractiveCliAgentSession.ts
```

**Fix**: Restore the noninteractive agent-session dispatch path when `config.getAgentSessionNoninteractiveEnabled()` is true, or remove the setting and all user-facing/config API that claims this mode exists. To preserve behavior, the flag should continue to select the agent-session implementation.

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

> @google/gemini-cli@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:client && tsc -p tsconfig.build.json


> @google/gemini-cli-a2a-server@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:dev


> @google/gemini-cli-test-utils@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli-sdk@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build:client
> node esbuild.client.js


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build:dev
> node esbuild.js

Successfully copied files.
Successfully copied files.
[watch] build started
Successfully copied files.
Successfully copied files.
[watch] build finished
```

Test command:

```text
npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'
exit code: 0
tail -50:
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
[Routing] Selected model: gemini-2.0-flash (Source: agent-router/override, Latency: 0ms)
	[Routing] Reasoning: Routing bypassed by forced model directive. Using: gemini-2.0-flash

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Experiments loaded {
  experimentIds: [],
  flags: []
}

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/sdk/.geminiignore, continue without it.

(node:37781) MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 model-changed listeners added to [CoreEventEmitter]. MaxListeners is 10. Use emitter.setMaxListeners() to increase limit
(Use `node --trace-warnings ...` to show where the warning was created)
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 592ms
   ✓ GeminiCliAgent Integration > resumes a session  528ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  00:30:59
   Duration  2.24s (transform 728ms, setup 0ms, collect 5.80s, tests 822ms, environment 0ms, prepare 244ms)


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/cleanroom-v2/24476/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 13ms
 ✓ src/extension.test.ts (11 tests) 21ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 51ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  00:31:02
   Duration  1.64s (transform 696ms, setup 0ms, collect 2.88s, tests 85ms, environment 0ms, prepare 177ms)
```
