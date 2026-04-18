## Build/test failure — round 4
```
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/bb-merged-24476/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/bb-merged-24476/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 591ms
   ✓ GeminiCliAgent Integration > resumes a session  529ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  00:38:53
   Duration  2.36s (transform 789ms, setup 0ms, collect 6.23s, tests 822ms, environment 0ms, prepare 288ms)


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/bb-merged-24476/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 12ms
 ✓ src/extension.test.ts (11 tests) 21ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 52ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  00:38:56
   Duration  1.69s (transform 722ms, setup 0ms, collect 2.95s, tests 86ms, environment 0ms, prepare 141ms)

```
