## Build/test failure — round 7
```
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/bb-merged-24476/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/bb-merged-24476/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 687ms
   ✓ GeminiCliAgent Integration > resumes a session  626ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  00:48:44
   Duration  2.38s (transform 724ms, setup 0ms, collect 5.96s, tests 919ms, environment 0ms, prepare 204ms)


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/bb-merged-24476/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 13ms
 ✓ src/extension.test.ts (11 tests) 18ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 54ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  00:48:46
   Duration  1.72s (transform 748ms, setup 0ms, collect 3.00s, tests 85ms, environment 0ms, prepare 133ms)

```
