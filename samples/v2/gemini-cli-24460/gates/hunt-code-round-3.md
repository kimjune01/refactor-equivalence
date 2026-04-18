## Build/test failure — round 3
```
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/bb-merged-24460/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/bb-merged-24460/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 696ms
   ✓ GeminiCliAgent Integration > resumes a session  633ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  23:38:30
   Duration  2.32s (transform 689ms, setup 0ms, collect 5.72s, tests 930ms, environment 0ms, prepare 235ms)


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/bb-merged-24460/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 12ms
 ✓ src/extension.test.ts (11 tests) 20ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 52ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  23:38:32
   Duration  1.63s (transform 661ms, setup 0ms, collect 2.84s, tests 84ms, environment 0ms, prepare 139ms)

```
