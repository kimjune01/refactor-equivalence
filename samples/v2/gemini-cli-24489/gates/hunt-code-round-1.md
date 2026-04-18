## Build: PASS
## Tests: PASS

## Finding F1 — Plan policy still matches invoke_agent args instead of virtual subagent names
**Severity**: warning
**File**: packages/core/src/policy/policies/plan.toml:108
**What**: Accepted claim C1 was not applied. The Plan-mode subagent allow rule still targets `invoke_agent` and parses `agent_name` with `argsPattern`, instead of relying on the PolicyEngine virtual alias path with `toolName = ["codebase_investigator", "cli_help"]`.

Current evidence:
```toml
108	# Allow specific subagents in Plan mode.
109	# We use argsPattern to match the agent_name argument for invoke_agent.
110	[[rule]]
111	name = "Allow specific subagents in Plan mode"
112	toolName = "invoke_agent"
113	argsPattern = "\"agent_name\":\\s*\"(codebase_investigator|cli_help)\""
114	decision = "allow"
115	priority = 50
116	modes = ["plan"]
```
**Fix**: Change the rule to `toolName = ["codebase_investigator", "cli_help"]`, remove the `argsPattern`, and update the comment to state that the rule depends on `invoke_agent` virtual alias matching.

## Finding F2 — Remote agent dynamic policy still parses invoke_agent arguments
**Severity**: warning
**File**: packages/core/src/agents/registry.ts:394
**What**: Accepted claim C2 was not applied. `AgentRegistry.addAgentPolicy` still creates dynamic remote-agent policy rules against `AgentTool.Name` with an `argsPattern` for `"agent_name"`, leaving a registry-local JSON-argument match instead of using the agent name as the virtual policy key.

Current evidence:
```ts
394	    // Only add override for remote agents. Local agents are handled by blanket allow.
395	    if (definition.kind === 'remote') {
396	      policyEngine.addRule({
397	        toolName: AgentTool.Name,
398	        argsPattern: new RegExp(`"agent_name":\\s*"${definition.name}"`),
399	        decision: PolicyDecision.ASK_USER,
400	        priority: PRIORITY_SUBAGENT_TOOL + 0.1, // Higher priority to override blanket allow
401	        source: DYNAMIC_RULE_SOURCE,
402	      });
403	    }
```
**Fix**: Change the dynamic rule to `toolName: definition.name`, remove the `argsPattern`, and drop the `AgentTool` import if it is no longer used.

## Command Evidence

`npm run build`

Exit code: 0

Tail 50 lines:
```text
> @google/gemini-cli-core@0.39.0-nightly.20260408.e77b22e63 build
> node ../../scripts/build_package.js

Running chrome devtools MCP bundling...

> @google/gemini-cli-core@0.39.0-nightly.20260408.e77b22e63 bundle:browser-mcp
> node scripts/bundle-browser-mcp.mjs

Successfully copied files.
Copied documentation to dist/docs
Building other workspaces in parallel...

> gemini-cli-vscode-ide-companion@0.39.0-nightly.20260408.e77b22e63 build
> npm run build:dev


> @google/gemini-cli-test-utils@0.39.0-nightly.20260408.e77b22e63 build
> node ../../scripts/build_package.js


> @google/gemini-cli-sdk@0.39.0-nightly.20260408.e77b22e63 build
> node ../../scripts/build_package.js


> @google/gemini-cli@0.39.0-nightly.20260408.e77b22e63 build
> node ../../scripts/build_package.js


> @google/gemini-cli-devtools@0.39.0-nightly.20260408.e77b22e63 build
> npm run build:client && tsc -p tsconfig.build.json


> @google/gemini-cli-a2a-server@0.39.0-nightly.20260408.e77b22e63 build
> node ../../scripts/build_package.js


> @google/gemini-cli-devtools@0.39.0-nightly.20260408.e77b22e63 build:client
> node esbuild.client.js


> gemini-cli-vscode-ide-companion@0.39.0-nightly.20260408.e77b22e63 build:dev
> node esbuild.js

Successfully copied files.
Successfully copied files.
Successfully copied files.
[watch] build started
Successfully copied files.
[watch] build finished
```

`npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'`

Exit code: 0

Tail 50 lines:
```text
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24489/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24489/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
[Routing] Selected model: gemini-2.0-flash (Source: agent-router/override, Latency: 0ms)
	[Routing] Reasoning: Routing bypassed by forced model directive. Using: gemini-2.0-flash

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Experiments loaded {
  experimentIds: [],
  flags: []
}

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24489/packages/sdk/.geminiignore, continue without it.

(node:68807) MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 model-changed listeners added to [CoreEventEmitter]. MaxListeners is 10. Use emitter.setMaxListeners() to increase limit
(Use `node --trace-warnings ...` to show where the warning was created)
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24489/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24489/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 683ms
   ✓ GeminiCliAgent Integration > resumes a session  530ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  17:26:23
   Duration  2.25s (transform 673ms, setup 0ms, collect 5.54s, tests 793ms, environment 0ms, prepare 182ms)


> gemini-cli-vscode-ide-companion@0.39.0-nightly.20260408.e77b22e63 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/cleanroom-v2/24489/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 12ms
 ✓ src/extension.test.ts (11 tests) 18ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 51ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  17:26:25
   Duration  1.56s (transform 689ms, setup 0ms, collect 2.74s, tests 81ms, environment 0ms, prepare 166ms)
```
