## Build: PASS
## Tests: PASS

## Finding F1 — Release dry-runs now mutate npm dist-tags
**Severity**: blocker
**File**: .github/actions/publish-release/action.yml:174
**What**: The CORE and a2a publish steps now run `npm dist-tag rm ... false` unconditionally, immediately after `npm publish --dry-run="${INPUTS_DRY_RUN}"`. In a dry run this still attempts a real registry mutation/removal and can fail or alter package tags, which is an observable release-action behavior change unrelated to the eval refactor.

Current evidence:

```yaml
        npm publish \
          --dry-run="${INPUTS_DRY_RUN}" \
          --workspace="${INPUTS_CORE_PACKAGE_NAME}" \
          --no-tag
        npm dist-tag rm ${INPUTS_CORE_PACKAGE_NAME} false
```

```yaml
        npm publish \
          --dry-run="${INPUTS_DRY_RUN}" \
          --workspace="${INPUTS_A2A_PACKAGE_NAME}" \
          --no-tag
        npm dist-tag rm ${INPUTS_A2A_PACKAGE_NAME} false
```

**Fix**: Restore the dry-run guard around both `npm dist-tag rm` commands so they only execute when `INPUTS_DRY_RUN == "false"`.

## Finding F2 — Latest npm releases skip bundled CLI preparation
**Severity**: blocker
**File**: .github/actions/publish-release/action.yml:195
**What**: The bundled CLI preparation step is now skipped for `inputs.npm-tag == 'latest'`, even though the following CLI publish still runs. That means a stable/latest npm release can publish without running `scripts/prepare-npm-release.js`, changing the release artifact pipeline outside the eval-infra goal.

Current evidence:

```yaml
    - name: '📦 Prepare bundled CLI for npm release'
      if: "inputs.npm-registry-url != 'https://npm.pkg.github.com/' && inputs.npm-tag != 'latest'"
      working-directory: '${{ inputs.working-directory }}'
      shell: 'bash'
      run: |
        node ${{ github.workspace }}/scripts/prepare-npm-release.js
```

**Fix**: Remove the `inputs.npm-tag != 'latest'` condition so npm releases to the public registry prepare the bundled CLI regardless of tag.

## Finding F3 — Windows non-CLI CI can pass after failed workspace tests
**Severity**: blocker
**File**: .github/workflows/ci.yml:431
**What**: In the PowerShell CI shard, the non-CLI branch runs workspace tests and then `npm run test:scripts` without checking `$LASTEXITCODE` after the first command. If the workspace test command fails but `test:scripts` passes, the step can finish with the later command's success status and mask the failed tests.

Current evidence:

```yaml
          if ("${{ matrix.shard }}" -eq "cli") {
            npm run test:ci --workspace @google/gemini-cli -- --coverage.enabled=false
          } else {
            # Explicitly list non-cli packages to ensure they are sharded correctly
            npm run test:ci --workspace @google/gemini-cli-core --workspace @google/gemini-cli-a2a-server --workspace gemini-cli-vscode-ide-companion --workspace @google/gemini-cli-test-utils --if-present -- --coverage.enabled=false
            npm run test:scripts
          }
```

**Fix**: Restore explicit `$LASTEXITCODE` checks after each native command, or set PowerShell native-command error handling so a failing `npm` command stops the step.

## Finding F4 — Accepted component-helper cleanup claims were not applied
**Severity**: warning
**File**: evals/component-test-helper.ts:20
**What**: Sharpened claims C1-C3 are still unapplied. `Config` is still imported as a value, `ComponentRig.initialize()` still returns nothing, `componentEvalTest` still uses `rig.config!`, and the JSDoc still says "behavioral evaluations" instead of component-level evaluations.

Current evidence:

```ts
  Config,
```

```ts
  async initialize() {
```

```ts
 * A helper for running behavioral evaluations directly against backend components.
```

```ts
        await rig.initialize();
```

