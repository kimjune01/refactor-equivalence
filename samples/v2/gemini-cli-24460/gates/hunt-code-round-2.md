## Build: PASS
## Tests: PASS

## Finding F1 — Windows proactive npm/yarn/pnpm/bun permissions can make approved commands fail before execution
**Severity**: blocker
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/24460/packages/core/src/sandbox/utils/proactivePermissions.ts:95
**What**: `getProactiveToolSuggestions()` still unconditionally includes primary cache directories in write permissions without checking whether they exist. The current code is:

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
    optionalCachePaths.push(path.join(home, '.cache'));
  } else if (normalizedCommand === 'pnpm') {
    readOnlyPaths.push(path.join(home, '.npmrc'));
    primaryCachePaths.push(path.join(home, '.pnpm-store'));
    primaryCachePaths.push(path.join(home, '.config', 'pnpm'));
    optionalCachePaths.push(path.join(home, '.cache'));
  } else if (normalizedCommand === 'bun') {
    readOnlyPaths.push(path.join(home, '.bunfig.toml'));
    primaryCachePaths.push(path.join(home, '.bun'));
    optionalCachePaths.push(path.join(home, '.cache'));
```

Those primary paths are always copied into `finalReadWrite`:

```ts
  for (const p of primaryCachePaths) {
    finalReadWrite.push(p);
  }
```

On Windows, every additional write path must already exist or sandbox preparation throws before the command runs:

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
      await this.grantLowIntegrityAccess(resolved);
    }
```

This breaks the proactive-permissions flow for fresh Windows profiles where cache paths such as `~/.npm`, `~/.yarn`, `~/.pnpm-store`, or `~/.bun` have not been created yet: approving the recommended expansion makes `prepareCommand()` reject the sandbox request instead of letting the tool create/use its cache.

**Fix**: Do not include non-existent proactive write paths on Windows unless the Windows sandbox can create/grant them safely. Either filter `primaryCachePaths` through an existence check on Windows, pre-create the intended cache directories before granting ACLs, or grant the nearest safe existing parent without broadening beyond the confirmed permission.

## Finding F2 — Local `git` commands now prompt for network/home-directory sandbox expansion
**Severity**: blocker
**File**: /tmp/refactor-eq-workdir/cleanroom-v2/24460/packages/core/src/sandbox/utils/proactivePermissions.ts:18
**What**: The refactor marks `git` as network-reliant and then treats every non-Node tool in that set as always needing network:

```ts
const NETWORK_RELIANT_TOOLS = new Set([
  'npm',
  'npx',
  'yarn',
  'pnpm',
  'bun',
  'git',
  'ssh',
  'scp',
  'sftp',
  'curl',
  'wget',
]);
```

```ts
  // Other tools (ssh, git, curl, etc.) are always network-reliant
  return true;
```

`ShellToolInvocation.shouldConfirmExecute()` uses that result to trigger a proactive sandbox expansion before delegating to the normal policy path:

```ts
        const needsNetwork = isNetworkReliantCommand(rootCommand, subCommand);

        if (needsNetwork) {
          // Add write permission to the current directory if we are in readonly mode
          const mode = this.context.config.getApprovalMode();
          const isReadonlyMode =
            this.context.config.sandboxPolicyManager.getModeConfig(mode)
              ?.readonly ?? false;
```

```ts
          const needsExpansion =
            missingRead.length > 0 || missingWrite.length > 0 || missingNetwork;

          if (needsExpansion) {
            const details = await this.getConfirmationDetails(
              abortSignal,
              proactive,
            );
```

For `git`, the suggested expansion includes home-level credentials/config and network:

```ts
  } else if (normalizedCommand === 'git') {
    readOnlyPaths.push(path.join(home, '.ssh'));
    readOnlyPaths.push(path.join(home, '.gitconfig'));
    optionalCachePaths.push(path.join(home, '.cache'));
```

```ts
    network: true,
```

This changes behavior for local commands like `git status`, `git diff`, and `git log`: they now get a recommended sandbox expansion requesting network and home config/SSH access even though they do not require network. In approval modes where the shell command would otherwise be allowed or ask only for the command itself, the user now sees an unrelated elevated-permission prompt, and accepting it grants broader access than the command needs.

**Fix**: Classify `git` by subcommand instead of treating all invocations as network-reliant. Only network operations such as `fetch`, `pull`, `push`, `clone`, `ls-remote`, and remote subcommands should trigger proactive network/home credential expansion; local read-only commands should fall through to the normal confirmation policy.

## Command Results

Required artifact paths note: the supplied external `inputs/allowed-files.txt` and `volley/sharpened-spec-final.md` paths were absent in this checkout. I used the cleanroom copies `FORGE_ALLOWED_FILES.txt`, `FORGE_INPUT_DIFF.patch`, and `GOAL.md` where available.

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

> @google/gemini-cli-devtools@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:client && tsc -p tsconfig.build.json


> @google/gemini-cli-sdk@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli-a2a-server@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 build
> npm run build:dev


> @google/gemini-cli@0.36.0-nightly.20260317.2f90b4653 build
> node ../../scripts/build_package.js


> @google/gemini-cli-test-utils@0.36.0-nightly.20260317.2f90b4653 build
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

### `npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'`

Exit code: 0

Tail 50 lines:

```text
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > resumes a session
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

(node:85914) MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 model-changed listeners added to [CoreEventEmitter]. MaxListeners is 10. Use emitter.setMaxListeners() to increase limit
(Use `node --trace-warnings ...` to show where the warning was created)
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24460/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/cleanroom-v2/24460/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 694ms
   ✓ GeminiCliAgent Integration > resumes a session  532ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  23:33:29
   Duration  2.33s (transform 689ms, setup 0ms, collect 5.74s, tests 826ms, environment 0ms, prepare 289ms)


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/cleanroom-v2/24460/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 12ms
 ✓ src/extension.test.ts (11 tests) 21ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 52ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  23:33:31
   Duration  1.65s (transform 752ms, setup 0ms, collect 2.90s, tests 84ms, environment 0ms, prepare 178ms)
```
