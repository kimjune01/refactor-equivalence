## Build/test failure — round 10
```
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/bb-merged-24460/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/bb-merged-24460/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 583ms
   ✓ GeminiCliAgent Integration > resumes a session  519ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  00:03:09
   Duration  2.39s (transform 755ms, setup 0ms, collect 6.31s, tests 823ms, environment 0ms, prepare 249ms)


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/bb-merged-24460/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 13ms
 ✓ src/extension.test.ts (11 tests) 21ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 56ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  00:03:11
   Duration  1.87s (transform 774ms, setup 0ms, collect 3.27s, tests 91ms, environment 0ms, prepare 166ms)

```