```ts
          await evalCase.setup(rig.config!);
```

```ts
        await evalCase.assert(rig.config!);
```

**Fix**: Import `Config` as a type, make `initialize()` return the initialized config, use `const config = await rig.initialize()` for setup/assert, and update the JSDoc to say component-level evaluations.

## Finding F5 — Accepted app-helper type-only import claim was not applied
**Severity**: warning
**File**: evals/app-test-helper.ts:15
**What**: Sharpened claim C4 is still unapplied. `BaseEvalCase` is only used as an interface base but remains a value import from `./test-helper.js`.

Current evidence:

```ts
  BaseEvalCase,
```

```ts
export interface AppEvalCase extends BaseEvalCase {
```

**Fix**: Change the import to `type BaseEvalCase` so the helper does not emit an unnecessary runtime import.

## Command Results

Required commands run:

```bash
cat /Users/junekim/Documents/refactor-equivalence/samples/v2/gemini-cli-24941/inputs/allowed-files.txt
npm run build
npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'
```

Clean rerun after build:

```text
build exit code: 0
test exit code: 0
```

Build tail 50 lines:

```text
> node ../../scripts/build_package.js

Successfully copied files.

> @google/gemini-cli-core@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js

Running chrome devtools MCP bundling...

> @google/gemini-cli-core@0.36.0-nightly.20260317.2f90b4653 bundle:browser-mcp
> node scripts/bundle-browser-mcp.mjs

Successfully copied files.
Copied documentation to dist/docs

> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:client && tsc -p tsconfig.build.json


> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build:client
> node esbuild.client.js


> @google/gemini-cli-sdk@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js

Successfully copied files.

> @google/gemini-cli-test-utils@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js

Successfully copied files.

> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:dev


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build:dev
> npm run check-types && npm run lint && node esbuild.js


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 check-types
> tsc --noEmit


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 lint
> eslint src

[watch] build started
[watch] build finished
```

Test tail 50 lines:

```text
Experiments loaded {
  experimentIds: [],
  flags: []
}

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24941/packages/sdk/.geminiignore, continue without it.

(node:77344) MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 model-changed listeners added to [CoreEventEmitter]. MaxListeners is 10. Use emitter.setMaxListeners() to increase limit
(Use `node --trace-warnings ...` to show where the warning was created)
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24941/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24941/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
[DEBUG] [MemoryDiscovery] Loading environment memory for trusted root: /private/tmp/refactor-eq-workdir/cleanroom-v2/24941/packages/sdk (Stopping at trusted root: /private/tmp/refactor-eq-workdir/cleanroom-v2/24941/packages/sdk — no git root found)
[DEBUG] [MemoryDiscovery] Starting upward search from /private/tmp/refactor-eq-workdir/cleanroom-v2/24941/packages/sdk stopping at /private/tmp/refactor-eq-workdir/cleanroom-v2/24941/packages/sdk

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
[DEBUG] [MemoryDiscovery] deduplication: keeping /private/tmp/refactor-eq-workdir/cleanroom-v2/24941/packages/sdk/GEMINI.md (dev: 16777233, ino: 46449924)

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
[DEBUG] [MemoryDiscovery] Successfully read and processed imports: /private/tmp/refactor-eq-workdir/cleanroom-v2/24941/packages/sdk/GEMINI.md (Length: 592)

 ✓ src/agent.integration.test.ts (5 tests) 594ms
   ✓ GeminiCliAgent Integration > resumes a session  532ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  01:01:17
   Duration  2.09s (transform 608ms, setup 0ms, collect 5.29s, tests 822ms, environment 0ms, prepare 172ms)


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/cleanroom-v2/24941/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 12ms
 ✓ src/extension.test.ts (11 tests) 20ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 49ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  01:01:19
   Duration  1.50s (transform 640ms, setup 0ms, collect 2.63s, tests 80ms, environment 0ms, prepare 132ms)
```
