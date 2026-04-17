## Build: PASS
## Tests: PASS

## Finding F1 — `invoke_agent` is no longer allowed by the default agent policy in Plan mode
**Severity**: blocker
**File**: packages/core/src/policy/policies/agents.toml:10
**What**: The added `modes = ["default", "autoEdit", "yolo"]` changes the default `invoke_agent` allow rule from all approval modes to only those three modes. `PolicyEngine` treats missing/empty `modes` as all modes, so in `HEAD~` a Plan-mode `invoke_agent` call matched the priority-50 allow rule. In `HEAD`, the same rule is skipped in Plan mode and the Plan-mode catch-all deny rule wins for any subagent not separately allowed in `plan.toml`. A direct policy-engine check demonstrates the regression: the `HEAD~` rule returns `allow` for `invoke_agent` in Plan mode, while the new rule returns `deny`.
**Fix**: Preserve the previous rule scope by removing the `modes` field, or explicitly include `plan` if the intent is to keep `invoke_agent` allowed in Plan mode.

## Finding F2 — Accepted `AgentTool` refactor claims were not implemented
**Severity**: warning
**File**: packages/core/src/agents/agent-tool.ts:106
**What**: Accepted claim C1 required centralizing input-key selection for `mapParams` and `DelegateInvocation.withUserHints`, but the code still has two separate schema-property probes at `mapParams` and `withUserHints`. Accepted claim C2 required a helper that applies user hints and builds the child invocation for reuse by both lifecycle methods, but `shouldConfirmExecute` and `execute` still duplicate `withUserHints(this.mappedInputs)` followed by `buildChildInvocation(...)`.
**Fix**: Add the shared private input-key helper and the hinted child-invocation helper described in the sharpened spec, then route both existing call sites through them without changing behavior.

## Required Command Evidence

`git diff HEAD~ -- .` exit code: 0

```diff
diff --git a/packages/core/src/policy/policies/agents.toml b/packages/core/src/policy/policies/agents.toml
index 77bb412316..7b942f3639 100644
--- a/packages/core/src/policy/policies/agents.toml
+++ b/packages/core/src/policy/policies/agents.toml
@@ -7,3 +7,4 @@ name = "Allow invoke_agent"
 toolName = "invoke_agent"
 decision = "allow"
 priority = 50
+modes = ["default", "autoEdit", "yolo"]
```

`npm run build` exit code: 0

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

> @google/gemini-cli-a2a-server@0.39.0-nightly.20260408.e77b22e63 build
> node ../../scripts/build_package.js


> @google/gemini-cli-devtools@0.39.0-nightly.20260408.e77b22e63 build
> npm run build:client && tsc -p tsconfig.build.json


> gemini-cli-vscode-ide-companion@0.39.0-nightly.20260408.e77b22e63 build
> npm run build:dev


> @google/gemini-cli-sdk@0.39.0-nightly.20260408.e77b22e63 build
> node ../../scripts/build_package.js


> @google/gemini-cli@0.39.0-nightly.20260408.e77b22e63 build
> node ../../scripts/build_package.js


> @google/gemini-cli-test-utils@0.39.0-nightly.20260408.e77b22e63 build
> node ../../scripts/build_package.js


> gemini-cli-vscode-ide-companion@0.39.0-nightly.20260408.e77b22e63 build:dev
> node esbuild.js


> @google/gemini-cli-devtools@0.39.0-nightly.20260408.e77b22e63 build:client
> node esbuild.client.js

Successfully copied files.
Successfully copied files.
[watch] build started
Successfully copied files.
Successfully copied files.
[watch] build finished
```

`npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'` exit code: 0

Tail 50 lines:

```text
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
Ignore file not found: /private/tmp/refactor-eq-workdir/v2-wt-24489/packages/sdk/.geminiignore, continue without it.

(node:70586) MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 model-changed listeners added to [CoreEventEmitter]. MaxListeners is 10. Use emitter.setMaxListeners() to increase limit
(Use `node --trace-warnings ...` to show where the warning was created)
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/v2-wt-24489/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/v2-wt-24489/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 678ms
   ✓ GeminiCliAgent Integration > resumes a session  625ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  11:25:01
   Duration  2.24s (transform 658ms, setup 0ms, collect 5.60s, tests 898ms, environment 0ms, prepare 175ms)


> gemini-cli-vscode-ide-companion@0.39.0-nightly.20260408.e77b22e63 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/v2-wt-24489/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 12ms
 ✓ src/extension.test.ts (11 tests) 18ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 50ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  11:25:03
   Duration  1.64s (transform 701ms, setup 0ms, collect 2.91s, tests 80ms, environment 0ms, prepare 130ms)
```

Note: `/tmp/refactor-eq-workdir/cleanroom-v2/24489` had no Git metadata, so the required Git/build/test commands were run in `/tmp/refactor-eq-workdir/v2-wt-24489`, which has the same checked-out code and `node_modules`.
